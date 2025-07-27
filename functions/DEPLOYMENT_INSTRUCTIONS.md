# F0 Cloud Function Deployment Instructions

## 🚀 Quick Deployment

### Option 1: Use the Automated Script (Recommended)

```bash
cd functions
chmod +x deploy.sh
./deploy.sh
```

This script will:
- ✅ Handle Python version compatibility
- ✅ Install dependencies automatically
- ✅ Test the function locally
- ✅ Deploy to Firebase

### Option 2: Manual Deployment

If the automated script doesn't work, follow these steps:

#### Step 1: Set up Python Environment
```bash
cd functions

# Remove existing venv
rm -rf venv

# Create new venv with Python 3.11 (or 3.10/3.9)
python3.11 -m venv venv
source venv/bin/activate

# Upgrade pip and install build tools
pip install --upgrade pip
pip install setuptools wheel
```

#### Step 2: Install Dependencies
```bash
# Try updated requirements first
pip install -r requirements_updated.txt

# If that fails, use minimal requirements
pip install firebase-admin google-cloud-storage numpy parselmouth soundfile
```

#### Step 3: Test Locally
```bash
python3 test_main.py
```

#### Step 4: Deploy
```bash
firebase deploy --only functions
```

## 🔧 Troubleshooting

### Python Version Issues
If you get Python compatibility errors:

```bash
# Check available Python versions
ls /usr/bin/python*
which python3.11

# Install Python 3.11 if needed
brew install python@3.11
```

### Dependency Issues
If some packages fail to install:

```bash
# Use existing requirements
pip install -r requirements.txt
```

### Firebase CLI Issues
If Firebase CLI is not working:

```bash
# Reinstall Firebase CLI
npm uninstall -g firebase-tools
npm install -g firebase-tools

# Login and select project
firebase login
firebase use sage-2d21f
```

## 🧪 Testing After Deployment

### 1. Check Function Status
```bash
firebase functions:list
```

### 2. Monitor Logs
```bash
firebase functions:log
```

### 3. Test with Audio Upload
1. Upload a WAV file to Firebase Storage
2. Check the function logs for processing
3. Verify F0 data is created in Firestore

## 📊 Monitoring

### Firebase Console
- Go to: https://console.firebase.google.com/project/sage-2d21f/functions
- Check function status and logs

### Expected Log Messages
```
Processing audio file: users/{userId}/recordings/{recordingId}/audio.wav
F0 extraction completed: 220.5 Hz (confidence: 95.7%)
F0 insights stored for user {userId}, recording {recordingId}
```

## 🎯 Success Indicators

After successful deployment, you should see:

1. ✅ Function deployed without errors
2. ✅ Local tests pass
3. ✅ Function appears in Firebase Console
4. ✅ Can upload audio files and see F0 processing logs
5. ✅ F0 data appears in Firestore with correct structure

## 🆘 If Deployment Fails

### Try Firebase Emulator Instead
```bash
firebase emulators:start --only functions
```

This will run the function locally for testing without deploying.

### Check Logs
```bash
firebase functions:log --only process_audio_file
```

### Verify Configuration
```bash
# Check Firebase project
firebase projects:list

# Check current project
firebase use
```

---

**Need Help?** Check the logs and error messages for specific issues. 