# Deployment Guide

## Prerequisites

- Google Cloud CLI installed
- Google Cloud project configured
- Service account with appropriate permissions

## Quick Deploy

```bash
# Deploy to Cloud Run
gcloud run deploy sage-voice-analysis --source .

# Or use the deployment script
./deploy.sh
```

## Environment Setup

1. **Install Google Cloud CLI**
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Or download from Google Cloud Console
   ```

2. **Login to Google Cloud**
   ```bash
   gcloud auth login
   ```

3. **Set Project**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

## Configuration

The function uses the following environment variables:
- `GCP_PROJECT`: Google Cloud project ID
- `GOOGLE_APPLICATION_CREDENTIALS`: Service account key (optional)

## Monitoring

Monitor function performance in the Google Cloud Console:
- Cloud Run service logs
- Error rates and latency
- Resource usage and scaling
- Firebase Storage trigger events 