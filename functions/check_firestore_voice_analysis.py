#!/usr/bin/env python3
"""
Quick script to check if voice analysis results exist in Firestore.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import sys

def main():
    try:
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred, {
                'projectId': 'sage-2d21f',
            })
        
        # Get Firestore client
        db = firestore.client()
        
        # Check for the recent recording
        recording_id = "1A7412FB-852A-487C-A561-1EEC916E4BAB"
        
        print(f"🔍 Checking for voice analysis results for recording: {recording_id}")
        
        # Try the recordings collection structure
        recordings_ref = db.collection('recordings').document(recording_id)
        recording_doc = recordings_ref.get()
        
        if recording_doc.exists:
            print(f"✅ Found recording document: {recording_id}")
            data = recording_doc.to_dict()
            
            # Check for voice analysis fields
            voice_fields = [k for k in data.keys() if k.startswith('vocal_analysis_')]
            if voice_fields:
                print(f"✅ Found {len(voice_fields)} voice analysis fields:")
                for field in sorted(voice_fields):
                    value = data[field]
                    print(f"   {field}: {value}")
            else:
                print("❌ No voice analysis fields found in recording document")
                print(f"Available fields: {list(data.keys())}")
            
            # Check insights subcollection
            insights_ref = recordings_ref.collection('insights')
            insights_docs = insights_ref.get()
            
            if insights_docs:
                print(f"✅ Found {len(insights_docs)} insights documents:")
                for doc in insights_docs:
                    insight_data = doc.to_dict()
                    print(f"   Document ID: {doc.id}")
                    voice_fields = [k for k in insight_data.keys() if k.startswith('vocal_analysis_')]
                    if voice_fields:
                        print(f"      Voice analysis fields: {len(voice_fields)}")
                        for field in sorted(voice_fields):
                            value = insight_data[field]
                            print(f"         {field}: {value}")
                    else:
                        print(f"      Available fields: {list(insight_data.keys())}")
            else:
                print("❌ No insights documents found")
        else:
            print(f"❌ Recording document not found: {recording_id}")
        
        # Also check users collection structure (in case it's there)
        print(f"\n🔍 Checking users collection structure...")
        users_ref = db.collection('users')
        users_docs = users_ref.limit(1).get()
        
        if users_docs:
            print(f"✅ Found users collection with {len(users_docs)} sample document(s)")
            # Check voice_analyses subcollection for any user
            for user_doc in users_docs:
                user_id = user_doc.id
                voice_analyses_ref = user_doc.reference.collection('voice_analyses')
                voice_docs = voice_analyses_ref.limit(5).get()
                
                if voice_docs:
                    print(f"✅ Found {len(voice_docs)} voice analysis documents for user {user_id[:8]}...")
                    for voice_doc in voice_docs:
                        data = voice_doc.to_dict()
                        voice_fields = [k for k in data.keys() if k.startswith('vocal_analysis_')]
                        print(f"   Document {voice_doc.id}: {len(voice_fields)} voice fields")
                        if voice_fields:
                            # Show key fields
                            f0_mean = data.get('vocal_analysis_f0_mean')
                            jitter = data.get('vocal_analysis_jitter_local')
                            timestamp = data.get('timestamp')
                            print(f"      F0: {f0_mean}Hz, Jitter: {jitter}%, Time: {timestamp}")
                else:
                    print(f"❌ No voice analysis documents found for user {user_id[:8]}...")
        else:
            print("❌ No users collection found")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())