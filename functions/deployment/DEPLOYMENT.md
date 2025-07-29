# Deployment Guide

## Prerequisites

- Firebase CLI installed
- Google Cloud project configured
- Service account with appropriate permissions

## Quick Deploy

```bash
# Deploy to Firebase Functions
firebase deploy --only functions

# Or use the deployment script
./deploy.sh
```

## Environment Setup

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Project** (if not already done)
   ```bash
   firebase init functions
   ```

## Configuration

The function uses the following environment variables:
- `GCP_PROJECT`: Google Cloud project ID
- `GOOGLE_APPLICATION_CREDENTIALS`: Service account key (optional)

## Monitoring

Monitor function performance in the Firebase Console:
- Function execution logs
- Error rates and latency
- Resource usage and scaling 