# Quickpad GCP Deployment Guide

This guide walks you through deploying Quickpad on Google Cloud Platform to meet CMPE 48A project requirements.

## 📋 Prerequisites

1. **GCP Account** with $300 free trial credits
2. **gcloud CLI** installed and configured
3. **kubectl** installed
4. **Docker** installed (for building images)
5. **Terraform** installed (optional, for IaC bonus)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    GCP Infrastructure                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Google Kubernetes Engine (GKE)           │  │
│  │  ┌──────────────┐      ┌─────────────────────┐ │  │
│  │  │  Frontend    │      │    Backend (HPA)     │ │  │
│  │  │  (React)     │      │  (Express+Socket.IO) │ │  │
│  │  │  2 replicas  │      │  2-5 replicas        │ │  │
│  │  └──────┬───────┘      └──────────┬────────────┘ │  │
│  │         └──────────────┬──────────┘              │  │
│  │                        ▼                          │  │
│  │              ┌─────────────────┐                  │  │
│  │              │  Ingress/LB     │                  │  │
│  │              └─────────────────┘                  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────┐    ┌─────────────────────────┐  │
│  │ Compute Engine   │    │  Cloud Functions        │  │
│  │ MongoDB VM       │    │  • cleanup-notes        │  │
│  │ (e2-small)       │    │  • analytics            │  │
│  └──────────────────┘    └─────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Step-by-Step Deployment

### Step 1: Set Up GCP Project

```bash
# Set your project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudscheduler.googleapis.com \
  storage-api.googleapis.com
```

### Step 2: Deploy MongoDB on Compute Engine VM

```bash
# Create MongoDB VM
gcloud compute instances create mongodb-vm \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-ssd \
  --tags=mongodb

# Set up firewall (internal only)
gcloud compute firewall-rules create allow-mongodb-internal \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:27017 \
  --source-ranges=10.0.0.0/8 \
  --target-tags=mongodb

# SSH into VM and run setup script
gcloud compute ssh mongodb-vm --zone=us-central1-a
# Then run: bash <(curl -s https://raw.githubusercontent.com/your-repo/vm-scripts/setup-mongodb.sh)
# Or copy setup-mongodb.sh to the VM and run it
```

**Get MongoDB Internal IP:**
```bash
MONGODB_IP=$(gcloud compute instances describe mongodb-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)')
echo "MongoDB IP: $MONGODB_IP"
```

### Step 3: Create GKE Cluster

**Option A: Standard Cluster (More Control)**
```bash
gcloud container clusters create quickpad-cluster \
  --zone=us-central1-a \
  --num-nodes=2 \
  --machine-type=e2-small \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=5 \
  --enable-autorepair \
  --enable-autoupgrade

# Get credentials
gcloud container clusters get-credentials quickpad-cluster --zone=us-central1-a
```

**Option B: Autopilot Cluster (Easier, Auto-managed)**
```bash
gcloud container clusters create-auto quickpad-cluster \
  --region=us-central1 \
  --project=$PROJECT_ID

gcloud container clusters get-credentials quickpad-cluster --region=us-central1
```

### Step 4: Build and Push Docker Images

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build and push frontend
cd docker
docker build -f frontend.Dockerfile \
  --build-arg VITE_API_URL=https://your-domain.com/api \
  --build-arg VITE_SOCKET_URL=https://your-domain.com \
  -t gcr.io/$PROJECT_ID/quickpad-frontend:latest \
  ..

docker push gcr.io/$PROJECT_ID/quickpad-frontend:latest

# Build and push backend
docker build -f backend.Dockerfile \
  -t gcr.io/$PROJECT_ID/quickpad-backend:latest \
  ..

docker push gcr.io/$PROJECT_ID/quickpad-backend:latest
```

### Step 5: Update Kubernetes Manifests

```bash
# Update image names in all deployment files
cd k8s
sed -i '' "s/YOUR_PROJECT_ID/$PROJECT_ID/g" *.yaml

# Update MongoDB URL in secrets
kubectl create secret generic quickpad-secrets \
  --from-literal=mongodb-url="mongodb://quickpad:PASSWORD@$MONGODB_IP:27017/quickpad" \
  --from-literal=jwt-secret="your-super-secret-jwt-key-change-this"

# Update ConfigMap with your domain
kubectl create configmap quickpad-config \
  --from-literal=client-url="https://your-domain.com"
