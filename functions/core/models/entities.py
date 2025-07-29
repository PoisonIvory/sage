from dataclasses import dataclass, field
from typing import Dict, Optional, Any

@dataclass
class FeatureMetadata:
    duration_seconds: float = 0.0
    voiced_ratio: float = 0.0
    sample_rate: int = 0
    frame_count: Optional[int] = None
    voiced_frame_count: Optional[int] = None
    # Add more fields as needed for other extractors

@dataclass
class FeatureSet:
    extractor: str
    version: str
    features: Dict[str, float]
    metadata: Optional[FeatureMetadata] = None
    error: Optional[str] = None
    error_message: Optional[str] = None 