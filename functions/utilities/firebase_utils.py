"""
Firebase utilities for Sage voice analysis.

This module provides centralized Firebase and GCP client initialization
and Firestore operations for the voice analysis pipeline.

Reference: DATA_STANDARDS.md §3.2.1
"""

import os
import logging
from typing import Dict, Any, Optional
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import storage
import threading

from .constants import (
    FIRESTORE_COLLECTION,
    INSIGHT_TYPE,
    INSIGHT_SUBCOLLECTION,
    ANALYSIS_VERSION,
    STATUS_COMPLETED,
    STATUS_COMPLETED_WITH_WARNINGS
)

logger = logging.getLogger(__name__)

class FirebaseManager:
    """Manages Firebase and GCP client initialization and operations."""
    
    def __init__(self, project_id: str, cred_path: Optional[str] = None):
        """
        Initialize Firebase manager.
        
        Args:
            project_id: Google Cloud project ID
            cred_path: Path to service account credentials file (optional)
        """
        self.project_id = project_id
        self.cred_path = cred_path
        self._firestore_client = None
        self._storage_client = None
        self._lock = threading.Lock()
        
    def initialize(self) -> None:
        """Initialize Firebase app and clients."""
        if not firebase_admin._apps:
            if self.cred_path and os.path.exists(self.cred_path):
                cred = credentials.Certificate(self.cred_path)
                logger.info(f"Using service account credentials from {self.cred_path}")
            else:
                cred = credentials.ApplicationDefault()
                logger.info("Using default application credentials")
            
            firebase_admin.initialize_app(cred, {'projectId': self.project_id})
            logger.info(f"Firebase initialized for project: {self.project_id}")
    
    @property
    def firestore_client(self) -> firestore.Client:
        """Get Firestore client instance (thread-safe singleton)."""
        if self._firestore_client is None:
            with self._lock:
                if self._firestore_client is None:
                    self._firestore_client = firestore.client()
        return self._firestore_client
    
    @property
    def storage_client(self) -> storage.Client:
        """Get Cloud Storage client instance (thread-safe singleton)."""
        if self._storage_client is None:
            with self._lock:
                if self._storage_client is None:
                    self._storage_client = storage.Client()
        return self._storage_client


class FirestoreOperations:
    """Handles Firestore operations for voice analysis results."""
    
    def __init__(self, firebase_manager: FirebaseManager):
        """
        Initialize Firestore operations.
        
        Args:
            firebase_manager: Initialized Firebase manager
        """
        self.firebase_manager = firebase_manager
        self.logger = logging.getLogger(__name__)
    
    def store_voice_analysis_results(
        self, 
        recording_id: str, 
        features: Dict[str, Any], 
        processing_metadata: Dict[str, Any],
        tool_versions: Dict[str, str],
        analysis_version: str = ANALYSIS_VERSION,
        user_id: Optional[str] = None
    ) -> str:
        """
        Store voice analysis results in Firestore.
        
        Args:
            recording_id: Unique identifier for the recording
            features: Dictionary of extracted features (already namespaced)
            processing_metadata: Metadata about the processing
            tool_versions: Dictionary of tool versions used
            analysis_version: Version string for analysis results
            user_id: User ID for storing in users collection (optional)
            
        Returns:
            Document ID of the stored insight
            
        Raises:
            Exception: If storage operation fails
        """
        try:
            # Validate recording_id and features early
            if not recording_id or not isinstance(features, dict):
                raise ValueError("Invalid recording ID or features dictionary")
            
            # Check for error status from any extractor
            has_errors = any(
                key.endswith('_error_type') and features[key] 
                for key in features.keys()
            )
            
            insight_data = {
                'insight_type': INSIGHT_TYPE,
                'status': STATUS_COMPLETED if not has_errors else STATUS_COMPLETED_WITH_WARNINGS,
                'analysis_version': analysis_version,
                'processing_metadata': processing_metadata,
                'tool_versions': tool_versions,
                'created_at': firestore.SERVER_TIMESTAMP
            }
            
            # Add all features directly (they're already namespaced)
            insight_data.update(features)
            
            # Write to canonical path: recordings/{recording_id}/insights/
            insights_ref = self.firebase_manager.firestore_client.collection(
                FIRESTORE_COLLECTION
            ).document(recording_id).collection(INSIGHT_SUBCOLLECTION)
            
            # Use add() method which returns a tuple (timestamp, DocumentReference)
            timestamp, doc_ref = insights_ref.add(insight_data)
            
            self.logger.info(
                f"Voice analysis insights stored successfully for recording {recording_id} "
                f"at document {doc_ref.id}"
            )
            
            # Also write to users collection if user_id is provided
            if user_id:
                try:
                    # Add timestamp for sorting in users collection
                    user_insight_data = insight_data.copy()
                    user_insight_data['timestamp'] = firestore.SERVER_TIMESTAMP
                    user_insight_data['recording_id'] = recording_id
                    
                    # Write to users/{user_id}/voice_analyses/{recording_id}
                    user_doc_ref = self.firebase_manager.firestore_client.collection(
                        'users'
                    ).document(user_id).collection('voice_analyses').document(recording_id)
                    
                    user_doc_ref.set(user_insight_data)
                    
                    self.logger.info(
                        f"Voice analysis results also stored in users collection: "
                        f"users/{user_id}/voice_analyses/{recording_id}"
                    )
                except Exception as e:
                    self.logger.warning(
                        f"Failed to store results in users collection for user {user_id}: {e}"
                    )
                    # Don't fail the entire operation if users collection write fails
            
            return doc_ref.id
            
        except Exception as e:
            self.logger.exception(
                f"Failed to store voice analysis insights for recording {recording_id}"
            )
            raise


class StorageOperations:
    """Handles Cloud Storage operations for audio files."""
    
    def __init__(self, firebase_manager: FirebaseManager):
        """
        Initialize Storage operations.
        
        Args:
            firebase_manager: Initialized Firebase manager
        """
        self.firebase_manager = firebase_manager
        self.logger = logging.getLogger(__name__)
    
    def download_audio_file(self, bucket_name: str, file_name: str) -> str:
        """
        Download audio file from Firebase Storage to temporary local file.
        
        Args:
            bucket_name: Name of the storage bucket
            file_name: Path to the file in the bucket
            
        Returns:
            Path to the temporary local file
            
        Raises:
            Exception: If download fails
        """
        try:
            bucket = self.firebase_manager.storage_client.bucket(bucket_name)
            blob = bucket.blob(file_name)
            
            import tempfile
            with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
                blob.download_to_filename(temp_file.name)
                temp_file_path = temp_file.name
            
            self.logger.info(f"Downloaded audio file: {file_name}")
            return temp_file_path
            
        except Exception as e:
            self.logger.exception("Audio download failed")
            raise 