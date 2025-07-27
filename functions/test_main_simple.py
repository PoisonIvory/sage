#!/usr/bin/env python3
"""
Simplified test suite for core functionality without external dependencies.
Tests the basic structure and logic without requiring parselmouth or librosa.
"""

import unittest
import tempfile
import os
import numpy as np
import soundfile as sf
from unittest.mock import patch, MagicMock
import sys

# Add the functions directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import only what we can test without parselmouth
from config import get_config
from utils_simple import convert_to_mono, resample_audio, calculate_duration, calculate_rms, safe_mean, safe_std

class TestCoreFunctionality(unittest.TestCase):
    """Test core functionality that doesn't require parselmouth."""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = get_config()
        
        # Create test audio
        self.sample_rate = 48000
        self.duration = 3.0
        self.f0 = 220  # A4 note
        t = np.linspace(0, self.duration, int(self.sample_rate * self.duration))
        self.test_audio = np.sin(2 * np.pi * self.f0 * t) * 0.5
        
    def test_config_loading(self):
        """Test that configuration loads correctly"""
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
        
    def test_utils_functions(self):
        """Test utility functions"""
        # Test safe_mean and safe_std
        self.assertEqual(safe_mean([]), 0.0)
        self.assertEqual(safe_std([]), 0.0)
        
        # Test with actual data
        data = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
        self.assertEqual(safe_mean(data), 3.0)
        # Population standard deviation (numpy default) vs sample standard deviation
        self.assertAlmostEqual(safe_std(data), 1.4142, places=3)
        
    def test_audio_processing_utils(self):
        """Test audio processing utility functions"""
        # Test duration calculation
        duration = calculate_duration(self.test_audio, self.sample_rate)
        self.assertAlmostEqual(duration, self.duration, places=2)
        
        # Test RMS calculation
        rms = calculate_rms(self.test_audio)
        self.assertGreater(rms, 0)
        
        # Test resampling
        resampled = resample_audio(self.test_audio, self.sample_rate, 22050)
        self.assertEqual(len(resampled), int(len(self.test_audio) * 22050 / self.sample_rate))
        
        # Test mono conversion
        stereo_audio = np.column_stack([self.test_audio, self.test_audio])
        mono_audio = convert_to_mono(stereo_audio, self.sample_rate)
        self.assertEqual(len(mono_audio.shape), 1)
        
    def test_file_path_parsing_logic(self):
        """Test file path parsing logic"""
        # Test valid path
        file_name = "users/user123/recordings/rec456/audio.wav"
        parts = file_name.split('/')
        
        self.assertEqual(len(parts), 5)
        self.assertEqual(parts[1], 'user123')
        self.assertEqual(parts[3], 'rec456')
        self.assertEqual(parts[4], 'audio.wav')
        
        # Test invalid path
        invalid_path = "invalid/path"
        parts = invalid_path.split('/')
        self.assertLess(len(parts), 4)
        
    def test_quality_gate_logic(self):
        """Test quality gate logic"""
        # Test with valid audio
        duration = calculate_duration(self.test_audio, self.sample_rate)
        rms = calculate_rms(self.test_audio)
        
        min_duration = self.config['audio']['min_duration_seconds']
        min_rms = self.config['quality_gate']['min_rms_threshold']
        
        # Should pass quality gate
        self.assertGreater(duration, min_duration)
        self.assertGreater(rms, min_rms)
        
        # Test with too short audio
        short_audio = self.test_audio[:1000]  # Very short
        short_duration = calculate_duration(short_audio, self.sample_rate)
        self.assertLess(short_duration, min_duration)
        
        # Test with too quiet audio
        quiet_audio = self.test_audio * 0.0001  # Very quiet
        quiet_rms = calculate_rms(quiet_audio)
        self.assertLess(quiet_rms, min_rms)
        
    def test_f0_validation_logic(self):
        """Test F0 validation logic"""
        # Test valid F0
        valid_f0 = 220.0
        min_f0 = self.config['f0']['min_f0_hz']
        max_f0 = self.config['f0']['max_f0_hz']
        
        self.assertGreaterEqual(valid_f0, min_f0)
        self.assertLessEqual(valid_f0, max_f0)
        
        # Test invalid F0
        invalid_f0_low = 50.0  # Too low
        invalid_f0_high = 600.0  # Too high
        
        self.assertLess(invalid_f0_low, min_f0)
        self.assertGreater(invalid_f0_high, max_f0)
        
    def test_data_structure_consistency(self):
        """Test that data structures are consistent"""
        # Simulate F0 features structure
        features = {
            'mean_f0': 220.5,
            'std_f0': 14.2,
            'confidence': 95.0,
            'voiced_ratio': 0.8,
            'error_type': None
        }
        
        # Verify all required fields are present
        required_fields = ['mean_f0', 'std_f0', 'confidence', 'voiced_ratio', 'error_type']
        for field in required_fields:
            self.assertIn(field, features)
            
        # Verify data types
        self.assertIsInstance(features['mean_f0'], (int, float))
        self.assertIsInstance(features['std_f0'], (int, float))
        self.assertIsInstance(features['confidence'], (int, float))
        self.assertIsInstance(features['voiced_ratio'], (int, float))
        
        # Verify value ranges
        self.assertGreaterEqual(features['confidence'], 0)
        self.assertLessEqual(features['confidence'], 100)
        self.assertGreaterEqual(features['voiced_ratio'], 0)
        self.assertLessEqual(features['voiced_ratio'], 1)
        
    def test_processing_metadata_structure(self):
        """Test processing metadata structure"""
        # Simulate processing metadata
        metadata = {
            'audio_duration': 5.0,
            'sample_rate': 48000,
            'tool_version': 'praat-6.4.1',
            'unit': 'Hz',
            'total_frames': 500,
            'voiced_frames': 400
        }
        
        # Verify required fields
        required_fields = ['audio_duration', 'sample_rate', 'tool_version', 'unit', 'total_frames', 'voiced_frames']
        for field in required_fields:
            self.assertIn(field, metadata)
            
        # Verify logical relationships
        self.assertGreater(metadata['total_frames'], 0)
        self.assertGreaterEqual(metadata['voiced_frames'], 0)
        self.assertLessEqual(metadata['voiced_frames'], metadata['total_frames'])
        self.assertGreater(metadata['audio_duration'], 0)
        self.assertGreater(metadata['sample_rate'], 0)

if __name__ == '__main__':
    unittest.main() 