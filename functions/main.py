# MVP Cloud Function - Simple F0 extraction only
import os
import tempfile
import logging
from typing import Dict, Any
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import storage
import parselmouth
import numpy as np
import soundfile as sf
from config import get_config
from utils import convert_to_mono, resample_audio, calculate_duration, calculate_rms, safe_mean, safe_std

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load configuration
config = get_config()

# Initialize Firebase
if not firebase_admin._apps:
    cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    project_id = config['firebase']['project_id']
    
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
    else:
        cred = credentials.ApplicationDefault()
    
    firebase_admin.initialize_app(cred, {'projectId': project_id})

def parse_file_path(file_name: str) -> Dict[str, str]:
    """
    Parse file path to extract user and recording IDs.
    
    Args:
        file_name (str): File path in format 'users/{userId}/recordings/{recordingId}/audio.wav'
        
    Returns:
        Dict[str, str]: Dictionary containing 'user_id' and 'recording_id'
        
    Raises:
        ValueError: If file path structure is invalid
    """
    try:
        parts = file_name.split('/')
        if len(parts) < 4:
            raise ValueError(f"Invalid file path structure: {file_name}")
        
        return {
            'user_id': parts[1],
            'recording_id': parts[3].replace('.wav', '')
        }
    except Exception as e:
        logger.error(f"File path parsing failed: {e}")
        raise

def download_audio(bucket_name: str, file_name: str) -> str:
    """
    Download audio file from Firebase Storage to temporary local file.
    
    Args:
        bucket_name (str): Firebase Storage bucket name
        file_name (str): Path to audio file in bucket
        
    Returns:
        str: Path to temporary local file
        
    Raises:
        Exception: If download fails
    """
    try:
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
        blob.download_to_filename(temp_file.name)
        logger.info(f"Downloaded audio file: {file_name}")
        return temp_file.name
    except Exception as e:
        logger.error(f"Audio download failed: {e}")
        raise

def fast_quality_gate(audio: np.ndarray, sample_rate: int) -> bool:
    """
    Simple quality gate for MVP audio validation.
    
    Args:
        audio (np.ndarray): Audio data as numpy array
        sample_rate (int): Audio sample rate in Hz
        
    Returns:
        bool: True if audio passes quality checks, False otherwise
        
    Raises:
        Exception: If quality gate processing fails
    """
    try:
        # Validate sample rate first
        if sample_rate <= 0:
            logger.error(f"Invalid sample rate: {sample_rate}")
            return False
        
        duration = calculate_duration(audio, sample_rate)
        rms = calculate_rms(audio)
        
        # Basic checks
        if duration < config['audio']['min_duration_seconds']:
            logger.warning(f"Audio too short: {duration:.2f}s")
            return False
        
        if duration > config['audio']['max_duration_seconds']:
            logger.warning(f"Audio too long: {duration:.2f}s")
            return False
        
        # Use configurable RMS threshold
        min_rms = config['quality_gate']['min_rms_threshold']
        if rms < min_rms:
            logger.warning(f"Audio too quiet: RMS {rms:.6f} < {min_rms}")
            return False
        
        logger.info(f"Quality gate passed: duration={duration:.2f}s, RMS={rms:.6f}")
        return True
    except Exception as e:
        logger.error(f"Quality gate failed: {e}")
        return False

def extract_f0_features(audio: np.ndarray, sample_rate: int) -> Dict[str, Any]:
    """
    Extract F0 features using Praat via Parselmouth.
    
    Args:
        audio (np.ndarray): Audio data as numpy array
        sample_rate (int): Audio sample rate in Hz
        
    Returns:
        Dict[str, Any]: Dictionary containing F0 features:
            - mean_f0 (float): Mean fundamental frequency in Hz
            - std_f0 (float): Standard deviation of F0 in Hz
            - confidence (float): Confidence score (0-100)
            - voiced_ratio (float): Ratio of voiced frames to total frames
            
    Raises:
        Exception: If F0 extraction fails
    """
    temp_file = None
    try:
        # Save audio to temporary file for Praat
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
        sf.write(temp_file.name, audio, sample_rate)
        
        # Load with Parselmouth (Praat)
        sound = parselmouth.Sound(temp_file.name)
        
        # Extract pitch
        pitch = sound.to_pitch(
            time_step=config['f0']['time_step'],
            pitch_floor=config['f0']['min_f0_hz'],
            pitch_ceiling=config['f0']['max_f0_hz']
        )
        
        # Get F0 values
        f0_values = pitch.selected_array['frequency']
        f0_values = f0_values[f0_values > 0]  # Remove unvoiced frames
        
        # Calculate features
        mean_f0 = safe_mean(f0_values)
        std_f0 = safe_std(f0_values)
        
        # Simple confidence based on voiced ratio
        voiced_ratio = len(f0_values) / len(pitch.selected_array['frequency'])
        confidence = min(100, voiced_ratio * 100)
        
        # Validate F0 is within physiological bounds
        if not (config['f0']['min_f0_hz'] <= mean_f0 <= config['f0']['max_f0_hz']):
            logger.warning(f"F0 {mean_f0:.1f} Hz outside physiological range [{config['f0']['min_f0_hz']}, {config['f0']['max_f0_hz']}] Hz")
            # Still return the value but flag it
            error_type = "f0_out_of_range"
        else:
            error_type = None
        
        logger.info(f"F0 extraction completed: {mean_f0:.1f} Hz (confidence: {confidence:.1f}%)")
        
        return {
            'mean_f0': mean_f0,
            'std_f0': std_f0,
            'confidence': confidence,
            'voiced_ratio': voiced_ratio,
            'error_type': error_type
        }
        
    except Exception as e:
        logger.error(f"F0 extraction failed: {e}")
        return {
            'mean_f0': 0.0,
            'std_f0': 0.0,
            'confidence': 0.0,
            'voiced_ratio': 0.0,
            'error_type': 'extraction_failed'
        }
    finally:
        # Ensure temp file is cleaned up
        if temp_file and os.path.exists(temp_file.name):
            try:
                os.unlink(temp_file.name)
                logger.debug("Temporary audio file cleaned up")
            except Exception as e:
                logger.warning(f"Failed to clean up temp file: {e}")

