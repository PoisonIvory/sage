# MVP Configuration - Simple and focused
import os

# Core audio processing parameters
AUDIO_CONFIG = {
    'target_sample_rate': 48000,  # Consistent 48kHz for all processing
    'min_duration_seconds': 0.5,
    'max_duration_seconds': 60.0,
}

# Consolidated vocal analysis parameters (F0 + voice quality)
VOCAL_ANALYSIS_CONFIG = {
    'min_f0_hz': 75,                    # Hz - minimum F0 (males + pathological cases)
    'max_f0_hz': 400,                   # Hz - maximum F0 for normal phonation (research-grade)
    'time_step': 0.0025,                # s - 2.5ms for research-grade temporal resolution
    'max_jitter_local': 1.04,           # % - research threshold (Farrús et al., 2007)
    'max_shimmer_local': 3.81,          # % - research threshold (Farrús et al., 2007) 
    'excellent_hnr_threshold': 20.0,    # dB - excellent voice quality threshold
}

# Quality gate parameters (RMS-based, not dB-based)
QUALITY_GATE_CONFIG = {
    'min_rms_threshold': 0.001,  # RMS threshold for silence detection
}

# Firebase configuration
FIREBASE_CONFIG = {
    'project_id': os.environ.get('GCP_PROJECT') or os.environ.get('GOOGLE_CLOUD_PROJECT'),
}

def get_config():
    """
    Get MVP configuration for vocal biomarker analysis pipeline.
    
    Returns:
        Dict[str, Any]: Configuration dictionary containing:
            - audio: Audio processing parameters
            - vocal_analysis: Comprehensive vocal biomarker parameters
            - quality_gate: Quality validation thresholds
            - firebase: Firebase project configuration
    """
    return {
        'audio': AUDIO_CONFIG,
        'vocal_analysis': VOCAL_ANALYSIS_CONFIG,
        'quality_gate': QUALITY_GATE_CONFIG,
        'firebase': FIREBASE_CONFIG,
    } 