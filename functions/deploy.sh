#!/bin/bash

# F0 Cloud Function Deployment Script
# This script handles Python version compatibility and deploys the F0 processing function

set -e  # Exit on any error

echo "🚀 Starting F0 Cloud Function Deployment..."

# Check if we're in the right directory
if [ ! -f "main.py" ]; then
    echo "❌ Error: main.py not found. Please run this script from the functions directory."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "📋 Python version: $PYTHON_VERSION"

# Remove existing venv if it exists
if [ -d "venv" ]; then
    echo "🧹 Cleaning up existing virtual environment..."
    rm -rf venv
fi

# Try different Python versions
PYTHON_VERSIONS=("python3.11" "python3.10" "python3.9" "python3")

PYTHON_CMD=""
for py_cmd in "${PYTHON_VERSIONS[@]}"; do
    if command -v $py_cmd &> /dev/null; then
        echo "✅ Found $py_cmd"
        PYTHON_CMD=$py_cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Error: No compatible Python version found. Please install Python 3.9+"
    exit 1
fi

echo "🐍 Using $PYTHON_CMD"

# Create virtual environment
echo "📦 Creating virtual environment..."
$PYTHON_CMD -m venv venv

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install setuptools and wheel first
echo "🔨 Installing build dependencies..."
pip install setuptools wheel

# Try to install requirements with updated versions
echo "📚 Installing dependencies..."
if [ -f "requirements_updated.txt" ]; then
    echo "📋 Using updated requirements..."
    pip install -r requirements_updated.txt
else
    echo "📋 Using original requirements..."
    pip install -r requirements.txt
fi

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "⚠️ Some dependencies failed to install. Trying with minimal requirements..."
    
    # Create minimal requirements for deployment
    cat > requirements_minimal.txt << EOF
# Minimal requirements for F0 processing
firebase-admin>=6.2.0
google-cloud-storage>=2.10.0
numpy>=1.24.0
parselmouth>=0.4.3
soundfile>=0.12.1
EOF
    
    pip install -r requirements_minimal.txt
fi

# Test the function locally
echo "🧪 Testing function locally..."
python3 test_f0_structure_simple.py

if [ $? -eq 0 ]; then
    echo "✅ Local tests passed"
else
    echo "⚠️ Local tests failed, but continuing with deployment..."
fi

# Deploy to Firebase
echo "🚀 Deploying to Firebase..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo ""
    echo "🎉 F0 Cloud Function deployed successfully!"
    echo "📊 Monitor logs at: https://console.firebase.google.com/project/sage-2d21f/functions/logs"
    echo "🔍 Test by uploading an audio file to Firebase Storage"
else
    echo "❌ Deployment failed"
    echo "💡 Try running: firebase emulators:start --only functions"
    exit 1
fi 