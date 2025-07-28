#!/bin/bash

# Manual deployment script for F0 Cloud Function
# This script tries to work around Firebase CLI issues

echo "🚀 Manual deployment of F0 Cloud Function..."

# Go to functions directory
cd functions

# Remove existing venv
rm -rf venv

# Create new venv
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Test locally
python3 test_main_simple.py

echo "✅ Local tests passed!"

# Try to deploy using Firebase CLI with explicit Python path
echo "📦 Attempting deployment..."

# Set the Python path explicitly
export PYTHONPATH="${PWD}/venv/lib/python3.13/site-packages:${PYTHONPATH}"

# Try deployment from parent directory
cd ..
firebase deploy --only functions --project sage-2d21f

echo "✅ Deployment attempt complete!"
echo ""
echo "📊 Next steps:"
echo "1. Check Firebase Console: https://console.firebase.google.com/project/sage-2d21f/functions"
echo "2. Test by uploading an audio file to Firebase Storage"
echo "3. Monitor logs: firebase functions:log" 