# Sage Cloud Functions - MVP Version

Simple F0 extraction from sustained vowel recordings for the Sage voice biomarker app.

## Overview

This Cloud Function processes audio files uploaded to Firebase Storage and extracts fundamental frequency (F0) features using Praat (via Parselmouth). Designed for MVP requirements with minimal complexity and robust error handling.

## MVP Requirements Met

1. **F0 Extraction**: Extracts mean F0 from sustained vowel recordings using Praat
2. **Quality Gate**: Simple duration and silence checks to reject poor quality audio
3. **Confidence Metric**: Basic confidence calculation based on voiced ratio
4. **Error Handling**: Granular error handling with logging and re-raising
5. **Firebase Integration**: Stores results in Firestore with consistent field naming
6. **Validation**: Physiological bounds validation for F0 values
7. **Resource Management**: Proper cleanup of temporary files

## Architecture

```
Audio Upload → Download → Quality Gate → F0 Extraction → Validation → Store Results
```

### Components

- **`main.py`**: Main Cloud Function with F0 extraction pipeline
- **`config.py`**: Simple configuration management
- **`utils.py`**: Essential helper functions
- **`test_main.py`**: Core functionality tests

## Configuration

Simple configuration in `config.py`:

```python
AUDIO_CONFIG = {
    'target_sample_rate': 48000,
    'min_duration_seconds': 0.5,
    'max_duration_seconds': 60.0,
}

F0_CONFIG = {
    'min_f0_hz': 75,
    'max_f0_hz': 500,
    'time_step': 0.01,
}

QUALITY_GATE_CONFIG = {
    'min_rms_threshold': 0.001,  # RMS threshold for silence detection
}
```

### Future-Proofing

The configuration structure is designed for rapid scaling to include additional acoustic features:

- **Jitter & Shimmer**: Add `JITTER_CONFIG` and `SHIMMER_CONFIG` sections
- **Formants**: Add `FORMANT_CONFIG` section with frequency ranges
- **Voice Quality**: Add `VOICE_QUALITY_CONFIG` for HNR and perturbation measures
- **Feature Subsets**: Enable selective feature extraction for performance tuning

This modular approach allows adding new features without major code restructuring.

## Features Extracted

The function extracts the following F0 features from sustained vowel recordings:

| Feature | Type | Unit | Description |
|---------|------|------|-------------|
| `f0_mean` | Object | Hz | Mean fundamental frequency with value and unit |
| `f0_std` | Object | Hz | Standard deviation of F0 with value and unit |
| `f0_confidence` | Number | % | Confidence score (0-100) |
| `voiced_ratio` | Number | - | Ratio of voiced frames to total frames |

### F0 Data Structure

```json
{
  "f0_mean": {
    "value": 220.0,
    "unit": "Hz"
  },
  "f0_std": {
    "value": 5.0,
    "unit": "Hz"
  },
  "f0_confidence": 85.0,
  "voiced_ratio": 0.8
}
```

### Processing Metadata

Each insight includes comprehensive processing metadata:

```json
{
  "processing_metadata": {
    "audio_duration": 5.0,
    "sample_rate": 48000,
    "tool_version": "praat-6.4.1",
    "voiced_frames": 4000,
    "total_frames": 5000
  }
}
```

### Field Naming Convention

| Internal Variable | Firestore Field | Description | Precision |
|------------------|-----------------|-------------|-----------|
| `features['mean_f0']` | `f0_mean` | Mean fundamental frequency | 1 decimal place |
| `features['std_f0']` | `f0_std` | F0 standard deviation | 1 decimal place |
| `features['confidence']` | `f0_confidence` | Confidence percentage | 1 decimal place |
| `features['voiced_ratio']` | `voiced_ratio` | Voiced frame ratio | 3 decimal places |

**Important**: The iOS frontend should expect `f0_mean` and `f0_std` field names in Firestore documents, not `mean_f0` or `std_f0`. All values are rounded for consistent display and storage.

## Quality Gate

Rejects audio that is:
- Too short (< 0.5 seconds)
- Too long (> 60 seconds)
- Too quiet (RMS < 0.001, configurable via `min_rms_threshold`)

## Error Handling

### Granular Error Handling
Each major function block logs and re-raises errors for better observability:

- **File Path Parsing**: Validates structure and logs parsing errors
- **Audio Download**: Handles storage client errors and download failures
- **Quality Gate**: Logs rejection reasons and handles calculation errors
- **F0 Extraction**: Handles Praat processing errors with fallback values
- **Results Storage**: Validates data before storing and handles Firestore errors

### Error Categories
- **Critical**: Processing failures that prevent feature extraction
- **Warning**: Issues that may affect quality but don't stop processing
- **Info**: Informational messages for monitoring

## Validation

### Physiological Bounds Validation
- **F0 Range**: Validates that extracted F0 is within 75-500 Hz range
- **Inline Validation**: Checks F0 values before storing in Firestore
- **Warning Logging**: Logs warnings for out-of-bounds values but continues processing

### Field Naming Consistency
- **iOS Compatibility**: Uses `f0_mean` and `f0_std` field names consistent with iOS expectations
- **Documentation**: Clear field mapping between internal and stored values
- **Cross-Reference**: All documentation uses the actual Firestore field names

## Resource Management

