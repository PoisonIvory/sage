"""
Audio processing service for Sage voice analysis.

This module encapsulates the audio processing logic from the main cloud function,
providing better separation of concerns and testability.

Reference: DATA_STANDARDS.md §3.2.1
"""

import os
import logging
import tempfile
from typing import Dict, Any, Optional
import numpy as np
import soundfile as sf

from config import get_config
from utilities.firebase_utils import FirebaseManager, FirestoreOperations, StorageOperations
from utilities.tool_versions import ToolVersions
from utilities.unified_logger import get_voice_logger, log_context
from utilities.constants import (
    SAGE_AUDIO_FILES_PREFIX,
    WAV_EXTENSION,
    METADATA_AUDIO_DURATION,
    METADATA_SAMPLE_RATE,
    METADATA_TOOL_VERSION,
    METADATA_UNIT,
    METADATA_TOTAL_FRAMES,
    METADATA_VOICED_FRAMES
)
from feature_extraction_pipeline import FeatureExtractionPipeline
from utilities.audio_utils import convert_to_mono, resample_audio, calculate_duration, calculate_rms

logger = get_voice_logger("audio_processing_service")


class AudioProcessingService:
    """Handles audio processing pipeline for voice analysis."""
    
    def __init__(self, config: Optional[Dict[str, Any]] = None, analysis_version: str = "1.0"):
        """
        Initialize audio processing service.
        
        Args:
            config: Configuration dictionary (optional, uses default if not provided)
            analysis_version: Version string for analysis results (default: "1.0")
        """
        self.config = config or get_config()
        self.analysis_version = analysis_version
        
        # Defensive config validation
        if not self.config.get("audio") or not self.config.get("firebase"):
            raise ValueError("Invalid or missing configuration")
        
        self.firebase_manager = FirebaseManager(
            project_id=self.config['firebase']['project_id'],
            cred_path=os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        )
        self.firebase_manager.initialize()
        
        self.firestore_ops = FirestoreOperations(self.firebase_manager)
        self.storage_ops = StorageOperations(self.firebase_manager)
        self.pipeline = FeatureExtractionPipeline(self.config)
        
        # Use unified logger instead of standard logger
        self.logger = get_voice_logger("audio_processing_pipeline")

    def _is_valid_audio_file(self, file_name: str) -> bool:
        """Check if file_name is a valid Sage audio file."""
        return file_name.endswith(WAV_EXTENSION) and file_name.startswith(SAGE_AUDIO_FILES_PREFIX)

    def _build_processing_metadata(self, duration: float, sample_rate: int, voiced_ratio: float = None) -> Dict[str, Any]:
        """Build processing metadata dictionary."""
        # Calculate frames based on Praat's default time step (0.01s = 100 Hz)
        total_frames = int(duration / 0.01)  # Total frames at 10ms intervals
        voiced_frames = int(total_frames * voiced_ratio) if voiced_ratio else total_frames
        
        return {
            METADATA_AUDIO_DURATION: round(duration, 2),
            METADATA_SAMPLE_RATE: sample_rate,
            METADATA_TOOL_VERSION: 'praat-6.4.1',
            METADATA_UNIT: 'Hz',
            METADATA_TOTAL_FRAMES: total_frames,
            METADATA_VOICED_FRAMES: voiced_frames
        }

    def parse_file_path(self, file_name: str) -> Dict[str, str]:
        """
        Parse file path to extract recording ID from storage path.
        
        Args:
            file_name: Storage file path
            
        Returns:
            Dictionary containing recording_id
            
        Raises:
            ValueError: If file path structure is invalid
        """
        try:
            if not file_name.startswith(SAGE_AUDIO_FILES_PREFIX):
                raise ValueError(f"Invalid file path structure: {file_name}")
            filename = file_name.split('/')[-1]
            recording_id = filename.replace(WAV_EXTENSION, '')
            return {'recording_id': recording_id}
        except Exception as e:
            self.logger.exception("File path parsing failed")
            raise

    def validate_audio_quality(self, audio: np.ndarray, sample_rate: int) -> bool:
        """
        Validate audio quality for processing.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            True if audio quality is sufficient for processing
        """
        try:
            duration = calculate_duration(audio, sample_rate)
            min_duration = self.config['audio']['min_duration_seconds']
            max_duration = self.config['audio']['max_duration_seconds']
            if duration < min_duration:
                self.logger.warning(f"Audio too short: {duration:.2f}s < {min_duration}s")
                return False
            if duration > max_duration:
                self.logger.warning(f"Audio too long: {duration:.2f}s > {max_duration}s")
                return False
            rms = calculate_rms(audio)
            min_rms = self.config['quality_gate']['min_rms_threshold']
            if rms < min_rms:
                self.logger.warning(f"Audio too quiet: RMS {rms:.6f} < {min_rms}")
                return False
            self.logger.info(f"Quality gate passed: duration={duration:.2f}s, RMS={rms:.6f}")
            return True
        except Exception as e:
            self.logger.exception("Quality gate failed")
            return False

    def _load_and_process_audio(self, temp_file_path: str, file_name: str, bucket_name: str) -> Optional[str]:
        """
        Shared logic for loading, validating, extracting, and storing audio features.
        """
        try:
            audio, sample_rate = sf.read(temp_file_path)
            audio = convert_to_mono(audio, sample_rate)
            audio = resample_audio(
                audio,
                sample_rate,
                self.config['audio']['target_sample_rate']
            )
            sample_rate = self.config['audio']['target_sample_rate']
            duration = calculate_duration(audio, sample_rate)
            if not self.validate_audio_quality(audio, sample_rate):
                self.logger.error("Audio failed quality gate")
                return None
            features = self.pipeline.run_for_firestore(audio, sample_rate)
            # Extract voiced_ratio from features for accurate metadata
            voiced_ratio = features.get('vocal_analysis_metadata_voiced_ratio', 0.0)
            processing_metadata = self._build_processing_metadata(duration, sample_rate, voiced_ratio)
            tool_versions = ToolVersions.get_analysis_versions()
            file_info = self.parse_file_path(file_name)
            recording_id = file_info['recording_id']
            doc_id = self.firestore_ops.store_voice_analysis_results(
                recording_id, features, processing_metadata, tool_versions, self.analysis_version
            )
            self.logger.info(f"Processing completed successfully for {file_name}")
            return doc_id
        except Exception as e:
            self.logger.exception(f"Processing failed for {file_name}")
            raise

    def process_audio_file(self, bucket_name: str, file_name: str) -> Optional[str]:
        """
        Process audio file through the complete voice analysis pipeline using context manager.
        """
        # Extract context for logging
        recording_id = None
        user_id = None
        try:
            file_info = self.parse_file_path(file_name)
            recording_id = file_info.get('recording_id')
            user_id = file_info.get('user_id')
        except Exception:
            pass
        
        if not self._is_valid_audio_file(file_name):
            self.logger.info("Skipping invalid or non-wav file", extra={
                "file_name": file_name,
                "recording_id": recording_id,
                "expected_extension": WAV_EXTENSION,
                "expected_prefix": SAGE_AUDIO_FILES_PREFIX
            })
            return None
            
        self.logger.info("Processing audio file", extra={
            "file_name": file_name,
            "bucket_name": bucket_name,
            "recording_id": recording_id,
            "user_id": user_id
        })
        
        temp_file_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=WAV_EXTENSION) as temp_file:
                bucket = self.firebase_manager.storage_client.bucket(bucket_name)
                blob = bucket.blob(file_name)
                blob.download_to_filename(temp_file.name)
                temp_file_path = temp_file.name
                
            result = self._load_and_process_audio(temp_file_path, file_name, bucket_name)
            
            self.logger.info("Audio processing completed", extra={
                "file_name": file_name,
                "recording_id": recording_id,
                "document_id": result if result else "none"
            })
            
            return result
            
        finally:
            if temp_file_path and os.path.exists(temp_file_path):
                try:
                    os.unlink(temp_file_path)
                    self.logger.debug("Temporary file cleaned up")
                except Exception as e:
                    self.logger.warning("Failed to clean up temporary file", error=e, extra={
                        "temp_file_path": temp_file_path
                    }) 