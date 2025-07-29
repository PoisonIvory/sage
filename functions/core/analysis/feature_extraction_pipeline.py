from services.voice_analysis_service import VoiceAnalysisService
from feature_extractors.vocal_analysis_extractor import VocalAnalysisExtractor
# Future extractors for different task types:
# from feature_extractors.formant_extractor import FormantExtractor  # For reading tasks
# from feature_extractors.prosody_extractor import ProsodyExtractor   # For conversation tasks

class FeatureExtractionPipeline:
    """
    Domain-driven feature extraction pipeline for vocal biomarker analysis.
    
    Architecture: Task-based extractor selection supporting different
    recording types (sustained vowel, reading, conversation) for comprehensive
    menstrual cycle voice tracking research.
    """
    
    def __init__(self, config=None, task_type='sustained_vowel'):
        """
        Initialize pipeline with task-specific extractors.
        
        Args:
            config: Configuration dictionary
            task_type: Type of recording task ('sustained_vowel', 'reading', 'conversation')
        """
        self.task_type = task_type
        self.config = config or {}
        
        # Task-based extractor selection (Domain-Driven Design)
        if task_type == 'sustained_vowel':
            # Primary task: F0, jitter, shimmer, HNR analysis
            extractors = [VocalAnalysisExtractor(self.config)]
        elif task_type == 'reading':
            # Future: Add formant and prosody analysis for reading tasks
            extractors = [VocalAnalysisExtractor(self.config)]
            # extractors.append(FormantExtractor(self.config))
        elif task_type == 'conversation':
            # Future: Add prosody and speaking rate analysis
            extractors = [VocalAnalysisExtractor(self.config)]
            # extractors.append(ProsodyExtractor(self.config))
        else:
            # Default to vocal analysis for unknown task types
            extractors = [VocalAnalysisExtractor(self.config)]
        
        self.service = VoiceAnalysisService(extractors)

    def run(self, audio, sample_rate):
        return self.service.analyze(audio, sample_rate)
    
    def run_for_firestore(self, audio, sample_rate):
        """
        Run feature extraction and format results for Firestore storage.
        
        Args:
            audio: Audio data as numpy array
            sample_rate: Sample rate in Hz
            
        Returns:
            Dictionary ready for Firestore storage with namespaced features
        """
        return self.service.analyze_for_firestore(audio, sample_rate) 