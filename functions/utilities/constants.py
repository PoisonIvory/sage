"""
Constants for Sage voice analysis.

This module centralizes all constants used throughout the voice analysis pipeline
to avoid magic strings and improve maintainability.

Reference: DATA_STANDARDS.md §3.2.1
"""

# File extensions
WAV_EXTENSION = '.wav'

# File path patterns
SAGE_AUDIO_FILES_PREFIX = 'voice_recordings/'

# Firestore schema constants
FIRESTORE_COLLECTION = 'recordings'
INSIGHT_TYPE = 'voice_analysis'
INSIGHT_SUBCOLLECTION = 'insights'
ANALYSIS_VERSION = '1.0'
STATUS_COMPLETED = 'completed'
STATUS_COMPLETED_WITH_WARNINGS = 'completed_with_warnings'

# Audio processing constants
DEFAULT_SAMPLE_RATE = 16000
MIN_DURATION_SECONDS = 0.5
MAX_DURATION_SECONDS = 30.0
MIN_RMS_THRESHOLD = 0.001

# F0 extraction constants
DEFAULT_TIME_STEP = 0.01
DEFAULT_MIN_F0_HZ = 75
DEFAULT_MAX_F0_HZ = 500

# Quality gate thresholds
QUALITY_GATE_MIN_DURATION = 0.5
QUALITY_GATE_MAX_DURATION = 30.0
QUALITY_GATE_MIN_RMS = 0.001

# Processing metadata keys
METADATA_AUDIO_DURATION = 'audio_duration'
METADATA_SAMPLE_RATE = 'sample_rate'
METADATA_TOOL_VERSION = 'tool_version'
METADATA_UNIT = 'unit'
METADATA_TOTAL_FRAMES = 'total_frames'
METADATA_VOICED_FRAMES = 'voiced_frames'

# Error types
ERROR_NO_VOICED_FRAMES = 'no_voiced_frames'
ERROR_PARSELMOUTH_UNAVAILABLE = 'parselmouth_unavailable'
ERROR_EXTRACTION_FAILED = 'extraction_failed'

# Logging constants
LOGGER_AUDIO_PROCESSING = 'audio_processing'
LOGGER_FIRESTORE = 'firestore'
LOGGER_FEATURE_EXTRACTION = 'feature_extraction' 