"""
Feature formatter utility for Sage voice analysis.

This module provides utilities for formatting and aggregating feature sets
for Firestore storage and consistent data handling.

Reference: DATA_STANDARDS.md §3.2.1
"""

from typing import List, Dict, Any
from entities import FeatureSet


class FeatureFormatter:
    """Utility class for formatting and aggregating feature sets."""
    
    @staticmethod
    def flatten_feature_sets(feature_sets: List[FeatureSet]) -> Dict[str, Any]:
        """
        Flatten multiple feature sets into a single Firestore-ready dictionary.
        
        Args:
            feature_sets: List of FeatureSet objects from various extractors
            
        Returns:
            Dictionary with namespaced feature keys and metadata
        """
        flattened = {}
        
        for fs in feature_sets:
            # Add features with extractor namespace
            for key, value in fs.features.items():
                namespaced_key = f"{fs.extractor}_{key}"
                flattened[namespaced_key] = value
            
            # Add version information
            flattened[f"{fs.extractor}_version"] = fs.version
            
            # Add error information if present
            if fs.error:
                flattened[f"{fs.extractor}_error_type"] = fs.error
                flattened[f"{fs.extractor}_error_message"] = fs.error_message
            
            # Add metadata if present
            if fs.metadata:
                for key, value in fs.metadata.__dict__.items():
                    if value is not None:
                        flattened[f"{fs.extractor}_metadata_{key}"] = value
        
        return flattened
    
    @staticmethod
    def format_for_firestore(feature_sets: List[FeatureSet]) -> Dict[str, Any]:
        """
        Format feature sets specifically for Firestore storage.
        
        Args:
            feature_sets: List of FeatureSet objects
            
        Returns:
            Dictionary ready for Firestore storage with proper typing
        """
        return FeatureFormatter.flatten_feature_sets(feature_sets) 