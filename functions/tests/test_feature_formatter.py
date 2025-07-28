"""
Tests for FeatureFormatter utility.

This module tests the FeatureFormatter class to ensure proper
namespacing and Firestore formatting.
"""

import unittest
from unittest.mock import Mock
from entities import FeatureSet, FeatureMetadata
from utilities.feature_formatter import FeatureFormatter


class TestFeatureFormatter(unittest.TestCase):
    """Test cases for FeatureFormatter utility."""
    
    def test_flatten_feature_sets_basic(self):
        """Test basic feature set flattening with namespacing."""
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
        
        # When: Flattening feature sets
        result = FeatureFormatter.flatten_feature_sets([vocal_features])
        
        # Then: Features should be namespaced
        self.assertIn("vocal_analysis_f0_mean", result)
        self.assertIn("vocal_analysis_f0_std", result)
        self.assertIn("vocal_analysis_f0_confidence", result)
        self.assertIn("vocal_analysis_jitter_local", result)
        self.assertIn("vocal_analysis_shimmer_local", result)
        self.assertIn("vocal_analysis_hnr_mean", result)
        self.assertEqual(result["vocal_analysis_f0_mean"], 220.0)
        self.assertEqual(result["vocal_analysis_f0_std"], 5.0)
        self.assertEqual(result["vocal_analysis_f0_confidence"], 85.0)
        self.assertEqual(result["vocal_analysis_jitter_local"], 0.5)
        self.assertEqual(result["vocal_analysis_version"], "1.0")
        self.assertEqual(result["vocal_analysis_metadata_voiced_ratio"], 0.8)
        self.assertEqual(result["vocal_analysis_metadata_sample_rate"], 48000)
    
    def test_flatten_feature_sets_with_errors(self):
        """Test feature set flattening with error handling."""
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
        
        # When: Flattening feature sets with errors
        result = FeatureFormatter.flatten_feature_sets([error_features])
        
        # Then: Error information should be included
        self.assertIn("vocal_analysis_error_type", result)
        self.assertIn("vocal_analysis_error_message", result)
        self.assertEqual(result["vocal_analysis_error_type"], "extraction_failed")
        self.assertEqual(result["vocal_analysis_error_message"], "Audio too short")
    
    def test_flatten_multiple_extractors(self):
        """Test flattening multiple extractors with different namespaces."""
        # Given: VocalAnalysisExtractor and a future FormantExtractor
        vocal_features = FeatureSet(
            extractor="vocal_analysis",
            version="1.0",
            features={"f0_mean": 220.0, "f0_std": 5.0},
            metadata=FeatureMetadata(voiced_ratio=0.8),
            error=None,
            error_message=None
        )
        
        # Mock future formant extractor for reading tasks
        formant_features = FeatureSet(
            extractor="formant_analysis",
            version="1.0",
            features={"f1_mean": 800.0, "f2_mean": 1200.0},
            metadata=FeatureMetadata(duration_seconds=3.0),
            error=None,
            error_message=None
        )
        
        # When: Flattening multiple feature sets
        result = FeatureFormatter.flatten_feature_sets([vocal_features, formant_features])
        
        # Then: All features should be properly namespaced
        self.assertIn("vocal_analysis_f0_mean", result)
        self.assertIn("vocal_analysis_f0_std", result)
        self.assertIn("formant_analysis_f1_mean", result)
        self.assertIn("formant_analysis_f2_mean", result)
        self.assertEqual(result["vocal_analysis_f0_mean"], 220.0)
        self.assertEqual(result["formant_analysis_f1_mean"], 800.0)
        self.assertEqual(result["vocal_analysis_version"], "1.0")
        self.assertEqual(result["formant_analysis_version"], "1.0")
    
    def test_format_for_firestore(self):
        """Test the format_for_firestore method."""
        # Given: VocalAnalysisExtractor feature set
        features = FeatureSet(
            extractor="vocal_analysis",
            version="1.0",
            features={"f0_mean": 220.0},
            metadata=FeatureMetadata(voiced_ratio=0.8),
            error=None,
            error_message=None
        )
        
        # When: Formatting for Firestore
        result = FeatureFormatter.format_for_firestore([features])
        
        # Then: Should return the same as flatten_feature_sets
        expected = FeatureFormatter.flatten_feature_sets([features])
        self.assertEqual(result, expected)


if __name__ == "__main__":
    unittest.main() 