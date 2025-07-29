"""
Test suite for VocalAnalysisExtractor using BDD/TDD principles.

This module tests the consolidated vocal analysis extractor that extracts
F0, jitter, shimmer, and HNR features in a single analysis pass.

Domain Context: Menstrual cycle vocal biomarker tracking
Behavior: Extract comprehensive voice features from sustained vowel recordings
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import numpy as np
import tempfile
import os

from feature_extractors.vocal_analysis_extractor import VocalAnalysisExtractor
from entities import FeatureSet, FeatureMetadata


class TestVocalAnalysisExtractorBehavior(unittest.TestCase):
    """
    Behavior-driven tests for vocal analysis extractor.
    
    Domain: Menstrual cycle vocal biomarker tracking
    Context: Sustained vowel recordings from iOS app
    """
    
    def setUp(self):
        """Set up test fixtures following domain context."""
        self.config = {
            'vocal_analysis': {
                'min_f0_hz': 75,
                'max_f0_hz': 500,
                'time_step': 0.01,
                'hnr_time_step': 0.01,
                'max_jitter_local': 5.0,
                'max_shimmer_local': 10.0
            }
        }
        self.extractor = VocalAnalysisExtractor(self.config)
        
        # Create synthetic sustained vowel audio (220 Hz sine wave = A4)
        duration = 2.0  # 2 seconds - sufficient for voice quality analysis
        sample_rate = 48000
        t = np.linspace(0, duration, int(sample_rate * duration))
        frequency = 220  # Adult female typical F0
        self.test_audio = np.sin(2 * np.pi * frequency * t) * 0.5
        self.sample_rate = sample_rate
    
    def test_extractor_follows_domain_naming_conventions(self):
        """
        Scenario: Clinical voice analysis requires standard feature names
        Given: VocalAnalysisExtractor is initialized
        When: Getting feature names
        Then: Should return clinically relevant feature names
        """
        feature_names = self.extractor.get_feature_names()
        
        # Domain-specific assertions
        self.assertIn('f0_mean', feature_names, "F0 mean is core vocal biomarker")
        self.assertIn('f0_std', feature_names, "F0 variability tracks hormonal changes") 
        self.assertIn('jitter_local', feature_names, "Jitter measures vocal fold stability")
        self.assertIn('shimmer_local', feature_names, "Shimmer measures amplitude perturbation")
        self.assertIn('hnr_mean', feature_names, "HNR measures voice breathiness")
        self.assertIn('vocal_stability_score', feature_names, "Overall voice quality metric")
    
    def test_sustained_vowel_analysis_extracts_all_biomarkers(self):
        """
        Scenario: User records sustained vowel for cycle tracking
        Given: 2-second sustained vowel recording at 220 Hz
        When: Extracting vocal biomarkers
        Then: Should extract F0, jitter, shimmer, and HNR features
        """
        with patch('parselmouth.Sound') as mock_sound_class:
            # Mock Parselmouth objects following actual API
            mock_sound = Mock()
            mock_sound_class.return_value = mock_sound
            
            mock_pitch = Mock()
            mock_pitch.selected_array = {'frequency': np.full(200, 220.0)}  # Stable 220 Hz
            mock_sound.to_pitch.return_value = mock_pitch
            
            mock_harmonicity = Mock()
            mock_harmonicity.values = np.full(200, 18.0)  # Good HNR
            mock_sound.to_harmonicity.return_value = mock_harmonicity
            
            # Mock point process for jitter/shimmer
            with patch('parselmouth.praat.call') as mock_praat_call:
                mock_praat_call.side_effect = [
                    Mock(),  # point process creation
                    0.005,   # jitter local (0.5%)
                    0.00002, # jitter absolute  
                    0.03,    # shimmer local (3%)
                    0.25,    # shimmer dB
                ]
                
                result = self.extractor.extract(self.test_audio, self.sample_rate)
        
        # Domain behavior assertions
        self.assertIsInstance(result, FeatureSet)
        self.assertEqual(result.extractor, 'vocal_analysis')
        
        # F0 biomarkers (core for cycle tracking)
        self.assertAlmostEqual(result.features['f0_mean'], 220.0, places=1)
        self.assertGreater(result.features['f0_confidence'], 80.0)
        
        # Voice quality biomarkers (secondary indicators)
        self.assertEqual(result.features['jitter_local'], 0.5)  # 0.5% jitter
        self.assertEqual(result.features['shimmer_local'], 3.0)  # 3% shimmer  
        self.assertEqual(result.features['hnr_mean'], 18.0)      # Good voice quality
        
        # Composite score for app UX
        self.assertGreater(result.features['vocal_stability_score'], 0.0)
    
    def test_poor_quality_audio_provides_degraded_confidence(self):
        """
        Scenario: User recording has background noise or poor technique
        Given: Audio with high jitter and low HNR
        When: Extracting vocal biomarkers  
        Then: Should return low confidence scores but still extract features
        """
        with patch('parselmouth.Sound') as mock_sound_class:
            mock_sound = Mock()
            mock_sound_class.return_value = mock_sound
            
            # Simulate noisy pitch with gaps
            noisy_pitch = np.full(200, 220.0)
            noisy_pitch[1::2] = 0  # 50% unvoiced frames
            noisy_pitch[::3] = 0  # Additional gaps - ~67% unvoiced frames (poor quality)
            mock_pitch = Mock()
            mock_pitch.selected_array = {'frequency': noisy_pitch}
            mock_sound.to_pitch.return_value = mock_pitch
            
            # Poor voice quality parameters
            mock_harmonicity = Mock()
            mock_harmonicity.values = np.full(200, 8.0)  # Poor HNR
            mock_sound.to_harmonicity.return_value = mock_harmonicity
            
            with patch('parselmouth.praat.call') as mock_praat_call:
                mock_praat_call.side_effect = [
                    Mock(),  # point process
                    0.08,    # high jitter (8%)
                    0.0008,  # high absolute jitter
                    0.15,    # high shimmer (15%)
                    1.2,     # high shimmer dB
                ]
                
                result = self.extractor.extract(self.test_audio, self.sample_rate)
        
        # Should still extract features but with low confidence
        self.assertIsInstance(result, FeatureSet)
        self.assertLess(result.features['f0_confidence'], 50.0)  # Low confidence
        self.assertLess(result.features['vocal_stability_score'], 30.0)  # Poor quality
        
        # But features should still be present for research value
        self.assertGreater(result.features['jitter_local'], 5.0)
        self.assertGreater(result.features['shimmer_local'], 10.0)
    
    def test_audio_duration_validation_follows_clinical_standards(self):
        """
        Scenario: Clinical voice analysis requires minimum duration
        Given: VocalAnalysisExtractor for voice quality measurement
        When: Validating audio shorter than 1 second
        Then: Should reject as insufficient for reliable jitter/shimmer
        """
        short_audio = self.test_audio[:24000]  # 0.5 seconds
        
        is_valid = self.extractor.validate_audio_quality(short_audio, self.sample_rate)
        
        self.assertFalse(is_valid, "Voice quality analysis requires ≥1 second audio")
    
    def test_error_handling_preserves_research_data_integrity(self):
        """
        Scenario: Parselmouth fails but research pipeline continues
        Given: Parselmouth library unavailable or crashes
        When: Extracting vocal biomarkers
        Then: Should return zero values with error metadata for data consistency
        """
        with patch('parselmouth.Sound', side_effect=ImportError("Parselmouth not available")):
            result = self.extractor.extract(self.test_audio, self.sample_rate)
        
        # Data integrity assertions
        self.assertIsInstance(result, FeatureSet)
        self.assertEqual(result.error, 'parselmouth_unavailable')
        
        # Should return structured zero values to clearly indicate failure
        self.assertEqual(result.features['f0_mean'], 0.0)
        self.assertEqual(result.features['jitter_local'], 0.0)
        self.assertEqual(result.features['vocal_stability_score'], 0.0)
        
        # Metadata preserved for research filtering
        self.assertIsNotNone(result.metadata)
    
    def test_feature_confidence_scoring_uses_clinical_thresholds(self):
        """
        Scenario: App needs to communicate voice quality to users
        Given: Extracted voice features with known clinical ranges
        When: Calculating confidence scores
        Then: Should use established clinical thresholds for jitter/shimmer/HNR
        """
        # Clinical normal ranges:
        # Jitter < 1.04% (excellent), < 2% (good), >5% (pathological)
        # Shimmer < 3.81% (excellent), < 6% (good), >10% (pathological)  
        # HNR > 20dB (excellent), > 15dB (good), <10dB (poor)
        
        excellent_features = {
            'f0_confidence': 95.0,  # 95% - excellent F0 confidence
            'jitter_local': 0.8,    # 0.8% - excellent
            'shimmer_local': 2.5,   # 2.5% - excellent  
            'hnr_mean': 22.0        # 22dB - excellent
        }
        
        confidence = self.extractor._calculate_vocal_stability_score(excellent_features)
        self.assertGreater(confidence, 85.0, "Excellent voice quality should score >85")
        
        pathological_features = {
            'f0_confidence': 30.0,  # 30% - poor F0 confidence
            'jitter_local': 8.0,    # 8% - pathological
            'shimmer_local': 15.0,  # 15% - pathological
            'hnr_mean': 8.0         # 8dB - poor
        }
        
        confidence = self.extractor._calculate_vocal_stability_score(pathological_features)
        self.assertLess(confidence, 30.0, "Poor voice quality should score <30")


class TestVocalAnalysisExtractorIntegration(unittest.TestCase):
    """Integration tests for vocal analysis extractor in research pipeline."""
    
    def setUp(self):
        """Set up integration test fixtures."""
        self.config = {
            'vocal_analysis': {
                'min_f0_hz': 75,
                'max_f0_hz': 500,
                'time_step': 0.01
            }
        }
        self.extractor = VocalAnalysisExtractor(self.config)
    
    def test_extractor_integrates_with_feature_pipeline(self):
        """
        Scenario: VocalAnalysisExtractor works in existing pipeline
        Given: Current FeatureExtractionPipeline architecture
        When: Using VocalAnalysisExtractor instead of F0Extractor
        Then: Should produce compatible FeatureSet output
        """
        # This will be tested when we update the pipeline
        pass


if __name__ == "__main__":
    unittest.main()