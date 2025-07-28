"""
Integration tests for the voice analysis pipeline.

This module tests the complete pipeline from feature extraction
to Firestore formatting.
"""

import unittest
from unittest.mock import Mock, patch
import numpy as np
from entities import FeatureSet, FeatureMetadata
from utilities.feature_formatter import FeatureFormatter
from services.voice_analysis_service import VoiceAnalysisService
from feature_extractors.vocal_analysis_extractor import VocalAnalysisExtractor


class TestIntegration(unittest.TestCase):
    """Integration tests for the voice analysis pipeline."""
    
    def test_pipeline_integration(self):
        """Test the complete pipeline from audio to Firestore format."""
        # Given: Mock audio data and configuration
        mock_audio = np.random.randn(48000)  # 1 second at 48kHz
        sample_rate = 48000
        config = {
            'vocal_analysis': {
                'time_step': 0.01,
                'min_f0_hz': 75,
                'max_f0_hz': 500,
                'max_jitter_local': 5.0,
                'max_shimmer_local': 10.0,
                'excellent_hnr_threshold': 20.0
            }
        }
        
        # When: Running the complete pipeline
        service = VoiceAnalysisService([VocalAnalysisExtractor(config)])
        firestore_result = service.analyze_for_firestore(mock_audio, sample_rate)
        
        # Then: Result should be properly formatted for Firestore
        self.assertIsInstance(firestore_result, dict)
        self.assertIn('vocal_analysis_version', firestore_result)
        
        # Check that vocal analysis features are namespaced
        vocal_features = [key for key in firestore_result.keys() if key.startswith('vocal_analysis_')]
        self.assertGreater(len(vocal_features), 0)
        
        # Check that version is included
        self.assertIn('vocal_analysis_version', firestore_result)
    
    def test_feature_formatter_integration(self):
        """Test FeatureFormatter with real FeatureSet objects."""
        # Given: VocalAnalysisExtractor feature set
        vocal_features = FeatureSet(
            extractor="vocal_analysis",
            version="1.0",
            features={
                "f0_mean": 220.0, 
                "f0_std": 5.0, 
                "f0_confidence": 85.0,
                "jitter_local": 0.5,
                "shimmer_local": 3.0,
                "hnr_mean": 18.5,
                "vocal_stability_score": 82.0
            },
            metadata=FeatureMetadata(voiced_ratio=0.8, sample_rate=48000),
            error=None,
            error_message=None
        )
        
        # When: Formatting for Firestore
        result = FeatureFormatter.format_for_firestore([vocal_features])
        
        # Then: Should have proper namespacing
        self.assertIn("vocal_analysis_f0_mean", result)
        self.assertIn("vocal_analysis_f0_std", result)
        self.assertIn("vocal_analysis_f0_confidence", result)
        self.assertIn("vocal_analysis_jitter_local", result)
        self.assertIn("vocal_analysis_shimmer_local", result)
        self.assertIn("vocal_analysis_hnr_mean", result)
        self.assertIn("vocal_analysis_vocal_stability_score", result)
        self.assertIn("vocal_analysis_version", result)
        self.assertIn("vocal_analysis_metadata_voiced_ratio", result)
        self.assertIn("vocal_analysis_metadata_sample_rate", result)
        
        # Values should be correct
        self.assertEqual(result["vocal_analysis_f0_mean"], 220.0)
        self.assertEqual(result["vocal_analysis_f0_std"], 5.0)
        self.assertEqual(result["vocal_analysis_f0_confidence"], 85.0)
        self.assertEqual(result["vocal_analysis_jitter_local"], 0.5)
        self.assertEqual(result["vocal_analysis_version"], "1.0")
        self.assertEqual(result["vocal_analysis_metadata_voiced_ratio"], 0.8)
        self.assertEqual(result["vocal_analysis_metadata_sample_rate"], 48000)
    
    def test_error_handling_integration(self):
        """Test error handling in the pipeline."""
        # Given: VocalAnalysisExtractor feature set with error
        error_features = FeatureSet(
            extractor="vocal_analysis",
            version="1.0",
            features={
                "f0_mean": 0.0, 
                "f0_std": 0.0, 
                "f0_confidence": 0.0,
                "jitter_local": 0.0,
                "shimmer_local": 0.0,
                "hnr_mean": 0.0,
                "vocal_stability_score": 0.0
            },
            metadata=FeatureMetadata(voiced_ratio=0.0, sample_rate=48000),
            error="extraction_failed",
            error_message="Audio too short"
        )
        
        # When: Formatting for Firestore
        result = FeatureFormatter.format_for_firestore([error_features])
        
        # Then: Error information should be included
        self.assertIn("vocal_analysis_error_type", result)
        self.assertIn("vocal_analysis_error_message", result)
        self.assertEqual(result["vocal_analysis_error_type"], "extraction_failed")
        self.assertEqual(result["vocal_analysis_error_message"], "Audio too short")


if __name__ == "__main__":
    unittest.main() 