def store_results(user_id: str, recording_id: str, features: Dict[str, Any], processing_metadata: Dict[str, Any]) -> None:
    """
    Store processing results in Firestore insights subcollection.
    
    Args:
        user_id (str): User identifier
        recording_id (str): Recording identifier
        features (Dict[str, Any]): Extracted F0 features
        processing_metadata (Dict[str, Any]): Processing metadata and frame counts
        
    Returns:
        None
        
    Raises:
        Exception: If storage operation fails
    """
    try:
        db = firestore.client()
        
        # Store in insights subcollection for better scalability
        insights_ref = db.collection('users').document(user_id).collection('recordings').document(recording_id).collection('insights')
        
        # Validate F0 before storing
        mean_f0 = features['mean_f0']
        error_type = features.get('error_type')
        
        if not (config['f0']['min_f0_hz'] <= mean_f0 <= config['f0']['max_f0_hz']):
            logger.warning(f"Storing F0 {mean_f0:.1f} Hz outside physiological range")
            error_type = error_type or "f0_out_of_range"
        
        # Create insight document with F0 data and metadata
        insight_data = {
            'insight_type': 'f0_analysis',  # Lowercase snake_case convention
            'created_at': firestore.SERVER_TIMESTAMP,
            'status': 'completed' if not error_type else 'completed_with_warnings',
            'analysis_version': '1.0',
            'error_type': error_type,  # For downstream analytics
            
            # F0 features as simple floats (for Firestore compatibility and iOS expectations)
            'f0_mean': round(features['mean_f0'], 1),  # Float, not nested object
            'f0_std': round(features['std_f0'], 1),
            'f0_confidence': round(features['confidence'], 1),  # Percentage
            'voiced_ratio': round(features['voiced_ratio'], 3),
            
            # Processing metadata with units and frame counts
            'processing_metadata': processing_metadata,
            
            # Version info for research reproducibility
            'tool_versions': {
                'praat': '6.4.1',
                'parselmouth': '0.4.3'
            }
        }
        
        # Add to insights subcollection
        insights_ref.add(insight_data)
        
        logger.info(f"F0 insights stored for user {user_id}, recording {recording_id}")
        
    except Exception as e:
        logger.error(f"Failed to store F0 insights: {e}")
        raise

def process_audio_file(event: Dict[str, Any], context: Any) -> None:
    """
    Main Cloud Function entry point for F0 processing pipeline.
    
    Processes uploaded audio files, extracts F0 features using Praat,
    and stores results in Firestore insights subcollection.
    
    Args:
        event (Dict[str, Any]): Cloud Function event containing file upload info
        context (Any): Cloud Function context (unused)
        
    Returns:
        None
        
    Raises:
        Exception: If processing fails at any stage
    """
    temp_file_path = None
    
    # Explicit file path filtering - only process audio.wav files
    file_name = event.get('name', '')
    if not file_name.endswith('/audio.wav'):
        logger.info(f"Skipping non-audio.wav file: {file_name}")
        return
    
    # Validate expected path structure: users/{userId}/recordings/{recordingId}/audio.wav
    if not file_name.startswith('users/') or file_name.count('/') != 3:
        logger.warning(f"Unexpected file path structure: {file_name}")
        return
    
    try:
        # Extract file info
        bucket_name = event['bucket']
        
        logger.info(f"Processing audio file: {file_name} from bucket: {bucket_name}")
        
        # Parse file path
        file_info = parse_file_path(file_name)
        user_id = file_info['user_id']
        recording_id = file_info['recording_id']
        
        # Download audio
        temp_file_path = download_audio(bucket_name, file_name)
        
        # Load audio
        audio, sample_rate = sf.read(temp_file_path)
        
        # Preprocess
        audio = convert_to_mono(audio, sample_rate)
        audio = resample_audio(audio, sample_rate, config['audio']['target_sample_rate'])
        sample_rate = config['audio']['target_sample_rate']
        
        # Quality gate
        if not fast_quality_gate(audio, sample_rate):
            logger.error("Audio failed quality gate")
            return
        
        # Extract F0 features
        features = extract_f0_features(audio, sample_rate)
        
        # Add processing metadata
        duration = calculate_duration(audio, sample_rate)
        # Create processing metadata with rounded values and units
        processing_metadata = {
            'audio_duration': round(duration, 2),  # Round to 2 decimal places for consistency
            'sample_rate': sample_rate,
            'tool_version': 'praat-6.4.1',
            'unit': 'Hz',  # Unit info in metadata, not in feature values
            'total_frames': int(duration * 100),  # Approximate frame count (100 Hz frame rate)
            'voiced_frames': int(features['voiced_ratio'] * duration * 100)  # Approximate voiced frames
        }
        
        # Store results in insights subcollection
        store_results(user_id, recording_id, features, processing_metadata)
        
        logger.info(f"Processing completed successfully for {file_name}")
        
    except Exception as e:
        logger.error(f"Processing failed for {file_name}: {e}")
        raise
    finally:
        # Clean up temp file
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
                logger.debug("Main temp file cleaned up")
            except Exception as e:
                logger.warning(f"Failed to clean up main temp file: {e}") 