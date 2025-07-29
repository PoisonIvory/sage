#!/bin/bash

# Verify Firestore Voice Analysis Writes
# This script helps you check if the cloud function successfully wrote voice analysis data

echo "🔍 Verifying Firestore Voice Analysis Writes"
echo "=============================================="

# Set your Firebase project (replace with your actual project ID if needed)
PROJECT_ID=$(firebase use --show-current 2>/dev/null || echo "your-project-id")
echo "Using Firebase project: $PROJECT_ID"
echo ""

# 1. List all recordings with insights (shows structure)
echo "📁 Checking recordings collection structure..."
firebase firestore:get recordings --limit 5

echo ""
echo "🔍 Looking for recent voice analysis insights..."

# 2. Query for recent insights with voice analysis data
echo "Querying recordings for insights with voice analysis fields..."
echo "(This will show documents that have vocal_analysis_f0_mean field)"

# Note: You'll need to replace 'RECORDING_ID' with an actual recording ID from your logs
echo ""
echo "💡 To check a specific recording, run:"
echo "firebase firestore:get recordings/YOUR_RECORDING_ID/insights"
echo ""

# 3. Check for documents created around the time mentioned (22:07:41 UTC)
echo "🕒 To find documents created around 22:07:41 UTC, run:"
echo "firebase firestore:query recordings --where 'created_at' '>=' '2024-XX-XX 22:00:00' --limit 10"
echo ""

# 4. Search for voice analysis insights specifically
echo "🎤 To verify voice analysis data exists, check for documents with these fields:"
echo "   - vocal_analysis_f0_mean"
echo "   - vocal_analysis_jitter_local" 
echo "   - vocal_analysis_shimmer_local"
echo "   - vocal_analysis_hnr_mean"
echo ""

echo "📝 Example commands to run:"
echo "1. List all recordings:"
echo "   firebase firestore:get recordings --limit 10"
echo ""
echo "2. Check specific recording (replace RECORDING_ID):"
echo "   firebase firestore:get recordings/RECORDING_ID"
echo ""
echo "3. List insights for a recording:"
echo "   firebase firestore:get recordings/RECORDING_ID/insights"
echo ""
echo "4. Get specific insight document:"
echo "   firebase firestore:get recordings/RECORDING_ID/insights/INSIGHT_DOC_ID"
echo ""

echo "🚀 If you see documents with vocal_analysis_* fields, the writes were successful!"