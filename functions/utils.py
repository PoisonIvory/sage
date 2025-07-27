# MVP Utility Functions - Essential helpers only
import numpy as np
import librosa
import soundfile as sf

def convert_to_mono(audio: np.ndarray, sample_rate: int) -> np.ndarray:
    """
    Convert stereo audio to mono with shape validation.
    
    Args:
        audio (np.ndarray): Audio data as numpy array
        sample_rate (int): Audio sample rate in Hz (unused but kept for interface consistency)
        
    Returns:
        np.ndarray: Mono audio data
        
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
        audio (np.ndarray): Audio data as numpy array
        original_rate (int): Original sample rate in Hz
        target_rate (int): Target sample rate in Hz
        
    Returns:
        np.ndarray: Resampled audio data
        
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
        audio (np.ndarray): Audio data as numpy array
        sample_rate (int): Audio sample rate in Hz
        
    Returns:
        float: Duration in seconds
        
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
        audio (np.ndarray): Audio data as numpy array
        
    Returns:
        float: RMS energy value
        
    Raises:
        ValueError: If audio data is empty or invalid
    """
    return np.sqrt(np.mean(audio**2))

def safe_mean(values: np.ndarray) -> float:
    """
    Safely calculate mean, returning 0 if array is empty.
    
    Args:
        values (np.ndarray): Array of numeric values
        
    Returns:
        float: Mean value or 0.0 if array is empty
        
    Raises:
        ValueError: If values array is None
    """
    return float(np.mean(values)) if len(values) > 0 else 0.0

def safe_std(values: np.ndarray) -> float:
    """
    Safely calculate standard deviation, returning 0 if array is empty.
    
    Args:
        values (np.ndarray): Array of numeric values
        
    Returns:
        float: Standard deviation or 0.0 if array is empty
        
    Raises:
        ValueError: If values array is None
    """
    return float(np.std(values)) if len(values) > 0 else 0.0 