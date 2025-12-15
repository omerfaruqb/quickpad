#!/bin/bash
# Script to build and push Docker images to GCR

set -e

PROJECT_ID=${1:-"your-project-id"}
FRONTEND_URL=${2:-"https://your-domain.com"}

if [ "$PROJECT_ID" == "your-project-id" ]; then
  echo "❌ Error: Please provide your GCP project ID"
  echo "Usage: ./build-and-push.sh <PROJECT_ID> [FRONTEND_URL]"
  exit 1
fi

echo "🔨 Building Docker images..."
echo "Project ID: $PROJECT_ID"
echo "Frontend URL: $FRONTEND_URL"

# Configure Docker for GCR
gcloud auth configure-docker --quiet

# Build and push frontend
echo "📦 Building frontend image..."
docker build -f docker/frontend.Dockerfile \
  --build-arg VITE_API_URL="$FRONTEND_URL" \
  --build-arg VITE_SOCKET_URL="$FRONTEND_URL" \
  -t gcr.io/$PROJECT_ID/quickpad-frontend:latest \
  -t gcr.io/$PROJECT_ID/quickpad-frontend:$(git rev-parse --short HEAD) \
  .

echo "📤 Pushing frontend image..."
docker push gcr.io/$PROJECT_ID/quickpad-frontend:latest
docker push gcr.io/$PROJECT_ID/quickpad-frontend:$(git rev-parse --short HEAD)

# Build and push backend
echo "📦 Building backend image..."
docker build -f docker/backend.Dockerfile \
  -t gcr.io/$PROJECT_ID/quickpad-backend:latest \
  -t gcr.io/$PROJECT_ID/quickpad-backend:$(git rev-parse --short HEAD) \
  .

echo "📤 Pushing backend image..."
docker push gcr.io/$PROJECT_ID/quickpad-backend:latest
docker push gcr.io/$PROJECT_ID/quickpad-backend:$(git rev-parse --short HEAD)

echo "✅ Images built and pushed successfully!"
echo ""
echo "Frontend: gcr.io/$PROJECT_ID/quickpad-frontend:latest"
echo "Backend:  gcr.io/$PROJECT_ID/quickpad-backend:latest"

