#!/usr/bin/env python3
"""
Script to verify voice analysis results in Firestore.
This script checks if the cloud function successfully wrote voice analysis data.
"""

import os
import sys
from google.cloud import firestore
from datetime import datetime, timezone
import json

def init_firestore():
    """Initialize Firestore client."""
    project_id = "sage-2d21f"
    return firestore.Client(project=project_id)

def check_recordings_collection(db):
    """Check the recordings collection for recent documents."""
    print("🔍 Checking recordings collection...")
    
    try:
        recordings_ref = db.collection('recordings')
        
        # Get all recordings (limit to avoid overwhelming output)
        recordings = list(recordings_ref.limit(10).stream())
        
        if not recordings:
            print("❌ No recordings found in the collection")
            return []
        
        print(f"✅ Found {len(recordings)} recording documents")
        
        recording_ids = []
        for doc in recordings:
            recording_ids.append(doc.id)
            print(f"   📄 Recording ID: {doc.id}")
            
            # Check if this recording has insights
            insights_ref = doc.reference.collection('insights')
            insights = list(insights_ref.limit(5).stream())
            
            if insights:
                print(f"      💡 Has {len(insights)} insight documents")
                for insight in insights:
                    insight_data = insight.to_dict()
                    print(f"         🎤 Insight ID: {insight.id}")
                    print(f"         📊 Type: {insight_data.get('insight_type', 'unknown')}")
                    print(f"         ✅ Status: {insight_data.get('status', 'unknown')}")
                    
                    # Check for voice analysis fields
                    voice_fields = [k for k in insight_data.keys() if k.startswith('vocal_analysis_')]
                    if voice_fields:
                        print(f"         🎵 Voice analysis fields found: {len(voice_fields)}")
                        # Show key metrics
                        if 'vocal_analysis_f0_mean' in insight_data:
                            print(f"            F0 Mean: {insight_data['vocal_analysis_f0_mean']} Hz")
                        if 'vocal_analysis_jitter_local' in insight_data:
                            print(f"            Jitter: {insight_data['vocal_analysis_jitter_local']}%")
                        if 'vocal_analysis_shimmer_local' in insight_data:
                            print(f"            Shimmer: {insight_data['vocal_analysis_shimmer_local']}%")
                        if 'vocal_analysis_hnr_mean' in insight_data:
                            print(f"            HNR: {insight_data['vocal_analysis_hnr_mean']} dB")
                        if 'vocal_analysis_vocal_stability_score' in insight_data:
                            print(f"            Stability Score: {insight_data['vocal_analysis_vocal_stability_score']}")
                    else:
                        print("         ❌ No voice analysis fields found")
                    
                    print()
            else:
                print("      ❌ No insights found for this recording")
            print()
        
        return recording_ids
        
    except Exception as e:
        print(f"❌ Error checking recordings: {e}")
        return []

def check_recent_insights(db, hours_back=24):
    """Check for insights created in the last N hours."""
    print(f"🕒 Checking for insights created in the last {hours_back} hours...")
    
    try:
        from datetime import timedelta
        cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours_back)
        
        # Query across all recordings for recent insights
        # Note: This is a collection group query
        insights_ref = db.collection_group('insights')
        recent_insights = insights_ref.where('created_at', '>=', cutoff_time).limit(20).stream()
        
        recent_count = 0
        voice_analysis_count = 0
        
        for insight in recent_insights:
            recent_count += 1
            insight_data = insight.to_dict()
            
            print(f"📄 Recent insight: {insight.reference.path}")
            print(f"   Type: {insight_data.get('insight_type', 'unknown')}")
            print(f"   Status: {insight_data.get('status', 'unknown')}")
            print(f"   Created: {insight_data.get('created_at')}")
            
            # Check for voice analysis data
            voice_fields = [k for k in insight_data.keys() if k.startswith('vocal_analysis_')]
            if voice_fields:
                voice_analysis_count += 1
                print(f"   ✅ Contains voice analysis data ({len(voice_fields)} fields)")
                
                # Show sample data
                if 'vocal_analysis_f0_mean' in insight_data:
                    f0_mean = insight_data['vocal_analysis_f0_mean']
                    jitter = insight_data.get('vocal_analysis_jitter_local', 'N/A')
                    shimmer = insight_data.get('vocal_analysis_shimmer_local', 'N/A')
                    hnr = insight_data.get('vocal_analysis_hnr_mean', 'N/A')
                    print(f"   🎵 F0: {f0_mean}Hz, Jitter: {jitter}%, Shimmer: {shimmer}%, HNR: {hnr}dB")
            else:
                print(f"   ❌ No voice analysis data")
            print()
        
        print(f"📊 Summary: {recent_count} recent insights, {voice_analysis_count} with voice analysis data")
        return voice_analysis_count > 0
        
    except Exception as e:
        print(f"❌ Error checking recent insights: {e}")
        return False

def main():
    """Main function to check Firestore data."""
    print("🚀 Sage Voice Analysis Firestore Verification")
    print("=" * 50)
    
    try:
        # Initialize Firestore
        db = init_firestore()
        print("✅ Connected to Firestore")
        print()
        
        # Check recordings collection
        recording_ids = check_recordings_collection(db)
        print()
        
        # Check for recent insights (especially around 22:07:41 UTC)
        has_recent_voice_data = check_recent_insights(db, hours_back=24)
        print()
        
        # Summary
        print("📋 VERIFICATION SUMMARY")
        print("-" * 30)
        if recording_ids:
            print(f"✅ Found {len(recording_ids)} recordings in Firestore")
        else:
            print("❌ No recordings found")
            
        if has_recent_voice_data:
            print("✅ Recent voice analysis data found - Cloud function writes are working!")
        else:
            print("❌ No recent voice analysis data found")
            print("   This could mean:")
            print("   - No audio files were processed recently")
            print("   - Audio processing failed")
            print("   - Cloud function is not writing to Firestore")
        
        print()
        print("💡 If you found voice analysis data, the cloud function is working correctly!")
        print("💡 Look for documents with fields like:")
        print("   - vocal_analysis_f0_mean")
        print("   - vocal_analysis_jitter_local") 
        print("   - vocal_analysis_shimmer_local")
        print("   - vocal_analysis_hnr_mean")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()