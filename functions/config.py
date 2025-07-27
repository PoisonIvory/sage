# MVP Configuration - Simple and focused
import os

# Core audio processing parameters
AUDIO_CONFIG = {
    'target_sample_rate': 48000,
    'min_duration_seconds': 0.5,
    'max_duration_seconds': 60.0,
}

# F0 extraction parameters
F0_CONFIG = {
    'min_f0_hz': 75,
    'max_f0_hz': 500,
    'time_step': 0.01,
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
    Get MVP configuration for F0 processing pipeline.
    
    Returns:
        Dict[str, Any]: Configuration dictionary containing:
            - audio: Audio processing parameters
            - f0: F0 extraction parameters  
            - quality_gate: Quality validation thresholds
            - firebase: Firebase project configuration
    """
    return {
        'audio': AUDIO_CONFIG,
        'f0': F0_CONFIG,
        'quality_gate': QUALITY_GATE_CONFIG,
        'firebase': FIREBASE_CONFIG,
    } 