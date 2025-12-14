#!/bin/bash
# Firewall setup script for MongoDB VM
# Run this from your local machine or Cloud Shell

PROJECT_ID="YOUR_PROJECT_ID"  # Update this
ZONE="us-central1-a"  # Update to match your VM zone

echo "🔥 Setting up firewall rules for MongoDB..."

# Create firewall rule to allow internal traffic only
gcloud compute firewall-rules create allow-mongodb-internal \
  --project=$PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:27017 \
  --source-ranges=10.0.0.0/8 \
  --target-tags=mongodb \
  --description="Allow MongoDB access from internal GCP network only"

echo "✅ Firewall rule created!"
echo ""
echo "📝 Don't forget to tag your MongoDB VM:"
echo "   gcloud compute instances add-tags mongodb-vm --tags=mongodb --zone=$ZONE"