### Temporary File Cleanup
- **Automatic Cleanup**: All temporary files are cleaned up using `try/finally` blocks
- **Error Resilience**: Cleanup occurs even if exceptions are raised
- **Logging**: Debug logging for successful cleanup and warnings for failures

### Memory Management
- **Streaming**: Audio processing uses streaming to minimize memory usage
- **Garbage Collection**: Temporary objects are properly disposed

### Type Robustness
- **Zero Division Protection**: `calculate_duration()` validates sample rate to prevent division by zero
- **Stereo Shape Handling**: `convert_to_mono()` handles both (channels, time) and (time, channels) formats
- **Input Validation**: All utility functions validate inputs before processing
- **Error Recovery**: Graceful handling of invalid audio parameters

## Testing

Run tests with:

```bash
python3 test_main.py
```

### Test Coverage

Tests cover:
- **File path parsing** with error handling and validation
- **Quality gate functionality** and error cases using synthetic test audio
- **F0 feature extraction** and validation with Praat processing
- **Field naming consistency** verification between internal variables and Firestore fields
- **Temporary file cleanup** verification using code structure inspection
- **Utility functions** with edge cases, error conditions, and type robustness
- **Configuration loading** and parameter validation
- **Error handling improvements** with mocked logging verification
- **Type robustness** including zero division protection and stereo shape handling

### Test Environment

- **Synthetic Audio**: Tests use generated sine wave audio at 220 Hz (A4 note) for consistent, predictable results
- **Mocked Dependencies**: Firebase clients and external services are mocked to avoid network dependencies
- **Unit Testing**: Each function is tested in isolation with controlled inputs
- **Integration Testing**: End-to-end pipeline testing with mocked external dependencies

## Deployment

Deploy to Google Cloud Functions:

```bash
firebase deploy --only functions
```

## Dependencies

- `parselmouth`: Praat integration for F0 extraction
- `numpy`: Numerical operations
- `soundfile`: Audio file I/O
- `firebase-admin`: Firebase integration
- `google-cloud-storage`: Cloud Storage access

## Environment Variables

- `GCP_PROJECT` or `GOOGLE_CLOUD_PROJECT`: Google Cloud project ID
- `GOOGLE_APPLICATION_CREDENTIALS`: Service account credentials (optional)

## Output

Stores results in Firestore insights subcollection for better scalability:
```
users/{userId}/recordings/{recordingId}/insights/{insightId}
├── insight_type: "f0_analysis"           # Type of analysis performed
├── created_at: timestamp                 # Processing timestamp
├── status: "completed"                   # Processing status
├── f0_mean: float                        # Mean F0 (rounded to 1 decimal)
├── f0_std: float                         # F0 standard deviation (rounded to 1 decimal)
├── f0_confidence: float                  # Confidence percentage (rounded to 1 decimal)
├── voiced_ratio: float                   # Proportion of voiced frames (rounded to 3 decimals)
├── processing_metadata: object           # Audio processing details
│   ├── audio_duration: float             # Duration in seconds
│   ├── sample_rate: int                  # Sample rate in Hz
│   └── tool_version: string              # Praat version used
├── analysis_version: "1.0"               # Analysis pipeline version
└── tool_versions: object                 # Tool version information
    ├── praat: "6.4.1"                    # Praat version
    └── parselmouth: "0.4.3"              # Parselmouth version
```

**Frontend Integration Note**: iOS app should query the insights subcollection for `insight_type: "f0_analysis"` and read `f0_mean` and `f0_std` fields. All F0 values are rounded for consistent display and storage efficiency.

## File Path Filtering

The Cloud Function only processes files that match the exact path pattern:
```
users/{userId}/recordings/{recordingId}/audio.wav
```

**Filtering Logic:**
- ✅ Must end with `/audio.wav`
- ✅ Must start with `users/`
- ✅ Must have exactly 3 path segments (users/userId/recordings/recordingId/audio.wav)
- ❌ Skips all other file types and paths

This ensures only the intended audio files trigger F0 extraction and prevents processing of other file types.

## Error Recovery

The system is designed to handle failures gracefully:

1. **Partial Failures**: Individual component failures don't stop the entire pipeline
2. **Fallback Values**: F0 extraction returns default values if processing fails
3. **Logging**: Comprehensive logging for debugging and monitoring
4. **Cleanup**: Resources are properly cleaned up even during failures

## Monitoring

Key metrics to monitor:
- Processing success rate
- F0 extraction confidence distribution
- Quality gate rejection rate
- Processing latency
- Error rates by component

## Future Enhancements

The modular configuration design enables easy addition of new acoustic features:

### Planned Features
- **Jitter Analysis**: Add `JITTER_CONFIG` for cycle-to-cycle F0 variation
- **Shimmer Analysis**: Add `SHIMMER_CONFIG` for cycle-to-cycle amplitude variation
- **Formant Analysis**: Add `FORMANT_CONFIG` for vocal tract resonance frequencies
- **Voice Quality Metrics**: Add `VOICE_QUALITY_CONFIG` for HNR and perturbation measures

### Configuration Extensibility
```python
# Future configuration example
JITTER_CONFIG = {
    'min_jitter_percent': 0.1,
    'max_jitter_percent': 5.0,
    'analysis_method': 'local'
}

SHIMMER_CONFIG = {
    'min_shimmer_db': 0.1,
    'max_shimmer_db': 3.0,
    'analysis_method': 'local'
}
```

This design allows rapid feature addition without major architectural changes. 