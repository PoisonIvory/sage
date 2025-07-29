"""
Base feature extractor class for modular voice analysis.

This module provides the foundation for all feature extractors in the Sage voice analysis pipeline.
Each extractor should inherit from BaseFeatureExtractor and implement the required methods.

Reference: DATA_STANDARDS.md §3.2.1, §3.3
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
import numpy as np

logger = logging.getLogger(__name__)


class BaseFeatureExtractor(ABC):
    """Base class for all feature extractors in the Sage voice analysis pipeline."""
    
    def __init__(self, name: str, version: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the feature extractor.
        
        Args:
            name: Human-readable name of the extractor
            version: Version string for tracking algorithm changes (optional)
            config: Configuration dictionary for dynamic versioning (optional)
        """
        self.name = name
        self.config = config or {}
        self.version = version or self.load_version_from_config(name)
        self.logger = logging.getLogger(f"{__name__}.{name}")
    
    def namespace_key(self, key: str) -> str:
        """
        Generate namespaced key for consistent feature naming.
        
        Args:
            key: Raw feature key
            
        Returns:
            Namespaced key in format "{extractor_name}_{key}"
        """
        return f"{self.name}_{key}"
    
    def load_version_from_config(self, extractor_name: str) -> str:
        """
        Load version from config or return default.
        
        Args:
            extractor_name: Name of the extractor
            
        Returns:
            Version string
        """
        extractor_config = self.config.get(extractor_name, {})
        return extractor_config.get('version', '1.0')
    
    @abstractmethod
    def extract(self, audio: np.ndarray, sample_rate: int) -> Dict[str, Any]:
        """
        Extract features from audio data.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            Dictionary containing extracted features and optional metadata.
            Can return either:
            - Flat dict: {"feature1": value1, "feature2": value2}
            - Structured dict: {"features": {...}, "metadata": {...}}
        """
        pass
    
    def extract_with_error_handling(self, audio: np.ndarray, sample_rate: int, namespace: bool = True) -> Dict[str, Any]:
        """
        Extract features with comprehensive error handling.
        Optionally suppress namespacing for flat export use cases.
        Returns a structured dict with 'features', 'metadata', and 'errors' keys.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            namespace: Whether to namespace feature keys (default True)
        Returns:
            Dict with 'features', 'metadata', and 'errors' keys
        """
        try:
            # Validate inputs
            if audio is None or len(audio) == 0:
                raise ValueError("Audio data is empty or None")
            if sample_rate <= 0:
                raise ValueError(f"Invalid sample rate: {sample_rate}")
            # Extract features
            result = self.extract(audio, sample_rate)
            if not isinstance(result, dict):
                raise ValueError("Extractor must return a dictionary")
            features = result.get("features", result)  # fallback to flat dict
            metadata = result.get("metadata", {})
            # Namespace all feature keys if requested
            if namespace:
                features_out = {self.namespace_key(k): v for k, v in features.items()}
                metadata_out = {self.namespace_key(k): v for k, v in metadata.items()}
            else:
                features_out = dict(features)
                metadata_out = dict(metadata)
            # Add extractor version to metadata
            metadata_out['version'] = self.version
            self.logger.info(f"{self.name} v{self.version} extraction completed successfully")
            return {
                'features': features_out,
                'metadata': metadata_out,
                'errors': None
            }
        except Exception as e:
            self.logger.error(f"{self.name} v{self.version} extraction failed: {str(e)}")
            return {
                'features': {},
                'metadata': {'version': self.version},
                'errors': {
                    'error_type': 'extraction_failed',
                    'error_message': str(e)
                }
            }
    
    def validate_audio_quality(self, audio: np.ndarray, sample_rate: int) -> bool:
        """
        Validate audio quality for this specific extractor.
        
        Override this method in subclasses to add extractor-specific validation.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            True if audio quality is sufficient for this extractor
        """
        # Default implementation - basic checks
        if audio is None or len(audio) == 0:
            return False
        
        duration = len(audio) / sample_rate
        if duration < 0.1:  # Minimum 100ms
            return False
        
        return True
    
    @abstractmethod
    def get_feature_names(self) -> List[str]:
        """
        Get list of canonical feature names that this extractor produces.
        
        Returns:
            List of raw feature names (without namespace)
        """
        pass
    
    def get_namespaced_feature_names(self) -> List[str]:
        """
        Get list of namespaced feature names that this extractor produces.
        
        Returns:
            List of namespaced feature names
        """
        base_names = self.get_feature_names()
        return [self.namespace_key(name) for name in base_names] 