"""
Tool versions configuration for Sage voice analysis.

This module centralizes all tool versions used in the voice analysis pipeline
to avoid hardcoding and enable easy version management.

Reference: DATA_STANDARDS.md §3.2.1
"""

from typing import Dict


class ToolVersions:
    """Centralized tool version management."""
    
    # Audio processing tools
    PRAAT_VERSION = "6.4.1"
    PARSELMOUTH_VERSION = "0.4.6"
    LIBROSA_VERSION = "0.10.1"
    SOUNDFILE_VERSION = "0.12.1"
    
    # Analysis pipeline
    ANALYSIS_VERSION = "1.0"
    
    @classmethod
    def get_audio_processing_versions(cls) -> Dict[str, str]:
        """Get versions for audio processing tools."""
        return {
            'praat': cls.PRAAT_VERSION,
            'parselmouth': cls.PARSELMOUTH_VERSION,
            'librosa': cls.LIBROSA_VERSION,
            'soundfile': cls.SOUNDFILE_VERSION
        }
    
    @classmethod
    def get_analysis_versions(cls) -> Dict[str, str]:
        """Get versions for feature extraction tools (Praat, Parselmouth)."""
        return {
            'praat': cls.PRAAT_VERSION,
            'parselmouth': cls.PARSELMOUTH_VERSION
        }
    
    @classmethod
    def get_all_versions(cls) -> Dict[str, str]:
        """Get all tool versions including pipeline versioning."""
        return {
            'praat': cls.PRAAT_VERSION,
            'parselmouth': cls.PARSELMOUTH_VERSION,
            'librosa': cls.LIBROSA_VERSION,
            'soundfile': cls.SOUNDFILE_VERSION,
            'analysis_version': cls.ANALYSIS_VERSION
        }
    
    @classmethod
    def get_versions(cls, *tools: str) -> Dict[str, str]:
        """Get versions for specified tools."""
        all_versions = cls.get_all_versions()
        return {k: v for k, v in all_versions.items() if k in tools} 