```

### Step 6: Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml.example  # Or create your own
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f backend-hpa.yaml
kubectl apply -f managed-certificate.yaml
kubectl apply -f ingress.yaml

# Verify deployments
kubectl get pods
kubectl get services
kubectl get hpa
```

### Step 7: Deploy Cloud Functions

```bash
# Deploy cleanup-notes function
cd cloud-functions/cleanup-notes
gcloud functions deploy cleanup-expired-notes \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=cleanupExpiredNotes \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars=MONGODB_URL="mongodb://quickpad:PASSWORD@$MONGODB_IP:27017/quickpad"

# Create Cloud Scheduler job
gcloud scheduler jobs create http cleanup-notes-job \
  --schedule="0 * * * *" \
  --uri="https://us-central1-$PROJECT_ID.cloudfunctions.net/cleanup-expired-notes" \
  --http-method=POST \
  --location=us-central1

# Deploy analytics function
cd ../analytics
gcloud functions deploy process-analytics \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=processAnalytics \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars=MONGODB_URL="mongodb://quickpad:PASSWORD@$MONGODB_IP:27017/quickpad"
```

### Step 8: Set Up Ingress and Domain

```bash
# Get ingress IP (may take a few minutes)
kubectl get ingress quickpad-ingress

# Update your DNS to point to the ingress IP
# A record: your-domain.com -> <INGRESS_IP>

# Wait for SSL certificate provisioning (can take 10-15 minutes)
kubectl describe managedcertificate quickpad-ssl-cert
```

## 🧪 Performance Testing with Locust

```bash
# Install Locust
cd locust
pip install -r requirements.txt

# Run load test
./run-locust.sh https://your-domain.com 100 10 5m

# Or run with web UI
locust -f locustfile.py --host=https://your-domain.com

# Access UI at http://localhost:8089
```

**Test Scenarios:**
- **Light Load**: 50 users, spawn rate 5/sec, duration 5min
- **Medium Load**: 100 users, spawn rate 10/sec, duration 10min
- **Heavy Load**: 200 users, spawn rate 20/sec, duration 15min
- **Stress Test**: 500 users, spawn rate 50/sec, duration 20min

## 📊 Monitoring and Metrics

```bash
# View HPA status
kubectl get hpa -w

# View pod metrics
kubectl top pods

# View node metrics
kubectl top nodes

# Check logs
kubectl logs -f deployment/quickpad-backend
kubectl logs -f deployment/quickpad-frontend

# View Cloud Function logs
gcloud functions logs read cleanup-expired-notes --region=us-central1
```

## 💰 Cost Optimization

1. **Use Preemptible Nodes** (if using standard cluster):
   ```bash
   gcloud container node-pools create preemptible-pool \
     --cluster=quickpad-cluster \
     --preemptible \
     --num-nodes=2
   ```

2. **Monitor Spending**:
   ```bash
   gcloud billing budgets list --billing-account=YOUR_BILLING_ACCOUNT
   ```

3. **Set Budget Alerts** in GCP Console

## 🔧 Troubleshooting

**Pods not starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**HPA not scaling:**
```bash
kubectl describe hpa quickpad-backend-hpa
# Check if metrics are available
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/namespaces/default/pods"
```

**MongoDB connection issues:**
```bash
# Test from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod: telnet $MONGODB_IP 27017
```

**Ingress not working:**
```bash
kubectl describe ingress quickpad-ingress
# Check backend services
kubectl get endpoints
```

## 🗑️ Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Delete GKE cluster
gcloud container clusters delete quickpad-cluster --zone=us-central1-a

# Delete Cloud Functions
gcloud functions delete cleanup-expired-notes --region=us-central1
gcloud functions delete process-analytics --region=us-central1

# Delete MongoDB VM
gcloud compute instances delete mongodb-vm --zone=us-central1-a

# Delete firewall rules
gcloud compute firewall-rules delete allow-mongodb-internal
```

## 📝 Terraform Deployment (Bonus)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply

# Get outputs
terraform output mongodb_internal_ip
terraform output gke_cluster_name
```

## ✅ Verification Checklist

- [ ] MongoDB VM is running and accessible
- [ ] GKE cluster is created and nodes are ready
- [ ] Frontend and backend pods are running
- [ ] HPA is configured and working
- [ ] Ingress is configured with SSL certificate
- [ ] Cloud Functions are deployed and scheduled
- [ ] Load testing with Locust completes successfully
- [ ] Metrics are being collected
- [ ] Cost is within $300 budget

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Locust Documentation](https://docs.locust.io/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

