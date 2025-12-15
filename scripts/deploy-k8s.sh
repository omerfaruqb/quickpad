#!/bin/bash
# Script to deploy Kubernetes manifests

set -e

PROJECT_ID=${1:-"your-project-id"}

if [ "$PROJECT_ID" == "your-project-id" ]; then
  echo "❌ Error: Please provide your GCP project ID"
  echo "Usage: ./deploy-k8s.sh <PROJECT_ID>"
  exit 1
fi

echo "🚀 Deploying to Kubernetes..."
echo "Project ID: $PROJECT_ID"

# Update image names in deployment files
echo "📝 Updating image references..."
cd k8s
sed -i.bak "s/YOUR_PROJECT_ID/$PROJECT_ID/g" frontend-deployment.yaml backend-deployment.yaml
rm -f *.bak

# Apply manifests in order
echo "📦 Applying ConfigMap..."
kubectl apply -f configmap.yaml

echo "🔐 Applying Secrets..."
if [ ! -f secrets.yaml ]; then
  echo "⚠️  Warning: secrets.yaml not found. Using example file."
  echo "Please create secrets.yaml with your actual secrets."
  kubectl apply -f secrets.yaml.example || true
else
  kubectl apply -f secrets.yaml
fi

echo "🎯 Deploying Frontend..."
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

echo "🎯 Deploying Backend..."
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f backend-hpa.yaml

echo "🌐 Setting up Ingress..."
kubectl apply -f managed-certificate.yaml
kubectl apply -f ingress.yaml

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/quickpad-frontend
kubectl wait --for=condition=available --timeout=300s deployment/quickpad-backend

echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
kubectl get pods
kubectl get services
kubectl get hpa

echo ""
echo "🌐 Ingress IP:"
kubectl get ingress quickpad-ingress

