"""
Unified Structured Logging System for Sage Voice Analysis

This module provides a standardized logging interface that addresses critical debugging gaps:
- Consistent formatting across all components
- Correlation IDs for request tracing
- Rich context (recording_id, user_id, operation_id)
- Performance metrics and timing
- Debug flags and structured data
- Error context and stack traces

Usage:
    from utilities.unified_logger import get_voice_logger, LogContext
    
    logger = get_voice_logger("component_name")
    
    # With context
    with LogContext(recording_id="123", user_id="user456", operation="analyze"):
        logger.info("Starting analysis", extra={"f0_mean": 210.0})
        logger.performance("Local analysis", duration_ms=954)
        logger.error("Analysis failed", error=e, context={"attempt": 2})

Design principles:
- All logs include correlation context automatically
- Structured data for searchability
- Performance metrics built-in
- Debug levels can be toggled per component
- Error logs include full context and stack traces
"""

import logging
import json
import time
import traceback
from typing import Dict, Any, Optional, Union
from contextlib import contextmanager
from dataclasses import dataclass, asdict
from datetime import datetime
import threading
from enum import Enum

class LogLevel(Enum):
    DEBUG = "DEBUG"
    INFO = "INFO" 
    WARNING = "WARNING"
    ERROR = "ERROR"
    PERFORMANCE = "PERFORMANCE"

