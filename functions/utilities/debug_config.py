"""
Debug Configuration for Sage Voice Analysis

This module provides centralized debug flag management to enable/disable
detailed logging and debugging features across the entire system.

Usage:
    # Enable debug logging for specific components
    from utilities.debug_config import enable_debug, is_debug_enabled
    
    enable_debug("cloud_function_main")
    enable_debug("feature_extraction")
    
    # Check if debug is enabled
    if is_debug_enabled("cloud_function_main"):
        logger.debug("Detailed debug information")
        
    # Enable debug for all components
    enable_debug("*")
    
Environment Variables:
    SAGE_DEBUG_COMPONENTS: Comma-separated list of components to debug
        Example: "cloud_function_main,feature_extraction,audio_processing"
        Use "*" to enable debug for all components
        
    SAGE_DEBUG_PERFORMANCE: Enable performance timing logs (true/false)
    SAGE_DEBUG_FIRESTORE: Enable detailed Firestore operation logs (true/false)
    SAGE_DEBUG_AUDIO: Enable audio processing debug logs (true/false)
"""

import os
from typing import Set, Dict, Any
from threading import Lock

# Global debug state
_debug_components: Set[str] = set()
_debug_flags: Dict[str, bool] = {}
_debug_lock = Lock()

def _load_debug_config():
    """Load debug configuration from environment variables"""
    with _debug_lock:
        # Load debug components from environment
        debug_env = os.environ.get('SAGE_DEBUG_COMPONENTS', '')
        if debug_env:
            components = [c.strip() for c in debug_env.split(',')]
            _debug_components.update(components)
            
        # Load specific debug flags
        _debug_flags['performance'] = os.environ.get('SAGE_DEBUG_PERFORMANCE', 'false').lower() == 'true'
        _debug_flags['firestore'] = os.environ.get('SAGE_DEBUG_FIRESTORE', 'false').lower() == 'true'
        _debug_flags['audio'] = os.environ.get('SAGE_DEBUG_AUDIO', 'false').lower() == 'true'
        _debug_flags['parselmouth'] = os.environ.get('SAGE_DEBUG_PARSELMOUTH', 'false').lower() == 'true'

# Load configuration on import
_load_debug_config()

def enable_debug(component: str = "*") -> None:
    """
    Enable debug logging for a component
    
    Args:
        component: Component name or "*" for all components
    """
    with _debug_lock:
        _debug_components.add(component)

def disable_debug(component: str = None) -> None:
    """
    Disable debug logging for a component
    
    Args:
        component: Component name or None to disable all
    """
    with _debug_lock:
        if component is None:
            _debug_components.clear()
        else:
            _debug_components.discard(component)

def is_debug_enabled(component: str) -> bool:
    """
    Check if debug logging is enabled for a component
    
    Args:
        component: Component name to check
        
    Returns:
        True if debug is enabled for this component
    """
    with _debug_lock:
        return "*" in _debug_components or component in _debug_components

def is_flag_enabled(flag: str) -> bool:
    """
    Check if a specific debug flag is enabled
    
    Args:
        flag: Flag name (performance, firestore, audio, parselmouth)
        
    Returns:
        True if the flag is enabled
    """
    with _debug_lock:
        return _debug_flags.get(flag, False)

def get_debug_info() -> Dict[str, Any]:
    """
    Get current debug configuration
    
    Returns:
        Dictionary with debug configuration info
    """
    with _debug_lock:
        return {
            "debug_components": list(_debug_components),
            "debug_flags": _debug_flags.copy(),
            "environment_vars": {
                "SAGE_DEBUG_COMPONENTS": os.environ.get('SAGE_DEBUG_COMPONENTS'),
                "SAGE_DEBUG_PERFORMANCE": os.environ.get('SAGE_DEBUG_PERFORMANCE'),
                "SAGE_DEBUG_FIRESTORE": os.environ.get('SAGE_DEBUG_FIRESTORE'),
                "SAGE_DEBUG_AUDIO": os.environ.get('SAGE_DEBUG_AUDIO'),
                "SAGE_DEBUG_PARSELMOUTH": os.environ.get('SAGE_DEBUG_PARSELMOUTH'),
            }
        }

def set_debug_flag(flag: str, enabled: bool) -> None:
    """
    Set a specific debug flag
    
    Args:
        flag: Flag name
        enabled: Whether to enable the flag
    """
    with _debug_lock:
        _debug_flags[flag] = enabled

# Common debug configurations
def enable_all_debug():
    """Enable debug logging for all components and flags"""
    enable_debug("*")
    set_debug_flag("performance", True)
    set_debug_flag("firestore", True)
    set_debug_flag("audio", True)
    set_debug_flag("parselmouth", True)

def enable_cloud_function_debug():
    """Enable debug logging specifically for cloud function components"""
    enable_debug("cloud_function_main")
    enable_debug("audio_processing_service")
    enable_debug("feature_extraction")
    enable_debug("firebase_utils")
    set_debug_flag("performance", True)
    set_debug_flag("firestore", True)

def enable_ios_debug():
    """Enable debug logging specifically for iOS components"""
    enable_debug("HybridAnalysis")
    enable_debug("CloudAnalysis")
    enable_debug("ResultsListener")
    set_debug_flag("performance", True)