#!/bin/bash

echo "🚀 Simple Firestore Voice Analysis Check"
echo "========================================"

# Check if we can access the project
echo "📋 Current Firebase project:"
firebase use

echo ""
echo "🔍 To manually verify voice analysis data in Firestore:"
echo ""

echo "1. 🌐 Open the Firebase Console:"
echo "   https://console.firebase.google.com/project/sage-2d21f/firestore"
echo ""

echo "2. 📁 Navigate to the 'recordings' collection"
echo ""

echo "3. 🔎 Look for documents with subcollections called 'insights'"
echo ""

echo "4. 💾 In the insights documents, look for fields starting with 'vocal_analysis_':"
echo "   ✅ vocal_analysis_f0_mean (fundamental frequency in Hz)"
echo "   ✅ vocal_analysis_jitter_local (jitter percentage)"
echo "   ✅ vocal_analysis_shimmer_local (shimmer percentage)"
echo "   ✅ vocal_analysis_hnr_mean (harmonics-to-noise ratio in dB)"
echo "   ✅ vocal_analysis_vocal_stability_score (0-100 composite score)"
echo ""

echo "5. 📊 Additional fields to verify:"
echo "   ✅ insight_type: 'voice_analysis'"
echo "   ✅ status: 'completed' or 'completed_with_warnings'"
echo "   ✅ analysis_version: '1.0'"
echo "   ✅ created_at: timestamp (should be around 22:07:41 UTC)"
echo ""

echo "🎯 SUCCESS INDICATORS:"
echo "   - Documents exist in recordings/{recording_id}/insights/"
echo "   - Documents contain vocal_analysis_* fields with numeric values"
echo "   - F0 mean is typically 80-300 Hz for normal voices"
echo "   - Jitter/shimmer values are typically < 5%"
echo "   - HNR values are typically > 10 dB"
echo ""

# Try to check Firebase auth status
echo "🔐 Checking Firebase authentication..."
firebase auth:list --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Firebase CLI is properly configured"
else
    echo "❌ Firebase CLI may need authentication"
    echo "💡 Try running: firebase login"
fi

echo ""
echo "📱 Alternative: Check via iOS app logs"
echo "   - Look for successful data fetches in the dashboard"
echo "   - F0 data should be displayed in the voice dashboard"
echo "   - Check network logs for Firestore read operations"

echo ""
echo "🔧 If no data is found, check cloud function logs:"
echo "   firebase functions:log --only process_audio_file"