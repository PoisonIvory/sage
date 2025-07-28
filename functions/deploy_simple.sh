#!/bin/bash

# Simple deployment script for F0 Cloud Function

echo "🚀 Deploying F0 Cloud Function..."

# Go to functions directory
cd functions

# Remove existing venv
rm -rf venv

# Create new venv with Python 3.13
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Test locally
python3 test_main_simple.py

# Deploy from parent directory
cd ..
firebase deploy --only functions

echo "✅ Deployment complete!" 