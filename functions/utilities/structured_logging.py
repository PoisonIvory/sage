"""
Structured logging utilities for Sage voice analysis.

This module provides structured logging capabilities for better integration
with cloud logging systems and consistent logging across the application.

Reference: DATA_STANDARDS.md §3.2.1
"""

import logging
import json
from typing import Dict, Any, Optional
from datetime import datetime, timezone


class StructuredLogger:
    """Structured logger for cloud logging integration."""
    
    def __init__(self, name: str, level: int = logging.INFO):
        """
        Initialize structured logger.
        
        Args:
            name: Logger name
            level: Logging level
        """
        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        self.name = name
        
        # Ensure logs go to stdout as clean JSON for cloud environments
        if not self.logger.handlers:
            handler = logging.StreamHandler()
            handler.setFormatter(logging.Formatter('%(message)s'))  # Ensure pure JSON
            self.logger.addHandler(handler)
    
    def _format_log(self, level: str, message: str, trace_id: Optional[str] = None, **kwargs) -> str:
        """
        Format log message as structured JSON.
        
        Args:
            level: Log level
            message: Log message
            trace_id: Optional correlation/trace ID for distributed tracing
            **kwargs: Additional structured fields
            
        Returns:
            JSON formatted log string
        """
        log_data = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'severity': level.upper(),
            'logger': self.name,
            'message': message,
            **kwargs
        }
        
        if trace_id:
            log_data['trace_id'] = trace_id
            
        return json.dumps(log_data)
    
    def info(self, message: str, **kwargs) -> None:
        """Log info message with structured data."""
        formatted_message = self._format_log('INFO', message, **kwargs)
        self.logger.info(formatted_message)
    
    def warning(self, message: str, **kwargs) -> None:
        """Log warning message with structured data."""
        formatted_message = self._format_log('WARNING', message, **kwargs)
        self.logger.warning(formatted_message)
    
    def error(self, message: str, exc: Optional[Exception] = None, **kwargs) -> None:
        """Log error message with structured data and optional exception info."""
        if exc:
            kwargs['exception'] = str(exc)
        formatted_message = self._format_log('ERROR', message, **kwargs)
        self.logger.error(formatted_message, exc_info=bool(exc))
    
    def debug(self, message: str, **kwargs) -> None:
        """Log debug message with structured data."""
        formatted_message = self._format_log('DEBUG', message, **kwargs)
        self.logger.debug(formatted_message)
    
    def critical(self, message: str, exc: Optional[Exception] = None, **kwargs) -> None:
        """Log critical message with structured data and optional exception info."""
        if exc:
            kwargs['exception'] = str(exc)
        formatted_message = self._format_log('CRITICAL', message, **kwargs)
        self.logger.critical(formatted_message, exc_info=bool(exc))


class AudioProcessingLogger(StructuredLogger):
    """Specialized logger for audio processing operations."""
    
    def log_audio_processing_start(self, file_name: str, bucket_name: str) -> None:
        """Log start of audio processing."""
        self.info(
            "Audio processing started",
            operation="audio_processing_start",
            file_name=file_name,
            bucket_name=bucket_name
        )
    
    def log_audio_processing_success(self, file_name: str, recording_id: str, doc_id: str) -> None:
        """Log successful audio processing."""
        self.info(
            "Audio processing completed successfully",
            operation="audio_processing_success",
            file_name=file_name,
            recording_id=recording_id,
            document_id=doc_id
        )
    
    def log_audio_processing_error(self, file_name: str, error: str, exc: Optional[Exception] = None) -> None:
        """Log audio processing error."""
        self.error(
            "Audio processing failed",
            exc=exc,
            operation="audio_processing_error",
            file_name=file_name,
            error=error
        )
    
    def log_quality_gate_failure(self, file_name: str, reason: str, **metrics) -> None:
        """Log quality gate failure."""
        self.warning(
            "Audio failed quality gate",
            operation="quality_gate_failure",
            file_name=file_name,
            reason=reason,
            **metrics
        )
    
    def log_feature_extraction(self, extractor_name: str, features: Dict[str, Any], metadata: Dict[str, Any]) -> None:
        """Log feature extraction results."""
        self.info(
            f"{extractor_name} extraction completed",
            operation="feature_extraction",
            extractor=extractor_name,
            features=features,
            metadata=metadata
        )


class FirestoreLogger(StructuredLogger):
    """Specialized logger for Firestore operations."""
    
    def log_firestore_store_success(self, recording_id: str, doc_id: str) -> None:
        """Log successful Firestore storage."""
        self.info(
            "Voice analysis insights stored successfully",
            operation="firestore_store_success",
            recording_id=recording_id,
            document_id=doc_id
        )
    
    def log_firestore_store_error(self, recording_id: str, error: str, exc: Optional[Exception] = None) -> None:
        """Log Firestore storage error."""
        self.error(
            "Failed to store voice analysis insights",
            exc=exc,
            operation="firestore_store_error",
            recording_id=recording_id,
            error=error
        )


def get_structured_logger(name: str) -> StructuredLogger:
    """
    Get a structured logger instance.
    
    Args:
        name: Logger name
        
    Returns:
        StructuredLogger instance
    """
    return StructuredLogger(name)


def get_audio_processing_logger() -> AudioProcessingLogger:
    """
    Get an audio processing logger instance.
    
    Returns:
        AudioProcessingLogger instance
    """
    return AudioProcessingLogger("audio_processing")


def get_firestore_logger() -> FirestoreLogger:
    """
    Get a Firestore logger instance.
    
    Returns:
        FirestoreLogger instance
    """
    return FirestoreLogger("firestore") 