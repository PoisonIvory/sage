from typing import List, Dict, Any
from entities import FeatureSet
from feature_extractors.base import BaseFeatureExtractor
from utilities.feature_formatter import FeatureFormatter

class VoiceAnalysisService:
    def __init__(self, extractors: List[BaseFeatureExtractor]):
        self.extractors = extractors

    def analyze(self, audio, sample_rate) -> List[FeatureSet]:
        """
        Analyze audio using all configured extractors.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            List of FeatureSet objects from all extractors
        """
        results = []
        for extractor in self.extractors:
            feature_set = extractor.extract(audio, sample_rate)
            results.append(feature_set)
        return results
    
    def analyze_for_firestore(self, audio, sample_rate) -> Dict[str, Any]:
        """
        Analyze audio and format results for Firestore storage.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            Dictionary ready for Firestore storage with namespaced features
        """
        feature_sets = self.analyze(audio, sample_rate)
        return FeatureFormatter.format_for_firestore(feature_sets) 