#!/bin/bash
# Script to deploy Cloud Functions

set -e

PROJECT_ID=${1:-"your-project-id"}
MONGODB_URL=${2:-""}
REGION=${3:-"us-central1"}

if [ "$PROJECT_ID" == "your-project-id" ] || [ -z "$MONGODB_URL" ]; then
  echo "❌ Error: Please provide required parameters"
  echo "Usage: ./deploy-functions.sh <PROJECT_ID> <MONGODB_URL> [REGION]"
  exit 1
fi

echo "☁️  Deploying Cloud Functions..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

# Deploy cleanup-notes function
echo "🧹 Deploying cleanup-notes function..."
cd cloud-functions/cleanup-notes
gcloud functions deploy cleanup-expired-notes \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=cleanupExpiredNotes \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars=MONGODB_URL="$MONGODB_URL" \
  --project=$PROJECT_ID

CLEANUP_URL=$(gcloud functions describe cleanup-expired-notes \
  --region=$REGION \
  --gen2 \
  --format='value(serviceConfig.uri)' \
  --project=$PROJECT_ID)

echo "✅ Cleanup function deployed: $CLEANUP_URL"

# Create Cloud Scheduler job
echo "⏰ Creating Cloud Scheduler job..."
gcloud scheduler jobs create http cleanup-notes-job \
  --schedule="0 * * * *" \
  --uri="$CLEANUP_URL" \
  --http-method=POST \
  --location=$REGION \
  --project=$PROJECT_ID \
  2>/dev/null || echo "⚠️  Scheduler job may already exist"

# Deploy analytics function
echo "📊 Deploying analytics function..."
cd ../analytics
gcloud functions deploy process-analytics \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=processAnalytics \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars=MONGODB_URL="$MONGODB_URL" \
  --project=$PROJECT_ID

ANALYTICS_URL=$(gcloud functions describe process-analytics \
  --region=$REGION \
  --gen2 \
  --format='value(serviceConfig.uri)' \
  --project=$PROJECT_ID)

echo "✅ Analytics function deployed: $ANALYTICS_URL"

echo ""
echo "✅ All Cloud Functions deployed successfully!"
echo ""
echo "Functions:"
echo "  - cleanup-expired-notes: $CLEANUP_URL"
echo "  - process-analytics: $ANALYTICS_URL"

