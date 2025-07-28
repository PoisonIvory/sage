"""
Vocal Analysis Extractor for Sage menstrual cycle voice tracking.

This module extracts comprehensive vocal biomarkers (F0, jitter, shimmer, HNR) 
from sustained vowel recordings in a single analysis pass for maximum efficiency
and clinical accuracy.

Domain Context: Menstrual cycle vocal biomarker research
Clinical Focus: Voice features that correlate with hormonal fluctuations

Reference: DATA_STANDARDS.md §3.2.1
"""

import tempfile
import os
import logging
from typing import Dict, Any, Optional, List
import numpy as np
import soundfile as sf

from .base import BaseFeatureExtractor
from utilities.audio_utils import safe_mean, safe_std
from entities import FeatureSet, FeatureMetadata


class VocalAnalysisExtractor(BaseFeatureExtractor):
    """
    Extract comprehensive vocal biomarkers for menstrual cycle tracking.
    
    Combines F0, jitter, shimmer, and HNR analysis in a single Parselmouth pass
    to maximize efficiency and ensure feature consistency for hormonal correlation research.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize vocal analysis extractor with clinical parameters.
        
        Args:
            config: Configuration dictionary containing vocal analysis parameters
        """
        super().__init__(name="vocal_analysis", config=config)
        
        # Core vocal parameters (shared across all features)
        vocal_config = self.config.get('vocal_analysis', {})
        self.time_step = vocal_config.get('time_step', 0.01)
        self.min_f0_hz = vocal_config.get('min_f0_hz', 75)
        self.max_f0_hz = vocal_config.get('max_f0_hz', 500)
        
        # Voice quality thresholds (clinical standards)
        self.max_jitter_local = vocal_config.get('max_jitter_local', 5.0)  # % - pathological threshold
        self.max_shimmer_local = vocal_config.get('max_shimmer_local', 10.0)  # % - pathological threshold
        self.excellent_hnr_threshold = vocal_config.get('excellent_hnr_threshold', 20.0)  # dB
        
        self.logger = logging.getLogger(f"{__name__}.VocalAnalysisExtractor")
    
    def extract(self, audio: np.ndarray, sample_rate: int) -> FeatureSet:
        """
        Extract comprehensive vocal biomarkers from sustained vowel recording.
        
        Domain Behavior: Single-pass analysis of voice features relevant to
        menstrual cycle tracking and hormonal fluctuation research.
        
        Args:
            audio: Audio data as numpy array (sustained vowel recording)
            sample_rate: Sample rate in Hz
            
        Returns:
            FeatureSet containing F0, jitter, shimmer, and HNR features
        """
        temp_audio_file = None
        try:
            import parselmouth
            
            # === AUDIO PREPARATION ===
            temp_audio_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
            sf.write(temp_audio_file.name, audio, sample_rate)
            
            # Load audio into Praat (single load for all analyses)
            sound = parselmouth.Sound(temp_audio_file.name)
            
            # === CORE PITCH ANALYSIS ===
            # This forms the foundation for all other voice quality measures
            pitch = sound.to_pitch(
                time_step=self.time_step,
                pitch_floor=self.min_f0_hz,
                pitch_ceiling=self.max_f0_hz
            )
            
            pitch_values = pitch.selected_array['frequency']
            voiced_frames = pitch_values[pitch_values > 0]
            
            # Initialize feature dictionary
            features = {}
            
            # === F0 BIOMARKERS (PRIMARY) ===
            if len(voiced_frames) > 0:
                features['f0_mean'] = round(safe_mean(voiced_frames), 1)
                features['f0_std'] = round(safe_std(voiced_frames), 1)
                voiced_ratio = len(voiced_frames) / len(pitch_values)
                features['f0_confidence'] = round(voiced_ratio * 100, 1)
            else:
                self.logger.warning("No voiced frames detected - returning zero F0 values")
                features.update({
                    'f0_mean': 0.0,
                    'f0_std': 0.0,
                    'f0_confidence': 0.0
                })
                voiced_ratio = 0.0
            
            # === VOICE QUALITY BIOMARKERS (SECONDARY) ===
            # Only calculate if we have sufficient voiced content
            if len(voiced_frames) > 10:  # Need minimum voiced frames for reliability
                try:
                    # Get point process for jitter/shimmer analysis
                    point_process = parselmouth.praat.call([sound, pitch], "To PointProcess (cc)")
                    
                    # Jitter measures (vocal fold stability) - Research-grade suite
                    jitter_local = parselmouth.praat.call(
                        point_process, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3
                    )
                    features['jitter_local'] = round(jitter_local * 100, 3)  # % - 3 decimal precision
                    
                    jitter_absolute = parselmouth.praat.call(
                        point_process, "Get jitter (local, absolute)", 0, 0, 0.0001, 0.02, 1.3
                    )
                    features['jitter_absolute'] = round(jitter_absolute * 1000000, 1)  # µs - microseconds
                    
                    jitter_rap = parselmouth.praat.call(
                        point_process, "Get jitter (rap)", 0, 0, 0.0001, 0.02, 1.3
                    )
                    features['jitter_rap'] = round(jitter_rap * 100, 3)  # % - Relative Average Perturbation
                    
                    jitter_ppq5 = parselmouth.praat.call(
                        point_process, "Get jitter (ppq5)", 0, 0, 0.0001, 0.02, 1.3
                    )
                    features['jitter_ppq5'] = round(jitter_ppq5 * 100, 3)  # % - 5-point Period Perturbation
                    
                    # Shimmer measures (amplitude perturbation) - Research-grade suite
                    shimmer_local = parselmouth.praat.call(
                        [sound, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6
                    )
                    features['shimmer_local'] = round(shimmer_local * 100, 3)  # % - 3 decimal precision
                    
                    shimmer_db = parselmouth.praat.call(
                        [sound, point_process], "Get shimmer (local_db)", 0, 0, 0.0001, 0.02, 1.3, 1.6
                    )
                    features['shimmer_db'] = round(shimmer_db, 3)  # dB
                    
                    shimmer_apq3 = parselmouth.praat.call(
                        [sound, point_process], "Get shimmer (apq3)", 0, 0, 0.0001, 0.02, 1.3, 1.6
                    )
                    features['shimmer_apq3'] = round(shimmer_apq3 * 100, 3)  # % - 3-point Amplitude Perturbation
                    
                    shimmer_apq5 = parselmouth.praat.call(
                        [sound, point_process], "Get shimmer (apq5)", 0, 0, 0.0001, 0.02, 1.3, 1.6
                    )
                    features['shimmer_apq5'] = round(shimmer_apq5 * 100, 3)  # % - 5-point Amplitude Perturbation
                    
                except Exception as e:
                    self.logger.warning(f"Jitter/Shimmer calculation failed: {e}")
                    features.update({
                        'jitter_local': 0.0,
                        'jitter_absolute': 0.0,
                        'jitter_rap': 0.0,
                        'jitter_ppq5': 0.0,
                        'shimmer_local': 0.0,
                        'shimmer_db': 0.0,
                        'shimmer_apq3': 0.0,
                        'shimmer_apq5': 0.0
                    })
                
                # HNR analysis (voice breathiness/roughness)
                try:
                    harmonicity = sound.to_harmonicity(
                        time_step=self.time_step, 
                        minimum_pitch=self.min_f0_hz
                    )
                    hnr_values = harmonicity.values[harmonicity.values != -200]  # Remove undefined
                    
                    if len(hnr_values) > 0:
                        features['hnr_mean'] = round(safe_mean(hnr_values), 1)
                        features['hnr_std'] = round(safe_std(hnr_values), 1)
                    else:
                        features.update({'hnr_mean': 0.0, 'hnr_std': 0.0})
                        
                except Exception as e:
                    self.logger.warning(f"HNR calculation failed: {e}")
                    features.update({'hnr_mean': 0.0, 'hnr_std': 0.0})
            else:
                # Insufficient voiced content for reliable voice quality measures
                features.update({
                    'jitter_local': 0.0,
                    'jitter_absolute': 0.0,
                    'shimmer_local': 0.0,
                    'shimmer_db': 0.0,
                    'hnr_mean': 0.0,
                    'hnr_std': 0.0
                })
            
            # === COMPOSITE VOCAL STABILITY SCORE ===
            # Domain-specific metric for app UX and clinical interpretation
            features['vocal_stability_score'] = round(
                self._calculate_vocal_stability_score(features), 1
            )
            
            self.logger.info(f"Vocal analysis completed: F0={features['f0_mean']}Hz, "
                           f"Jitter={features['jitter_local']}%, Shimmer={features['shimmer_local']}%, "
                           f"HNR={features['hnr_mean']}dB, Stability={features['vocal_stability_score']}")
            
            return FeatureSet(
                extractor=self.name,
                version=self.version,
                features=features,
                metadata=FeatureMetadata(
                    voiced_ratio=voiced_ratio,
                    sample_rate=sample_rate,
                    frame_count=len(pitch_values),
                    voiced_frame_count=len(voiced_frames)
                ),
                error=None,
                error_message=None
            )
            
        except ImportError as e:
            self.logger.error(f"Parselmouth not available: {e}")
            
            # Return zero values to clearly indicate failure
            features = {
                'f0_mean': 0.0,
                'f0_std': 0.0,
                'f0_confidence': 0.0,
                'jitter_local': 0.0,
                'jitter_absolute': 0.0,
                'shimmer_local': 0.0,
                'shimmer_db': 0.0,
                'hnr_mean': 0.0,
                'hnr_std': 0.0,
                'vocal_stability_score': 0.0
            }
            
            return FeatureSet(
                extractor=self.name,
                version=self.version,
                features=features,
                metadata=FeatureMetadata(
                    voiced_ratio=0.8,
                    sample_rate=sample_rate
                ),
                error='parselmouth_unavailable',
                error_message=str(e)
            )
            
        except Exception as e:
            self.logger.error(f"Vocal analysis extraction failed: {e}")
            
            # Return zero values for failed extraction (preserves data structure)
            features = {
                'f0_mean': 0.0,
                'f0_std': 0.0,
                'f0_confidence': 0.0,
                'jitter_local': 0.0,
                'jitter_absolute': 0.0,
                'shimmer_local': 0.0,
                'shimmer_db': 0.0,
                'hnr_mean': 0.0,
                'hnr_std': 0.0,
                'vocal_stability_score': 0.0
            }
            
            return FeatureSet(
                extractor=self.name,
                version=self.version,
                features=features,
                metadata=FeatureMetadata(
                    voiced_ratio=0.0,
                    sample_rate=sample_rate
                ),
                error='extraction_failed',
                error_message=str(e)
            )
            
        finally:
            # Ensure cleanup of temporary resources
            if temp_audio_file and os.path.exists(temp_audio_file.name):
                try:
                    os.unlink(temp_audio_file.name)
                    self.logger.debug("Temporary audio file cleaned up successfully")
                except Exception as cleanup_error:
                    self.logger.warning(f"Failed to cleanup temporary file: {cleanup_error}")
    
    def _calculate_vocal_stability_score(self, features: Dict[str, Any]) -> float:
        """
        Calculate composite vocal stability score using clinical thresholds.
        
        Domain Logic: Combines F0 confidence, jitter, shimmer, and HNR into a single
        score that users can understand and researchers can validate against 
        hormonal cycle phases.
        
        Clinical Thresholds:
        - Jitter: <1% excellent, <2% good, >5% pathological
        - Shimmer: <4% excellent, <6% good, >10% pathological  
        - HNR: >20dB excellent, >15dB good, <10dB poor
        
        Args:
            features: Dictionary of extracted vocal features
            
        Returns:
            Composite stability score (0-100, higher = more stable voice)
        """
        scores = []
        
        # F0 confidence component (40% weight - most important for cycle tracking)
        f0_confidence = features.get('f0_confidence', 0)
        scores.append(f0_confidence * 0.4)
        
        # Jitter component (20% weight)
        jitter = features.get('jitter_local', 0)
        if jitter > 0:
            if jitter < 1.0:
                jitter_score = 100
            elif jitter < 2.0:
                jitter_score = 80
            elif jitter < 5.0:
                jitter_score = max(0, 80 - ((jitter - 2.0) / 3.0) * 60)
            else:
                jitter_score = 20  # Pathological range
            scores.append(jitter_score * 0.2)
        
        # Shimmer component (20% weight)
        shimmer = features.get('shimmer_local', 0)
        if shimmer > 0:
            if shimmer < 4.0:
                shimmer_score = 100
            elif shimmer < 6.0:
                shimmer_score = 80
            elif shimmer < 10.0:
                shimmer_score = max(0, 80 - ((shimmer - 6.0) / 4.0) * 60)
            else:
                shimmer_score = 20  # Pathological range
            scores.append(shimmer_score * 0.2)
        
        # HNR component (20% weight)
        hnr = features.get('hnr_mean', 0)
        if hnr > 0:
            if hnr >= self.excellent_hnr_threshold:
                hnr_score = 100
            elif hnr >= 15.0:
                hnr_score = 80
            elif hnr >= 10.0:
                hnr_score = 60
            else:
                hnr_score = max(0, (hnr / 10.0) * 40)  # Scale from 0-40 for poor range
            scores.append(hnr_score * 0.2)
        
        # Return weighted average, or 0 if no valid components
        return sum(scores) if scores else 0.0
    
    def validate_audio_quality(self, audio: np.ndarray, sample_rate: int) -> bool:
        """
        Validate audio quality for comprehensive vocal analysis.
        
        Domain Requirements: Voice quality analysis requires longer, higher-quality
        audio than simple F0 extraction for reliable jitter/shimmer measurements.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            True if audio quality is sufficient for vocal biomarker extraction
        """
        # Call parent validation first
        if not super().validate_audio_quality(audio, sample_rate):
            return False
        
        # Voice quality analysis requires longer audio for reliable measurements
        duration = len(audio) / sample_rate
        if duration < 1.0:  # Clinical standard: minimum 1 second for jitter/shimmer
            self.logger.warning(f"Audio too short for voice quality analysis: {duration:.2f}s")
            return False
        
        return True
    
    def get_feature_names(self) -> List[str]:
        """
        Get list of vocal biomarker feature names.
        
        Domain Context: Feature names follow clinical voice analysis conventions
        and are suitable for research data export and app display.
        
        Returns:
            List of feature names in clinical terminology
        """
        return [
            # F0 biomarkers (primary for cycle tracking)
            'f0_mean',
            'f0_std', 
            'f0_confidence',
            
            # Jitter biomarkers (research-grade suite)
            'jitter_local',        # % - local period perturbation
            'jitter_absolute',     # µs - absolute period variation  
            'jitter_rap',          # % - relative average perturbation
            'jitter_ppq5',         # % - 5-point period perturbation quotient
            
            # Shimmer biomarkers (research-grade suite)
            'shimmer_local',       # % - local amplitude perturbation
            'shimmer_db',          # dB - amplitude perturbation in dB
            'shimmer_apq3',        # % - 3-point amplitude perturbation quotient
            'shimmer_apq5',        # % - 5-point amplitude perturbation quotient
            
            # HNR biomarkers
            'hnr_mean',           # dB - harmonics-to-noise ratio
            'hnr_std',            # dB - HNR variability
            
            # Composite metric (for app UX)
            'vocal_stability_score'  # 0-100 - overall voice quality
        ]