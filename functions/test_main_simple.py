#!/usr/bin/env python3
"""
Simple test for main.py function
"""

import sys
import os

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_main_import():
    """Test that main.py can be imported without errors"""
    try:
        import main
        print("✅ main.py imported successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to import main.py: {e}")
        return False

def test_config_import():
    """Test that config can be imported"""
    try:
        from config import get_config
        config = get_config()
        print("✅ config imported successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to import config: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Running simple tests...")
    
    success = True
    success &= test_config_import()
    success &= test_main_import()
    
    if success:
        print("✅ All simple tests passed")
        sys.exit(0)
    else:
        print("❌ Some tests failed")
        sys.exit(1) 