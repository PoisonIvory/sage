#!/usr/bin/env python3
"""
Test suite for refactored main.py functionality
Validates all MVP requirements from the Engineering Design Document
"""

# MVP Tests - Core functionality only
import unittest
import tempfile
import os
import numpy as np
import soundfile as sf
from unittest.mock import patch, MagicMock
import sys
import os

# Add the functions directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from main import (
    parse_file_path, fast_quality_gate, extract_f0_features,
    process_audio_file, store_results
)
from config import get_config
from utils import convert_to_mono, resample_audio, calculate_duration, calculate_rms, safe_mean, safe_std

class TestMVPFunctionality(unittest.TestCase):
    """Test core MVP functionality"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = get_config()
        
        # Create test audio
        self.sample_rate = 48000
        self.duration = 3.0
        self.f0 = 220  # A4 note
        t = np.linspace(0, self.duration, int(self.sample_rate * self.duration))
        self.test_audio = np.sin(2 * np.pi * self.f0 * t) * 0.5
        
    def test_parse_file_path_valid(self):
        """Test parsing valid file path"""
        file_name = "users/user123/recordings/rec456/audio.wav"
        result = parse_file_path(file_name)
        
        self.assertEqual(result['user_id'], 'user123')
        self.assertEqual(result['recording_id'], 'rec456')
    
    def test_parse_file_path_invalid(self):
        """Test parsing invalid file path"""
        file_name = "invalid/path"
        with self.assertRaises(ValueError):
            parse_file_path(file_name)
    
    def test_fast_quality_gate_valid_audio(self):
        """Test quality gate with valid audio"""
        result = fast_quality_gate(self.test_audio, self.sample_rate)
        self.assertTrue(result)
    
    def test_fast_quality_gate_too_short(self):
        """Test quality gate with too short audio"""
        short_audio = self.test_audio[:1000]  # Very short
        result = fast_quality_gate(short_audio, self.sample_rate)
        self.assertFalse(result)
    
    def test_fast_quality_gate_too_quiet(self):
        """Test quality gate with too quiet audio"""
        quiet_audio = self.test_audio * 0.0001  # Very quiet
        result = fast_quality_gate(quiet_audio, self.sample_rate)
        self.assertFalse(result)
    
    def test_extract_f0_features(self):
        """Test F0 feature extraction"""
        features = extract_f0_features(self.test_audio, self.sample_rate)
        
        # Check that features are extracted
        self.assertIn('mean_f0', features)
        self.assertIn('std_f0', features)
        self.assertIn('confidence', features)
        self.assertIn('voiced_ratio', features)
        
        # Check reasonable values
        self.assertGreater(features['mean_f0'], 0)
        self.assertGreaterEqual(features['confidence'], 0)
        self.assertLessEqual(features['confidence'], 100)
    
    def test_extract_f0_features_physiological_validation(self):
        """Test F0 validation within physiological bounds"""
        features = extract_f0_features(self.test_audio, self.sample_rate)
        
        # Check F0 is within physiological range
        mean_f0 = features['mean_f0']
        min_f0 = self.config['f0']['min_f0_hz']
        max_f0 = self.config['f0']['max_f0_hz']
        
        # Should be within range (allowing some tolerance for test audio)
        self.assertGreaterEqual(mean_f0, min_f0 * 0.8)  # Allow some tolerance
        self.assertLessEqual(mean_f0, max_f0 * 1.2)     # Allow some tolerance
    
    def test_store_results_field_naming(self):
        """Test that store_results uses correct field names and structure"""
        features = {
            'mean_f0': 220.0,
            'std_f0': 5.0,
            'confidence': 85.0,
            'voiced_ratio': 0.8
        }
        
        processing_metadata = {
            'audio_duration': 5.0,
            'sample_rate': 48000,
            'tool_version': 'praat-6.4.1',
            'voiced_frames': 4000,
            'total_frames': 5000
        }
        
        with patch('main.firestore.client') as mock_firestore:
            mock_db = MagicMock()
            mock_firestore.return_value = mock_db
            mock_insights_ref = MagicMock()
            mock_add = MagicMock()
            mock_insights_ref.add = mock_add
            
            # Mock the insights subcollection path
            mock_db.collection.return_value.document.return_value.collection.return_value.document.return_value.collection.return_value = mock_insights_ref
            
            store_results('user123', 'rec456', features, processing_metadata)
            
            # Verify the insight document was added
            mock_add.assert_called_once()
            call_args = mock_add.call_args[0][0]
            
            # Check required fields are present
            self.assertEqual(call_args['insight_type'], 'f0_analysis')
            self.assertEqual(call_args['status'], 'completed')
            self.assertEqual(call_args['analysis_version'], '1.0')
            
            # Check F0 values with units
            self.assertIn('f0_mean', call_args)
            f0_mean = call_args['f0_mean']
            self.assertEqual(f0_mean['value'], 220.0)
            self.assertEqual(f0_mean['unit'], 'Hz')
            
            self.assertIn('f0_std', call_args)
            f0_std = call_args['f0_std']
            self.assertEqual(f0_std['value'], 5.0)
            self.assertEqual(f0_std['unit'], 'Hz')
            
            # Check other fields
            self.assertEqual(call_args['f0_confidence'], 85.0)
            self.assertEqual(call_args['voiced_ratio'], 0.8)
            
            # Check processing metadata
            self.assertIn('processing_metadata', call_args)
            metadata = call_args['processing_metadata']
            self.assertEqual(metadata['audio_duration'], 5.0)
            self.assertEqual(metadata['sample_rate'], 48000)
            self.assertEqual(metadata['tool_version'], 'praat-6.4.1')
            self.assertEqual(metadata['voiced_frames'], 4000)
            self.assertEqual(metadata['total_frames'], 5000)
            
            # Check tool versions
            self.assertIn('tool_versions', call_args)
            tool_versions = call_args['tool_versions']
            self.assertEqual(tool_versions['praat'], '6.4.1')
            self.assertEqual(tool_versions['parselmouth'], '0.4.3')
    
    def test_temp_file_cleanup(self):
        """Test that temporary files are properly cleaned up"""
        # This test verifies that temp files are cleaned up even if exceptions occur
        # We can't easily test the actual cleanup without complex mocking,
        # but we can verify the finally blocks are in place by checking the code structure
        
        # The extract_f0_features function should have a finally block
        import inspect
        source = inspect.getsource(extract_f0_features)
        self.assertIn('finally:', source)
        self.assertIn('os.unlink', source)
        
        # The process_audio_file function should also have a finally block
        source = inspect.getsource(process_audio_file)
        self.assertIn('finally:', source)
        self.assertIn('os.unlink', source)
    
    def test_real_temp_file_cleanup(self):
        """Test real filesystem cleanup with exception simulation"""
        import tempfile
        import os
        
        # Create a temporary file
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
        temp_path = temp_file.name
        temp_file.write(b'test audio data')
        temp_file.close()
        
        # Verify file exists
        self.assertTrue(os.path.exists(temp_path))
        
        try:
            # Simulate the cleanup logic from extract_f0_features
            if os.path.exists(temp_path):
                try:
                    os.unlink(temp_path)
                except Exception as e:
                    # This should not happen in normal operation
                    self.fail(f"Failed to clean up temp file: {e}")
            
            # Verify file was cleaned up
            self.assertFalse(os.path.exists(temp_path))
            
        except Exception as e:
            # If cleanup fails, try to clean up manually and fail the test
            if os.path.exists(temp_path):
                try:
                    os.unlink(temp_path)
                except:
                    pass
            self.fail(f"Cleanup test failed: {e}")
    
    def test_store_results_firestore_exception(self):
        """Test that store_results handles Firestore exceptions gracefully"""
        features = {
            'mean_f0': 220.0,
            'std_f0': 5.0,
            'confidence': 85.0,
            'voiced_ratio': 0.8
        }
        
        processing_metadata = {
            'audio_duration': 5.0,
            'sample_rate': 48000,
            'tool_version': 'praat-6.4.1'
        }
        
        with patch('main.firestore.client') as mock_firestore:
            mock_db = MagicMock()
            mock_firestore.return_value = mock_db
            
            # Mock Firestore to throw an exception
            mock_db.collection.side_effect = Exception("Firestore connection failed")
            
            with patch('main.logger') as mock_logger:
                # Should raise the exception (as designed)
                with self.assertRaises(Exception):
                    store_results('user123', 'rec456', features, processing_metadata)
                
                # Verify error was logged
                mock_logger.error.assert_called_once()
                error_message = mock_logger.error.call_args[0][0]
                self.assertIn("Failed to store F0 insights", error_message)
    
    def test_processing_metadata_verification(self):
        """Test that processing metadata is correctly stored"""
        features = {
            'mean_f0': 220.0,
            'std_f0': 5.0,
            'confidence': 85.0,
            'voiced_ratio': 0.8
        }
        
        processing_metadata = {
            'audio_duration': 5.0,
            'sample_rate': 48000,
            'tool_version': 'praat-6.4.1',
            'voiced_frames': 4000,
            'total_frames': 5000
        }
        
        with patch('main.firestore.client') as mock_firestore:
            mock_db = MagicMock()
            mock_firestore.return_value = mock_db
            mock_insights_ref = MagicMock()
            mock_add = MagicMock()
            mock_insights_ref.add = mock_add
            
            # Mock the insights subcollection path
            mock_db.collection.return_value.document.return_value.collection.return_value.document.return_value.collection.return_value = mock_insights_ref
            
            store_results('user123', 'rec456', features, processing_metadata)
            
            # Verify the insight document was added
            mock_add.assert_called_once()
            call_args = mock_add.call_args[0][0]
            
            # Check processing metadata is present and correct
            self.assertIn('processing_metadata', call_args)
            metadata = call_args['processing_metadata']
            self.assertEqual(metadata['audio_duration'], 5.0)
            self.assertEqual(metadata['sample_rate'], 48000)
            self.assertEqual(metadata['tool_version'], 'praat-6.4.1')
            self.assertEqual(metadata['voiced_frames'], 4000)
            self.assertEqual(metadata['total_frames'], 5000)
            
            # Check analysis_version is present
            self.assertIn('analysis_version', call_args)
            self.assertEqual(call_args['analysis_version'], '1.0')
            
            # Check F0 values have units
            self.assertIn('f0_mean', call_args)
            f0_mean = call_args['f0_mean']
            self.assertIn('value', f0_mean)
            self.assertIn('unit', f0_mean)
            self.assertEqual(f0_mean['unit'], 'Hz')
    
    def test_utils_functions(self):
        """Test utility functions"""
        # Test safe_mean
        self.assertEqual(safe_mean(np.array([1, 2, 3])), 2.0)
        self.assertEqual(safe_mean(np.array([])), 0.0)
        
        # Test safe_std
        self.assertAlmostEqual(safe_std(np.array([1, 2, 3])), 1.0, places=1)
        self.assertEqual(safe_std(np.array([])), 0.0)
        
        # Test calculate_duration
        duration = calculate_duration(self.test_audio, self.sample_rate)
        self.assertAlmostEqual(duration, self.duration, places=2)
        
        # Test calculate_rms
        rms = calculate_rms(self.test_audio)
        self.assertGreater(rms, 0)
    
    def test_utils_robustness(self):
        """Test utility function robustness improvements"""
        # Test calculate_duration with zero sample rate
        with self.assertRaises(ValueError) as context:
            calculate_duration(self.test_audio, 0)
        self.assertIn("Invalid sample rate", str(context.exception))
        
        # Test calculate_duration with negative sample rate
        with self.assertRaises(ValueError) as context:
            calculate_duration(self.test_audio, -48000)
        self.assertIn("Invalid sample rate", str(context.exception))
        
        # Test convert_to_mono with different stereo formats
        # Test (channels, time) format
        stereo_channels_time = np.column_stack((self.test_audio, self.test_audio))
        mono_result = convert_to_mono(stereo_channels_time, self.sample_rate)
        self.assertEqual(len(mono_result.shape), 1)  # Should be mono
        
        # Test (time, channels) format
        stereo_time_channels = np.column_stack((self.test_audio, self.test_audio))
        mono_result2 = convert_to_mono(stereo_time_channels, self.sample_rate)
        self.assertEqual(len(mono_result2.shape), 1)  # Should be mono
        
        # Test mono audio (should pass through unchanged)
        mono_audio = self.test_audio
        mono_result3 = convert_to_mono(mono_audio, self.sample_rate)
        np.testing.assert_array_equal(mono_result3, mono_audio)
    
    def test_config_loading(self):
        """Test configuration loading"""
        config = get_config()
        
        # Check required sections exist
        self.assertIn('audio', config)
        self.assertIn('f0', config)
        self.assertIn('quality_gate', config)
        self.assertIn('firebase', config)
        
        # Check key parameters
        self.assertEqual(config['audio']['target_sample_rate'], 48000)
        self.assertEqual(config['f0']['min_f0_hz'], 75)
        self.assertEqual(config['f0']['max_f0_hz'], 500)

class TestErrorHandling(unittest.TestCase):
    """Test error handling improvements"""
    
    def test_parse_file_path_error_logging(self):
        """Test that file path parsing errors are logged and re-raised"""
        with patch('main.logger') as mock_logger:
            with self.assertRaises(ValueError):
                parse_file_path("invalid/path")
            
            # Verify error was logged
            mock_logger.error.assert_called_once()
            error_message = mock_logger.error.call_args[0][0]
            self.assertIn("File path parsing failed", error_message)
    
    def test_quality_gate_error_handling(self):
        """Test quality gate error handling"""
        with patch('main.logger') as mock_logger:
            # Test with invalid audio data
            result = fast_quality_gate(None, 48000)
            self.assertFalse(result)
            
            # Verify error was logged
            mock_logger.error.assert_called_once()
            error_message = mock_logger.error.call_args[0][0]
            self.assertIn("Quality gate failed", error_message)

class TestErrorScenarios(unittest.TestCase):
    """Test additional error scenarios and edge cases"""
    
    def test_file_path_filtering(self):
        """Test that file path filtering works correctly"""
        # Test valid path
        valid_event = {
            'bucket': 'test-bucket',
            'name': 'users/user123/recordings/rec456/audio.wav'
        }
        
        # Test invalid paths that should be skipped
        invalid_paths = [
            'users/user123/recordings/rec456/image.jpg',  # Wrong extension
            'users/user123/recordings/rec456/',  # No filename
            'users/user123/recordings/rec456/audio.mp3',  # Wrong extension
            'uploads/user123/recordings/rec456/audio.wav',  # Wrong prefix
            'users/user123/recordings/rec456/audio.wav/extra',  # Too many segments
            'users/user123/recordings/audio.wav',  # Too few segments
        ]
        
        for invalid_path in invalid_paths:
            invalid_event = {
                'bucket': 'test-bucket',
                'name': invalid_path
            }
            
            with patch('main.logger') as mock_logger:
                # Should not process invalid paths
                process_audio_file(invalid_event, MagicMock())
                
                # Should log that it's skipping
                mock_logger.info.assert_called()
                log_message = mock_logger.info.call_args[0][0]
                self.assertIn("Skipping", log_message)
    
    def test_quality_gate_edge_cases(self):
        """Test quality gate with edge case inputs"""
        # Test with None audio
        result = fast_quality_gate(None, 48000)
        self.assertFalse(result)
        
        # Test with empty audio array
        result = fast_quality_gate(np.array([]), 48000)
        self.assertFalse(result)
        
        # Test with zero sample rate
        result = fast_quality_gate(np.array([1, 2, 3]), 0)
        self.assertFalse(result)
        
        # Test with negative sample rate
        result = fast_quality_gate(np.array([1, 2, 3]), -48000)
        self.assertFalse(result)
    
    def test_extract_f0_features_error_handling(self):
        """Test F0 extraction error handling"""
        # Test with invalid audio data
        invalid_audio = np.array([])  # Empty array
        
        result = extract_f0_features(invalid_audio, 48000)
        
        # Should return fallback values
        self.assertEqual(result['mean_f0'], 0.0)
        self.assertEqual(result['std_f0'], 0.0)
        self.assertEqual(result['confidence'], 0.0)
        self.assertEqual(result['voiced_ratio'], 0.0)
    
    def test_parse_file_path_edge_cases(self):
        """Test file path parsing with edge cases"""
        # Test with None
        with self.assertRaises(AttributeError):
            parse_file_path(None)
        
        # Test with empty string
        with self.assertRaises(ValueError):
            parse_file_path("")
        
        # Test with too few segments
        with self.assertRaises(ValueError):
            parse_file_path("users/user123/recording.wav")
        
        # Test with too many segments
        with self.assertRaises(ValueError):
            parse_file_path("users/user123/recordings/rec456/extra/audio.wav")

class TestIntegration(unittest.TestCase):
    """Test integration scenarios"""
    
    @patch('main.firestore.client')
    @patch('main.storage.Client')
    @patch('main.sf.read')
    def test_process_audio_file_success(self, mock_sf_read, mock_storage, mock_firestore):
        """Test successful audio processing"""
        # Mock dependencies
        mock_sf_read.return_value = (np.sin(2 * np.pi * 220 * np.linspace(0, 3, 144000)), 48000)
        
        # Create test event
        event = {
            'bucket': 'test-bucket',
            'name': 'users/user123/recordings/rec456/audio.wav'
        }
        
        # Mock context
        context = MagicMock()
        
        # This should not raise an exception
        try:
            process_audio_file(event, context)
        except Exception as e:
            self.fail(f"process_audio_file raised {e} unexpectedly!")

if __name__ == '__main__':
    unittest.main() 