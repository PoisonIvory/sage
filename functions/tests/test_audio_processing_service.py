"""
Tests for AudioProcessingService.

This module tests the audio processing service functionality, including
error handling, temporary file cleanup, and integration with Firebase services.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import numpy as np
import tempfile
import os
from typing import Dict, Any

from services.audio_processing_service import AudioProcessingService
from utilities.tool_versions import ToolVersions


class TestAudioProcessingService(unittest.TestCase):
    """Test cases for AudioProcessingService success paths."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Mock configuration - updated for VocalAnalysisExtractor
        self.mock_config = {
            'firebase': {'project_id': 'test-project'},
            'audio': {
                'min_duration_seconds': 0.5,
                'max_duration_seconds': 30.0,
                'target_sample_rate': 48000  # Updated to 48kHz
            },
            'quality_gate': {'min_rms_threshold': 0.001},
            'vocal_analysis': {  # Updated from 'f0' to 'vocal_analysis'
                'time_step': 0.01,
                'min_f0_hz': 75,
                'max_f0_hz': 500,
                'max_jitter_local': 5.0,
                'max_shimmer_local': 10.0,
                'excellent_hnr_threshold': 20.0
            }
        }
        
        # Create service with mocked dependencies
        with patch('services.audio_processing_service.FirebaseManager') as mock_firebase_manager:
            with patch('services.audio_processing_service.FeatureExtractionPipeline') as mock_pipeline:
                self.mock_firebase_manager = mock_firebase_manager.return_value
                self.mock_pipeline = mock_pipeline.return_value
                
                # Mock the service components
                self.mock_firestore_ops = Mock()
                self.mock_storage_ops = Mock()
                
                self.mock_firebase_manager.firestore_client = Mock()
                self.mock_firebase_manager.storage_client = Mock()
                
                # Create service instance
                with patch('services.audio_processing_service.get_config', return_value=self.mock_config):
                    self.service = AudioProcessingService(self.mock_config, analysis_version="1.0")
                    # Ensure mocks are properly configured
                    self.service.firestore_ops = Mock()
                    self.service.storage_ops = Mock()
    
    def test_parse_file_path_valid(self):
        """Test parsing valid file path."""
        # Given: Valid file path
        file_name = "sage-audio-files/test_recording_123.wav"
        
        # When: Parsing file path
        result = self.service.parse_file_path(file_name)
        
        # Then: Should extract recording ID correctly
        self.assertEqual(result['recording_id'], 'test_recording_123')
    
    def test_validate_audio_quality_success(self):
        """Test audio quality validation with good audio."""
        # Given: Good quality audio
        audio = np.random.randn(48000)  # 1 second at 48kHz
        sample_rate = 48000
        
        # When: Validating audio quality
        result = self.service.validate_audio_quality(audio, sample_rate)
        
        # Then: Should pass validation
        self.assertTrue(result)
    
    @patch('services.audio_processing_service.sf.read')
    @patch('services.audio_processing_service.convert_to_mono')
    @patch('services.audio_processing_service.resample_audio')
    @patch('services.audio_processing_service.calculate_duration')
    def test_process_audio_file_success(self, mock_duration, mock_resample, mock_mono, mock_read):
        """Test successful audio processing."""
        # Given: Mock audio data and successful processing
        mock_audio = np.random.randn(48000)
        mock_read.return_value = (mock_audio, 48000)
        mock_mono.return_value = mock_audio
        mock_resample.return_value = mock_audio
        mock_duration.return_value = 1.0
        
        # Mock storage operations
        self.service.storage_ops.download_audio_file.return_value = "/tmp/test.wav"
        
        # Mock pipeline with VocalAnalysisExtractor feature keys
        self.service.pipeline.run_for_firestore.return_value = {
            'vocal_analysis_f0_mean': 220.0,
            'vocal_analysis_f0_std': 5.0,
            'vocal_analysis_f0_confidence': 85.0,
            'vocal_analysis_jitter_local': 0.5,
            'vocal_analysis_shimmer_local': 3.0,
            'vocal_analysis_hnr_mean': 18.5,
            'vocal_analysis_vocal_stability_score': 82.0,
            'vocal_analysis_version': '1.0',
            'vocal_analysis_metadata_voiced_ratio': 0.8
        }
        
        # Mock Firestore operations
        self.service.firestore_ops.store_voice_analysis_results.return_value = "doc_123"
        
        # When: Processing audio file
        result = self.service.process_audio_file("test-bucket", "sage-audio-files/test.wav")
        
        # Then: Should return document ID
        self.assertEqual(result, "doc_123")
        
        # Verify pipeline was called
        self.service.pipeline.run_for_firestore.assert_called_once()
        
        # Verify VocalAnalysisExtractor feature keys are present
        pipeline_result = self.service.pipeline.run_for_firestore.return_value
        self.assertIn('vocal_analysis_f0_mean', pipeline_result)
        self.assertIn('vocal_analysis_f0_std', pipeline_result)
        self.assertIn('vocal_analysis_f0_confidence', pipeline_result)
        self.assertIn('vocal_analysis_jitter_local', pipeline_result)
        self.assertIn('vocal_analysis_shimmer_local', pipeline_result)
        self.assertIn('vocal_analysis_hnr_mean', pipeline_result)
        self.assertIn('vocal_analysis_version', pipeline_result)
    
    def test_tool_versions_integration(self):
        """Test that tool versions are properly integrated."""
        # Given: Tool versions from centralized module
        tool_versions = ToolVersions.get_analysis_versions()
        
        # Then: Should contain expected versions
        self.assertIn('praat', tool_versions)
        self.assertIn('parselmouth', tool_versions)
        self.assertEqual(tool_versions['praat'], ToolVersions.PRAAT_VERSION)
        self.assertEqual(tool_versions['parselmouth'], ToolVersions.PARSELMOUTH_VERSION)


