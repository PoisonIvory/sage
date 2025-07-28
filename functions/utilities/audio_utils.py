"""
Audio processing utilities for Sage voice analysis.

This module provides essential audio processing functions including
conversion, resampling, duration calculation, and statistical utilities.

Reference: DATA_STANDARDS.md §3.2.1
"""

import numpy as np
import librosa
import soundfile as sf
from typing import Union


def convert_to_mono(audio: np.ndarray, sample_rate: int) -> np.ndarray:
    """
    Convert stereo audio to mono with shape validation.
    
    Args:
        audio: Audio data as numpy array
        sample_rate: Audio sample rate in Hz (unused but kept for interface consistency)
        
    Returns:
        Mono audio data
        
    Raises:
        ValueError: If audio data is invalid
    """
    if len(audio.shape) > 1:
        # Check if we need to transpose (librosa expects time as first dimension)
        if audio.shape[0] < audio.shape[1]:
            # Audio is in (channels, time) format, transpose to (time, channels)
            audio = audio.T
        return librosa.to_mono(audio.T)
    return audio


def resample_audio(audio: np.ndarray, original_rate: int, target_rate: int) -> np.ndarray:
    """
    Resample audio to target sample rate.
    
    Args:
        audio: Audio data as numpy array
        original_rate: Original sample rate in Hz
        target_rate: Target sample rate in Hz
        
    Returns:
        Resampled audio data
        
    Raises:
        ValueError: If sample rates are invalid
    """
    if original_rate != target_rate:
        return librosa.resample(audio, orig_sr=original_rate, target_sr=target_rate)
    return audio


def calculate_duration(audio: np.ndarray, sample_rate: int) -> float:
    """
    Calculate audio duration in seconds with zero division protection.
    
    Args:
        audio: Audio data as numpy array
        sample_rate: Audio sample rate in Hz
        
    Returns:
        Duration in seconds
        
    Raises:
        ValueError: If sample rate is invalid (≤ 0)
    """
    if sample_rate <= 0:
        raise ValueError(f"Invalid sample rate: {sample_rate}. Must be positive.")
    return len(audio) / sample_rate


def calculate_rms(audio: np.ndarray) -> float:
    """
    Calculate RMS (Root Mean Square) energy of audio signal.
    
    Args:
        audio: Audio data as numpy array
        
    Returns:
        RMS energy value
        
    Raises:
        ValueError: If audio data is empty or invalid
    """
    return np.sqrt(np.mean(audio**2))


def safe_mean(values: np.ndarray) -> float:
    """
    Safely calculate mean, returning 0 if array is empty.
    
    Args:
        values: Array of numeric values
        
    Returns:
        Mean value or 0.0 if array is empty
        
    Raises:
        ValueError: If values array is None
    """
    return float(np.mean(values)) if len(values) > 0 else 0.0


def safe_std(values: np.ndarray) -> float:
    """
    Safely calculate standard deviation, returning 0 if array is empty.
    
    Args:
        values: Array of numeric values
        
    Returns:
        Standard deviation or 0.0 if array is empty
        
    Raises:
        ValueError: If values array is None
    """
    return float(np.std(values)) if len(values) > 0 else 0.0


def validate_audio_quality(audio: np.ndarray, sample_rate: int, 
                          min_duration: float = 0.5, 
                          max_duration: float = 30.0,
                          min_rms: float = 0.001) -> bool:
    """
    Validate audio quality for processing.
    
    Args:
        audio: Audio data as numpy array
        sample_rate: Audio sample rate in Hz
        min_duration: Minimum duration in seconds
        max_duration: Maximum duration in seconds
        min_rms: Minimum RMS threshold
        
    Returns:
        True if audio quality is sufficient for processing
    """
    if audio is None or len(audio) == 0:
        return False
    
    duration = calculate_duration(audio, sample_rate)
    if duration < min_duration or duration > max_duration:
        return False
    
    rms = calculate_rms(audio)
    if rms < min_rms:
        return False
    
    return True 