@dataclass
class LogContext:
    """Context information that gets included in all log messages"""
    recording_id: Optional[str] = None
    user_id: Optional[str] = None
    operation_id: Optional[str] = None
    operation: Optional[str] = None
    component: Optional[str] = None
    session_id: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary, excluding None values"""
        return {k: v for k, v in asdict(self).items() if v is not None}

# Thread-local storage for context
_context_storage = threading.local()

def set_log_context(context: LogContext) -> None:
    """Set the logging context for the current thread"""
    _context_storage.context = context

def get_log_context() -> LogContext:
    """Get the current logging context"""
    return getattr(_context_storage, 'context', LogContext())

def clear_log_context() -> None:
    """Clear the current logging context"""
    _context_storage.context = LogContext()

@contextmanager
def log_context(**kwargs):
    """Context manager for temporary logging context"""
    old_context = get_log_context()
    new_context = LogContext(**kwargs)
    set_log_context(new_context)
    try:
        yield new_context
    finally:
        set_log_context(old_context)

class StructuredFormatter(logging.Formatter):
    """Custom formatter that creates structured JSON logs with correlation context"""
    
    def format(self, record: logging.LogRecord) -> str:
        # Get current context
        context = get_log_context()
        
        # Build structured log entry
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "component": getattr(record, 'component', 'unknown'),
            "message": record.getMessage(),
            "logger": record.name,
        }
        
        # Add correlation context
        context_dict = context.to_dict()
        if context_dict:
            log_entry["context"] = context_dict
            
        # Add any extra structured data
        if hasattr(record, 'extra_data'):
            log_entry["data"] = record.extra_data
            
        # Add performance metrics if present
        if hasattr(record, 'duration_ms'):
            log_entry["performance"] = {
                "duration_ms": record.duration_ms,
                "operation": getattr(record, 'operation', 'unknown')
            }
            
        # Add error context for error logs
        if record.levelname == 'ERROR':
            if hasattr(record, 'error_context'):
                log_entry["error_context"] = record.error_context
            if record.exc_info:
                log_entry["stack_trace"] = traceback.format_exception(*record.exc_info)
                
        # Add location info for debugging
        log_entry["source"] = {
            "file": record.filename,
            "line": record.lineno,
            "function": record.funcName
        }
        
        return json.dumps(log_entry, indent=2 if getattr(record, 'pretty_print', False) else None)

class UnifiedLogger:
    """
    Unified logger that provides consistent, structured logging across all components
    """
    
    def __init__(self, component: str, debug_enabled: bool = False):
        self.component = component
        self.debug_enabled = debug_enabled
        self.logger = logging.getLogger(f"sage.{component}")
        
        # Configure logger if not already configured
        if not self.logger.handlers:
            handler = logging.StreamHandler()
            handler.setFormatter(StructuredFormatter())
            self.logger.addHandler(handler)
            self.logger.setLevel(logging.DEBUG if debug_enabled else logging.INFO)
            
    def _log(self, level: LogLevel, message: str, **kwargs) -> None:
        """Internal logging method"""
        log_level = getattr(logging, level.value)
        
        # Create log record with extra data
        extra = {
            'component': self.component,
        }
        
        # Add structured data if provided
        if 'extra' in kwargs:
            extra['extra_data'] = kwargs.pop('extra')
            
        # Add performance data if provided
        if 'duration_ms' in kwargs:
            extra['duration_ms'] = kwargs.pop('duration_ms')
            extra['operation'] = kwargs.get('operation', 'unknown')
            
        # Add error context if provided
        if 'error' in kwargs:
            error = kwargs.pop('error')
            extra['error_context'] = {
                'error_type': type(error).__name__,
                'error_message': str(error),
                'context': kwargs.get('context', {})
            }
            
        # Add any remaining kwargs as context
        if kwargs:
            existing_context = get_log_context()
            for key, value in kwargs.items():
                if hasattr(existing_context, key):
                    setattr(existing_context, key, value)
                    
        self.logger.log(log_level, message, extra=extra)
        
    def debug(self, message: str, **kwargs) -> None:
        """Log debug message (only if debug enabled)"""
        if self.debug_enabled:
            self._log(LogLevel.DEBUG, message, **kwargs)
            
    def info(self, message: str, **kwargs) -> None:
        """Log info message with structured data"""
        self._log(LogLevel.INFO, message, **kwargs)
        
    def warning(self, message: str, **kwargs) -> None:
        """Log warning message with context"""
        self._log(LogLevel.WARNING, message, **kwargs)
        
    def error(self, message: str, error: Optional[Exception] = None, **kwargs) -> None:
        """Log error message with full context and stack trace"""
        if error:
            kwargs['error'] = error
        self._log(LogLevel.ERROR, message, **kwargs)
        
    def performance(self, operation: str, duration_ms: float, **kwargs) -> None:
        """Log performance metrics"""
        self._log(LogLevel.PERFORMANCE, f"Performance: {operation}", 
                 duration_ms=duration_ms, operation=operation, **kwargs)
                 
    def start_operation(self, operation: str, **context) -> 'OperationLogger':
        """Start a timed operation with automatic performance logging"""
        return OperationLogger(self, operation, **context)

class OperationLogger:
    """Context manager for automatic operation timing and logging"""
    
    def __init__(self, logger: UnifiedLogger, operation: str, **context):
        self.logger = logger
        self.operation = operation
        self.context = context
        self.start_time = None
        
    def __enter__(self) -> 'OperationLogger':
        self.start_time = time.time()
        
        # Set up logging context
        with log_context(operation=self.operation, **self.context):
            self.logger.info(f"Starting {self.operation}", extra=self.context)
            
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration_ms = (time.time() - self.start_time) * 1000
        
        with log_context(operation=self.operation, **self.context):
            if exc_type is None:
                self.logger.performance(self.operation, duration_ms, extra=self.context)
                self.logger.info(f"Completed {self.operation}", 
                               extra={**self.context, "duration_ms": duration_ms})
            else:
                self.logger.error(f"Failed {self.operation}", error=exc_val, 
                                context={**self.context, "duration_ms": duration_ms})
                
    def log_progress(self, message: str, **extra) -> None:
        """Log progress during the operation"""
        with log_context(operation=self.operation, **self.context):
            self.logger.info(f"{self.operation}: {message}", extra=extra)

# Global configuration
_debug_components = set()

def enable_debug_logging(component: str = None) -> None:
    """Enable debug logging for a component (or all if None)"""
    if component:
        _debug_components.add(component)
    else:
        _debug_components.add("*")
        
def disable_debug_logging(component: str = None) -> None:
    """Disable debug logging for a component"""
    if component:
        _debug_components.discard(component)
    else:
        _debug_components.clear()

def is_debug_enabled(component: str) -> bool:
    """Check if debug logging is enabled for a component"""
    from .debug_config import is_debug_enabled as config_debug_enabled
    return config_debug_enabled(component) or "*" in _debug_components or component in _debug_components

# Factory function
def get_voice_logger(component: str) -> UnifiedLogger:
    """
    Get a unified logger for a component
    
    Args:
        component: Component name (e.g., "hybrid_analysis", "cloud_upload", "local_analyzer")
        
    Returns:
        UnifiedLogger instance configured for the component
    """
    debug_enabled = is_debug_enabled(component)
    return UnifiedLogger(component, debug_enabled)

# Convenience functions for common use cases
def log_voice_analysis_start(recording_id: str, user_id: str, logger: UnifiedLogger) -> None:
    """Standard log for voice analysis start"""
    with log_context(recording_id=recording_id, user_id=user_id, operation="voice_analysis"):
        logger.info("Voice analysis started", extra={
            "recording_id": recording_id,
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat()
        })

def log_voice_analysis_complete(recording_id: str, metrics: Dict[str, Any], 
                               duration_ms: float, logger: UnifiedLogger) -> None:
    """Standard log for voice analysis completion"""
    with log_context(recording_id=recording_id, operation="voice_analysis"):
        logger.performance("voice_analysis_complete", duration_ms, extra={
            "recording_id": recording_id,
            **metrics
        })

def log_upload_progress(recording_id: str, progress_percent: int, logger: UnifiedLogger) -> None:
    """Standard log for upload progress"""
    with log_context(recording_id=recording_id, operation="cloud_upload"):
        logger.info(f"Upload progress: {progress_percent}%", extra={
            "recording_id": recording_id,
            "progress_percent": progress_percent
        })

def log_firestore_operation(operation: str, collection: str, document_id: str, 
                          logger: UnifiedLogger, error: Optional[Exception] = None) -> None:
    """Standard log for Firestore operations"""
    with log_context(operation=f"firestore_{operation}"):
        if error:
            logger.error(f"Firestore {operation} failed", error=error, extra={
                "collection": collection,
                "document_id": document_id
            })
        else:
            logger.info(f"Firestore {operation} successful", extra={
                "collection": collection,
                "document_id": document_id
            })