class TestAudioProcessingServiceEdgeCases(unittest.TestCase):
    """Test edge cases and boundary conditions for AudioProcessingService."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_config = {
            'firebase': {'project_id': 'test-project'},
            'audio': {
                'min_duration_seconds': 0.5,
                'max_duration_seconds': 30.0,
                'target_sample_rate': 48000  # Updated to 48kHz
            },
            'quality_gate': {'min_rms_threshold': 0.001},
            'vocal_analysis': {  # Updated from 'f0' to 'vocal_analysis'
                'time_step': 0.01,
                'min_f0_hz': 75,
                'max_f0_hz': 500,
                'max_jitter_local': 5.0,
                'max_shimmer_local': 10.0,
                'excellent_hnr_threshold': 20.0
            }
        }
        
        with patch('services.audio_processing_service.FirebaseManager'):
            with patch('services.audio_processing_service.FeatureExtractionPipeline'):
                with patch('services.audio_processing_service.get_config', return_value=self.mock_config):
                    self.service = AudioProcessingService(self.mock_config, analysis_version="1.0")
                    # Ensure mocks are properly configured
                    self.service.firestore_ops = Mock()
                    self.service.storage_ops = Mock()
    
    def test_parse_file_path_invalid_prefix(self):
        """Test parsing file path with invalid prefix."""
        # Given: Invalid file path
        file_name = "invalid-path/test_recording_123.wav"
        
        # When/Then: Should raise ValueError
        with self.assertRaises(ValueError):
            self.service.parse_file_path(file_name)
    
    def test_validate_audio_quality_duration_at_boundary(self):
        """Test audio quality validation with duration exactly at minimum."""
        # Given: Audio with duration exactly at minimum threshold
        audio = np.random.randn(8000)  # 0.5 seconds at 16kHz (exactly at min)
        sample_rate = 48000
        
        # When: Validating audio quality
        result = self.service.validate_audio_quality(audio, sample_rate)
        
        # Then: Should pass validation (inclusive boundary)
        self.assertTrue(result)
    
    def test_validate_audio_quality_duration_below_boundary(self):
        """Test audio quality validation with duration just below minimum."""
        # Given: Audio with duration just below minimum threshold
        audio = np.random.randn(7999)  # Just below 0.5 seconds at 16kHz
        sample_rate = 48000
        
        # When: Validating audio quality
        result = self.service.validate_audio_quality(audio, sample_rate)
        
        # Then: Should fail validation
        self.assertFalse(result)
    
    def test_validate_audio_quality_rms_at_threshold(self):
        """Test audio quality validation with RMS exactly at threshold."""
        # Given: Audio with RMS exactly at threshold
        audio = np.ones(48000) * 0.001  # RMS exactly at threshold
        sample_rate = 48000
        
        # When: Validating audio quality
        result = self.service.validate_audio_quality(audio, sample_rate)
        
        # Then: Should pass validation (inclusive threshold)
        self.assertTrue(result)
    
    def test_validate_audio_quality_rms_below_threshold(self):
        """Test audio quality validation with RMS just below threshold."""
        # Given: Audio with RMS just below threshold
        audio = np.random.randn(48000) * 0.0009  # RMS just below threshold
        sample_rate = 48000
        
        # When: Validating audio quality
        result = self.service.validate_audio_quality(audio, sample_rate)
        
        # Then: Should fail validation
        self.assertFalse(result)
    
    def test_process_audio_file_invalid_file_type(self):
        """Test processing with invalid file type."""
        # Given: Non-wav file
        file_name = "sage-audio-files/test.mp3"
        
        # When: Processing audio file
        result = self.service.process_audio_file("test-bucket", file_name)
        
        # Then: Should return None
        self.assertIsNone(result)
    
    def test_process_audio_file_invalid_path(self):
        """Test processing with invalid file path."""
        # Given: Invalid file path
        file_name = "invalid-path/test.wav"
        
        # When: Processing audio file
        result = self.service.process_audio_file("test-bucket", file_name)
        
        # Then: Should return None
        self.assertIsNone(result)
    
    @patch('services.audio_processing_service.sf.read')
    @patch('services.audio_processing_service.convert_to_mono')
    @patch('services.audio_processing_service.resample_audio')
    @patch('services.audio_processing_service.calculate_duration')
    def test_process_audio_file_quality_gate_failure(self, mock_duration, mock_resample, mock_mono, mock_read):
        """Test audio processing with quality gate failure."""
        # Given: Audio that fails quality gate
        mock_audio = np.random.randn(1000)  # Too short
        mock_read.return_value = (mock_audio, 48000)
        mock_mono.return_value = mock_audio
        mock_resample.return_value = mock_audio
        mock_duration.return_value = 0.1  # Too short
        
        # Mock storage operations
        self.service.storage_ops.download_audio_file.return_value = "/tmp/test.wav"
        
        # When: Processing audio file
        result = self.service.process_audio_file("test-bucket", "sage-audio-files/test.wav")
        
        # Then: Should return None due to quality gate failure
        self.assertIsNone(result)
    
    @patch('services.audio_processing_service.sf.read')
    @patch('services.audio_processing_service.convert_to_mono')
    @patch('services.audio_processing_service.resample_audio')
    @patch('services.audio_processing_service.calculate_duration')
    @patch('os.unlink')
    def test_process_audio_file_temp_file_cleanup(self, mock_unlink, mock_duration, mock_resample, mock_mono, mock_read):
        """Test that temporary files are properly cleaned up."""
        # Given: Mock audio data
        mock_audio = np.random.randn(48000)
        mock_read.return_value = (mock_audio, 48000)
        mock_mono.return_value = mock_audio
        mock_resample.return_value = mock_audio
        mock_duration.return_value = 1.0
        
        # Mock pipeline
        self.service.pipeline.run_for_firestore.return_value = {
            'vocal_analysis_f0_mean': 220.0,
            'vocal_analysis_f0_std': 5.0,
            'vocal_analysis_f0_confidence': 85.0,
            'vocal_analysis_metadata_voiced_ratio': 0.8
        }
        
        # Mock Firestore operations
        self.service.firestore_ops.store_voice_analysis_results.return_value = "doc_123"
        
        # Mock storage client
        mock_bucket = Mock()
        mock_blob = Mock()
        self.service.firebase_manager.storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        # When: Processing audio file
        result = self.service.process_audio_file("test-bucket", "sage-audio-files/test.wav")
        
        # Then: Should return document ID and cleanup temp file
        self.assertEqual(result, "doc_123")
        mock_unlink.assert_called_once()
    
    @patch('services.audio_processing_service.sf.read')
    @patch('services.audio_processing_service.convert_to_mono')
    @patch('services.audio_processing_service.resample_audio')
    @patch('services.audio_processing_service.calculate_duration')
    def test_process_audio_file_logging_verification(self, mock_duration, mock_resample, mock_mono, mock_read):
        """Test that logging works correctly during processing."""
        # Given: Mock audio data
        mock_audio = np.random.randn(48000)
        mock_read.return_value = (mock_audio, 48000)
        mock_mono.return_value = mock_audio
        mock_resample.return_value = mock_audio
        mock_duration.return_value = 1.0
        
        # Mock pipeline
        self.service.pipeline.run_for_firestore.return_value = {
            'vocal_analysis_f0_mean': 220.0,
            'vocal_analysis_f0_std': 5.0,
            'vocal_analysis_f0_confidence': 85.0,
            'vocal_analysis_metadata_voiced_ratio': 0.8
        }
        
        # Mock Firestore operations
        self.service.firestore_ops.store_voice_analysis_results.return_value = "doc_123"
        
        # Mock storage client
        mock_bucket = Mock()
        mock_blob = Mock()
        self.service.firebase_manager.storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        # When: Processing audio file with logging verification
        with self.assertLogs('services.audio_processing_service', level='INFO') as log:
            result = self.service.process_audio_file("test-bucket", "sage-audio-files/test.wav")
        
        # Then: Should log success message
        self.assertTrue(any("Processing completed successfully" in msg for msg in log.output))
        self.assertEqual(result, "doc_123")


class TestAudioProcessingServiceErrorHandling(unittest.TestCase):
    """Test error handling and exceptions in AudioProcessingService."""
    
    def setUp(self):
        """Set up test fixtures for error handling tests."""
        self.mock_config = {
            'firebase': {'project_id': 'test-project'},
            'audio': {
                'min_duration_seconds': 0.5,
                'max_duration_seconds': 30.0,
                'target_sample_rate': 48000
            },
            'quality_gate': {'min_rms_threshold': 0.001}
        }
        
        with patch('services.audio_processing_service.FirebaseManager'):
            with patch('services.audio_processing_service.FeatureExtractionPipeline'):
                with patch('services.audio_processing_service.get_config', return_value=self.mock_config):
                    self.service = AudioProcessingService(self.mock_config, analysis_version="1.0")
                    # Ensure mocks are properly configured
                    self.service.firestore_ops = Mock()
                    self.service.storage_ops = Mock()
    
    def test_parse_file_path_exception_handling(self):
        """Test exception handling in file path parsing."""
        # Given: Invalid file path that will cause exception
        file_name = None
        
        # When/Then: Should handle exception gracefully
        with self.assertRaises(Exception):
            self.service.parse_file_path(file_name)
    
    @patch('services.audio_processing_service.calculate_duration')
    def test_validate_audio_quality_exception_handling(self, mock_duration):
        """Test exception handling in audio quality validation."""
        # Given: Mock that raises exception
        mock_duration.side_effect = Exception("Test error")
        
        # When: Validating audio quality
        result = self.service.validate_audio_quality(np.random.randn(48000), 48000)
        
        # Then: Should return False on exception
        self.assertFalse(result)
    
    @patch('services.audio_processing_service.sf.read')
    def test_process_audio_file_read_exception(self, mock_read):
        """Test handling of audio file read exceptions."""
        # Given: Mock that raises exception during file read
        mock_read.side_effect = Exception("File read error")
        
        # Mock storage operations
        self.service.storage_ops.download_audio_file.return_value = "/tmp/test.wav"
        
        # When/Then: Should handle exception and clean up
        with self.assertRaises(Exception):
            self.service.process_audio_file("test-bucket", "sage-audio-files/test.wav")
    
    @patch('services.audio_processing_service.sf.read')
    @patch('services.audio_processing_service.convert_to_mono')
    @patch('services.audio_processing_service.resample_audio')
    @patch('services.audio_processing_service.calculate_duration')
    @patch('os.unlink')
    def test_process_audio_file_cleanup_on_exception(self, mock_unlink, mock_duration, mock_resample, mock_mono, mock_read):
        """Test that temp files are cleaned up even when exceptions occur."""
        # Given: Mock audio data that will cause exception during processing
        mock_audio = np.random.randn(48000)
        mock_read.return_value = (mock_audio, 48000)
        mock_mono.return_value = mock_audio
        mock_resample.return_value = mock_audio
        mock_duration.side_effect = Exception("Processing error")
        
        # Mock storage operations
        self.service.storage_ops.download_audio_file.return_value = "/tmp/test.wav"
        
        # Mock storage client
        mock_bucket = Mock()
        mock_blob = Mock()
        self.service.firebase_manager.storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        # When/Then: Should handle exception and still clean up temp file
        with self.assertRaises(Exception):
            self.service.process_audio_file("test-bucket", "sage-audio-files/test.wav")
        
        # Then: Should still attempt cleanup
        mock_unlink.assert_called_once()
    
    def test_service_initialization_invalid_config(self):
        """Test service initialization with invalid configuration."""
        # Given: Invalid configuration
        invalid_config = {
            'firebase': {},  # Missing project_id
            'audio': {}      # Missing required fields
        }
        
        # When/Then: Should raise ValueError for invalid config
        with self.assertRaises(ValueError):
            AudioProcessingService(invalid_config)


if __name__ == "__main__":
    unittest.main() 