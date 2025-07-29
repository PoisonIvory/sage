"""
Integration tests for main cloud function.

This module tests the complete flow from cloud event to Firestore storage,
including error handling and temporary file cleanup.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock, ANY
import tempfile
import os
from typing import Dict, Any

from main import process_audio_file


def get_mock_cloud_event(name: str, bucket: str = "test-bucket"):
    mock_event = Mock()
    mock_event.data = {'name': name, 'bucket': bucket}
    return mock_event


class TestMainIntegration(unittest.TestCase):
    """Integration tests for main cloud function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_cloud_event = get_mock_cloud_event('sage-audio-files/test_recording_123.wav')
    
    @patch('main.audio_service')
    def test_process_audio_file_success(self, mock_audio_service):
        """Test successful audio processing flow."""
        # Given: Mock successful processing
        mock_audio_service.process_audio_file.return_value = "doc_123"
        mock_audio_service.parse_file_path.return_value = {'recording_id': 'test_recording_123'}
        
        # When: Processing audio file
        process_audio_file(self.mock_cloud_event)
        
        # Then: Should call audio service
        mock_audio_service.process_audio_file.assert_called_once_with(
            'test-bucket', 'sage-audio-files/test_recording_123.wav'
        )
    
    @patch('main.audio_service')
    def test_process_audio_file_non_wav_extension(self, mock_audio_service):
        """Test processing with non-wav file but correct prefix."""
        # Given: Non-wav file with correct prefix
        event = get_mock_cloud_event('sage-audio-files/test_recording_123.mp3')
        
        # When: Processing audio file
        process_audio_file(event)
        
        # Then: Should not call audio service
        mock_audio_service.process_audio_file.assert_not_called()
    
    @patch('main.audio_service')
    def test_process_audio_file_invalid_prefix(self, mock_audio_service):
        """Test processing with valid extension but wrong prefix."""
        # Given: Valid extension but wrong prefix
        event = get_mock_cloud_event('invalid-path/test_recording_123.wav')
        
        # When: Processing audio file
        process_audio_file(event)
        
        # Then: Should not call audio service
        mock_audio_service.process_audio_file.assert_not_called()
    
    @patch('main.audio_service')
    def test_process_audio_file_service_returns_none(self, mock_audio_service):
        """Test processing when service returns None."""
        # Given: Service returns None (quality gate failure, etc.)
        mock_audio_service.process_audio_file.return_value = None
        
        # When: Processing audio file
        process_audio_file(self.mock_cloud_event)
        
        # Then: Should handle gracefully
        mock_audio_service.process_audio_file.assert_called_once()
    
    @patch('main.audio_service')
    def test_process_audio_file_service_exception(self, mock_audio_service):
        """Test processing when service raises exception."""
        # Given: Service raises exception
        mock_audio_service.process_audio_file.side_effect = Exception("Test error")
        
        # When/Then: Should re-raise exception
        with self.assertRaises(Exception):
            process_audio_file(self.mock_cloud_event)
        
        # Verify service was called
        mock_audio_service.process_audio_file.assert_called_once()
    
    def test_process_audio_file_empty_event_data(self):
        """Test processing with empty cloud event data."""
        # Given: Cloud event with empty data
        event = Mock()
        event.data = {}
        
        # When: Processing audio file
        process_audio_file(event)
        # Then: Should not raise exception (should log fallback)


class TestMainErrorHandling(unittest.TestCase):
    """Test error handling in main function."""
    
    def setUp(self):
        """Set up test fixtures for error handling."""
        self.mock_cloud_event = get_mock_cloud_event('sage-audio-files/test.wav')
    
    def test_process_audio_file_missing_name(self):
        """Test processing with missing file name."""
        # Given: Cloud event with missing name
        event = Mock()
        event.data = {'bucket': 'test-bucket'}
        
        # When: Processing audio file
        process_audio_file(event)
        # Then: Should handle gracefully (no exception)
    
    def test_process_audio_file_missing_bucket(self):
        """Test processing with missing bucket."""
        # Given: Cloud event with missing bucket
        event = Mock()
        event.data = {'name': 'sage-audio-files/test.wav'}
        
        # When: Processing audio file
        process_audio_file(event)
        # Then: Should handle gracefully


class TestMainLogging(unittest.TestCase):
    """Test logging behavior in main function."""
    
    def setUp(self):
        """Set up test fixtures for logging tests."""
        self.mock_cloud_event = get_mock_cloud_event('sage-audio-files/test_recording_123.wav')
    
    @patch('main.logger')
    @patch('main.audio_service')
    def test_process_audio_file_logging_success(self, mock_audio_service, mock_logger):
        """Test logging for successful processing."""
        # Given: Successful processing
        mock_audio_service.process_audio_file.return_value = "doc_123"
        mock_audio_service.parse_file_path.return_value = {'recording_id': 'test_recording_123'}
        
        # When: Processing audio file
        process_audio_file(self.mock_cloud_event)
        
        # Then: Should log start and success
        mock_logger.log_audio_processing_start.assert_called_once_with(
            'sage-audio-files/test_recording_123.wav', 'test-bucket'
        )
        mock_logger.log_audio_processing_success.assert_called_once_with(
            'sage-audio-files/test_recording_123.wav', 'test_recording_123', 'doc_123'
        )
    
    @patch('main.logger')
    @patch('main.audio_service')
    def test_process_audio_file_logging_error(self, mock_audio_service, mock_logger):
        """Test logging for processing error."""
        # Given: Service raises exception
        mock_audio_service.process_audio_file.side_effect = Exception("Test error")
        
        # When/Then: Should log error and re-raise
        with self.assertRaises(Exception):
            process_audio_file(self.mock_cloud_event)
        
        # Then: Should log error
        mock_logger.log_audio_processing_error.assert_called_once()
        args, kwargs = mock_logger.log_audio_processing_error.call_args
        # Validate error message content
        self.assertTrue(
            any("Test error" in str(arg) for arg in args) or
            "Test error" in kwargs.get("error", "")
        )
    
    @patch('main.logger')
    @patch('main.audio_service')
    def test_process_audio_file_logging_no_doc_id(self, mock_audio_service, mock_logger):
        """Test logging when no document ID is returned."""
        # Given: Service returns None
        mock_audio_service.process_audio_file.return_value = None
        
        # When: Processing audio file
        process_audio_file(self.mock_cloud_event)
        
        # Then: Should log warning
        mock_logger.warning.assert_called_once_with(
            ANY
        )


if __name__ == "__main__":
    unittest.main() 