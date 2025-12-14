# Quick Start Guide - GCP Deployment

This is a condensed guide for quick deployment. For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Prerequisites Checklist

- [ ] GCP account with $300 credits
- [ ] `gcloud` CLI installed and authenticated
- [ ] `kubectl` installed
- [ ] `docker` installed
- [ ] Domain name (optional, can use IP initially)

## 5-Minute Deployment

### 1. Set Environment Variables

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export ZONE="us-central1-a"
export DOMAIN="your-domain.com"  # Optional
export MONGODB_PASSWORD="secure-password-123"
```

### 2. Enable GCP APIs

```bash
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudscheduler.googleapis.com \
  --project=$PROJECT_ID
```

### 3. Create MongoDB VM

```bash
gcloud compute instances create mongodb-vm \
  --zone=$ZONE \
  --machine-type=e2-small \
  --image-family=ubuntu-2204-lts \
  --boot-disk-size=20GB \
  --tags=mongodb

# Get internal IP
MONGODB_IP=$(gcloud compute instances describe mongodb-vm \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].networkIP)')

# Setup firewall
gcloud compute firewall-rules create allow-mongodb-internal \
  --allow=tcp:27017 \
  --source-ranges=10.0.0.0/8 \
  --target-tags=mongodb

# SSH and setup MongoDB
gcloud compute ssh mongodb-vm --zone=$ZONE --command="bash -s" < vm-scripts/setup-mongodb.sh
```

### 4. Create GKE Cluster

```bash
gcloud container clusters create-auto quickpad-cluster \
  --region=$REGION \
  --project=$PROJECT_ID

gcloud container clusters get-credentials quickpad-cluster --region=$REGION
```

### 5. Build and Push Images

```bash
./scripts/build-and-push.sh $PROJECT_ID https://$DOMAIN
```

### 6. Create Secrets

```bash
MONGODB_URL="mongodb://quickpad:$MONGODB_PASSWORD@$MONGODB_IP:27017/quickpad"

kubectl create secret generic quickpad-secrets \
  --from-literal=mongodb-url="$MONGODB_URL" \
  --from-literal=jwt-secret="$(openssl rand -base64 32)"

kubectl create configmap quickpad-config \
  --from-literal=client-url="https://$DOMAIN"
```

### 7. Deploy to Kubernetes

```bash
# Update image names in k8s files
sed -i '' "s/YOUR_PROJECT_ID/$PROJECT_ID/g" k8s/*.yaml

# Apply all manifests
kubectl apply -f k8s/

# Wait for pods
kubectl wait --for=condition=available --timeout=300s deployment/quickpad-frontend
kubectl wait --for=condition=available --timeout=300s deployment/quickpad-backend
```

### 8. Deploy Cloud Functions

```bash
./scripts/deploy-functions.sh $PROJECT_ID "$MONGODB_URL" $REGION
```

### 9. Get Ingress IP

```bash
kubectl get ingress quickpad-ingress
# Update DNS A record to point to the IP shown
```

## Verify Deployment

```bash
# Check pods
kubectl get pods

# Check services
kubectl get services

# Check HPA
kubectl get hpa

# Check functions
gcloud functions list --region=$REGION

# Test health endpoint
curl https://$DOMAIN/api/health
```

## Run Load Test

```bash
cd locust
pip install -r requirements.txt
./run-locust.sh https://$DOMAIN 100 10 5m
```

## Common Issues

**Pods not starting:**
- Check logs: `kubectl logs <pod-name>`
- Check secrets: `kubectl get secrets`
- Verify image exists: `gcloud container images list`

**HPA not scaling:**
- Check metrics: `kubectl top pods`
- Verify HPA: `kubectl describe hpa quickpad-backend-hpa`

**MongoDB connection failed:**
- Verify firewall rule
- Check MongoDB is running: `gcloud compute ssh mongodb-vm --zone=$ZONE --command="sudo systemctl status mongod"`
- Test connection from pod: `kubectl run -it --rm debug --image=busybox --restart=Never -- telnet $MONGODB_IP 27017`

## Next Steps

1. Set up monitoring and alerts
2. Configure backup for MongoDB
3. Set up CI/CD pipeline
4. Review cost optimization
5. Document performance test results

