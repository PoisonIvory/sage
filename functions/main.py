import os
import uuid
import tempfile
import datetime
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import storage
import opensmile
import parselmouth
import librosa
import numpy as np
import soundfile as sf

# Initialize Firebase Admin
if not firebase_admin._apps:
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {
        'projectId': os.environ.get('GCP_PROJECT') or os.environ.get('GOOGLE_CLOUD_PROJECT'),
    })
db = firestore.client()
storage_client = storage.Client()

# --- Feature Extraction Logic ---
def analyze_recording(audio_buffer, sample_rate=48000):
    """
    Extracts acoustic features from an audio buffer using openSMILE (eGeMAPS), Praat (parselmouth), and librosa.
    Follows DATA_STANDARDS.md §3.1–3.2 and RESOURCES.md for scientific rigor.
    Returns: (features_dict, processing_log)
    """
    processing_log = {
        'steps': [],
        'errors': [],
        'tool_versions': {
            'opensmile': opensmile.__version__,
            'parselmouth': parselmouth.__version__,
            'librosa': librosa.__version__,
        },
        'timestamps': {'start': datetime.datetime.utcnow().isoformat()}
    }
    features = {}
    try:
        # openSMILE: eGeMAPS (88 features)
        smile = opensmile.Smile(
            feature_set=opensmile.FeatureSet.eGeMAPSv02,
            feature_level=opensmile.FeatureLevel.Functionals,
            sample_rate=sample_rate
        )
        egemaps_features = smile.process_signal(audio_buffer, sample_rate).iloc[0].to_dict()
        features['eGeMAPS'] = egemaps_features  # See DATA_STANDARDS.md §3.2, eGeMAPS v02
        processing_log['steps'].append('Extracted eGeMAPS features with openSMILE')
    except Exception as e:
        processing_log['errors'].append(f'openSMILE error: {str(e)}')

    try:
        # Praat: F0, jitter, shimmer, HNR, formants (see DATA_STANDARDS.md §3.2.1–3.2.5)
        snd = parselmouth.Sound(audio_buffer, sampling_frequency=sample_rate)
        pitch = snd.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
        f0_values = pitch.selected_array['frequency']
        f0_nonzero = f0_values[np.nonzero(f0_values)]
        praat_features = {
            'mean_f0': float(np.mean(f0_nonzero)) if f0_nonzero.size > 0 else 0,
            'min_f0': float(np.min(f0_nonzero)) if f0_nonzero.size > 0 else 0,
            'max_f0': float(np.max(f0_nonzero)) if f0_nonzero.size > 0 else 0,
            'sd_f0': float(np.std(f0_nonzero)) if f0_nonzero.size > 0 else 0,
        }
        # Jitter, shimmer, HNR
        point_process = parselmouth.praat.call(snd, "To PointProcess (periodic, cc)", 75, 500)
        praat_features['jitter_local'] = float(parselmouth.praat.call([snd, point_process], "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3))  # %
        praat_features['jitter_rap'] = float(parselmouth.praat.call([snd, point_process], "Get jitter (rap)", 0, 0, 0.0001, 0.02, 1.3))  # %
        praat_features['shimmer_local'] = float(parselmouth.praat.call([snd, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6))  # dB
        praat_features['hnr'] = float(parselmouth.praat.call(snd, "To Harmonicity (cc)", 0.01, 75, 0.1, 1.0))  # dB
        # Formants (LPC)
        formant = snd.to_formant_burg(time_step=0.01, max_number_of_formants=5, maximum_formant=5500.0)
        praat_features['formant1_mean'] = float(np.mean([formant.get_value_at_time(1, t) for t in np.arange(0, snd.duration, 0.01) if formant.get_value_at_time(1, t) > 0]))
        praat_features['formant2_mean'] = float(np.mean([formant.get_value_at_time(2, t) for t in np.arange(0, snd.duration, 0.01) if formant.get_value_at_time(2, t) > 0]))
        praat_features['formant3_mean'] = float(np.mean([formant.get_value_at_time(3, t) for t in np.arange(0, snd.duration, 0.01) if formant.get_value_at_time(3, t) > 0]))
        features['praat'] = praat_features
        processing_log['steps'].append('Extracted pitch, jitter, shimmer, HNR, and formants with Praat')
    except Exception as e:
        processing_log['errors'].append(f'Praat error: {str(e)}')

    try:
        # Librosa: duration, MFCCs, intensity, speaking rate, voice breaks (see DATA_STANDARDS.md §3.2.6–3.2.10)
        y = audio_buffer if audio_buffer.ndim == 1 else audio_buffer[:, 0]  # mono
        duration = librosa.get_duration(y=y, sr=sample_rate)
        mfccs = librosa.feature.mfcc(y=y, sr=sample_rate, n_mfcc=13)
        rms = librosa.feature.rms(y=y)
        # Speaking rate and voice breaks (simple VAD-based estimate)
        intervals = librosa.effects.split(y, top_db=30)
        voiced_durations = sum([(e - s) / sample_rate for s, e in intervals])
        speaking_rate = len(intervals) / duration if duration > 0 else 0
        voice_breaks = (duration - voiced_durations) / duration if duration > 0 else 0
        features['librosa'] = {
            'duration': float(duration),
            'mfccs_mean': [float(np.mean(mfcc)) for mfcc in mfccs],
            'intensity_rms_mean': float(np.mean(rms)),
            'speaking_rate': float(speaking_rate),
            'voice_breaks_ratio': float(voice_breaks),
        }
        processing_log['steps'].append('Extracted duration, MFCCs, intensity, speaking rate, and voice breaks with Librosa')
    except Exception as e:
        processing_log['errors'].append(f'Librosa error: {str(e)}')
    processing_log['timestamps']['end'] = datetime.datetime.utcnow().isoformat()
    return features, processing_log

# --- Cloud Function Entry Point ---
def process_audio_file(event, context):
    """
    Cloud Function triggered by audio file upload to Firebase Storage.
    Downloads audio, extracts features, and writes results to Firestore.
    """
    bucket_name = event['bucket']
    file_name = event['name']
    # Parse userId and recordingId from file path (assume format: users/{userId}/recordings/{recordingId}/audio.wav)
    try:
        parts = file_name.split('/')
        user_id = parts[1]
        recording_id = parts[3]
    except Exception as e:
        print(f'Error parsing file path: {file_name}, {e}')
        return
    # Download audio file
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_name)
    with tempfile.NamedTemporaryFile(suffix='.wav') as temp_audio:
        blob.download_to_filename(temp_audio.name)
        audio_buffer, sr = sf.read(temp_audio.name)
        if sr != 48000:
            # Resample to 48kHz if needed
            audio_buffer = librosa.resample(audio_buffer, orig_sr=sr, target_sr=48000)
            sr = 48000
    # Extract features
    features, processing_log = analyze_recording(audio_buffer, sample_rate=sr)
    # Prepare Firestore document
    insight_id = str(uuid.uuid4())
    doc_ref = db.collection('users').document(user_id).collection('recordings').document(recording_id).collection('insights').document(insight_id)
    doc_data = {
        'features': features,
        'processing_log': processing_log,
        'created_at': firestore.SERVER_TIMESTAMP,
        'audio_metadata': {
            'sample_rate': sr,
            'duration': float(librosa.get_duration(y=audio_buffer, sr=sr)),
        }
    }
    doc_ref.set(doc_data)
    print(f'Processed and stored insights for user {user_id}, recording {recording_id}, insight {insight_id}') 