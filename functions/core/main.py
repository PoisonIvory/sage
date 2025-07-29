"""
Main Cloud Function entry point for Sage voice analysis.

This module provides the cloud function handler that processes audio files
uploaded to Firebase Storage and extracts voice analysis features.

Reference: DATA_STANDARDS.md §3.2.1
"""

import functions_framework
import logging
from typing import Optional
from services.audio_processing_service import AudioProcessingService
from utilities.unified_logger import get_voice_logger, log_context
from utilities.tool_versions import ToolVersions
from utilities.constants import WAV_EXTENSION, SAGE_AUDIO_FILES_PREFIX

# Configure unified logging
logger = get_voice_logger("cloud_function_main")

# Initialize audio processing service with configurable analysis version
audio_service = AudioProcessingService(analysis_version="1.0")


@functions_framework.cloud_event
def process_audio_file(cloud_event) -> None:
    """
    Main Cloud Function entry point for voice analysis processing.
    
    Args:
        cloud_event: Cloud event containing file upload information
        
    Returns:
        None
        
    Raises:
        Exception: If processing fails
    """
    # Get file info from the cloud event
    event_data = cloud_event.data
    file_name = event_data.get('name', '')
    bucket_name = event_data.get('bucket', '')
    
    # Extract recording ID from file path for correlation
    recording_id = None
    user_id = None
    try:
        file_info = audio_service.parse_file_path(file_name)
        recording_id = file_info.get('recording_id')
        user_id = file_info.get('user_id')
    except Exception:
        pass  # Continue processing even if path parsing fails
    
    logger.info("Cloud function triggered", extra={
        "file_name": file_name,
        "bucket_name": bucket_name,
        "recording_id": recording_id,
        "user_id": user_id,
        "file_size": event_data.get('size', 0),
        "content_type": event_data.get('contentType', 'unknown')
    })
    
    # Validate file type
    if not file_name.endswith(WAV_EXTENSION):
        logger.info("Skipping non-wav file", extra={
            "file_name": file_name,
            "recording_id": recording_id,
            "file_extension": file_name.split('.')[-1] if '.' in file_name else 'none',
            "expected_extension": WAV_EXTENSION
        })
        return
    
    if not file_name.startswith(SAGE_AUDIO_FILES_PREFIX):
        logger.warning("Unexpected file path structure", extra={
            "file_name": file_name,
            "recording_id": recording_id,
            "expected_prefix": SAGE_AUDIO_FILES_PREFIX,
            "actual_prefix": file_name.split('/')[0] if '/' in file_name else file_name
        })
        return
    
    try:
        logger.info("Starting audio processing pipeline", extra={
            "file_name": file_name,
            "bucket_name": bucket_name,
            "recording_id": recording_id
        })
        
        # Process audio file using the service
        doc_id = audio_service.process_audio_file(bucket_name, file_name)
        
        if doc_id:
            logger.info("Audio processing completed successfully", extra={
                "file_name": file_name,
                "recording_id": recording_id,
                "document_id": doc_id,
                "firestore_write": "success"
            })
        else:
            logger.warning("Audio processing returned no document ID", extra={
                "file_name": file_name,
                "recording_id": recording_id,
                "service_response": "no_doc_id"
            })
            
    except Exception as e:
        logger.error("Cloud function processing failed", error=e, extra={
            "file_name": file_name,
            "bucket_name": bucket_name,
            "error_type": type(e).__name__,
            "recording_id": recording_id
        })
        raise 