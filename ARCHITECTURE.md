# Quickpad Cloud Architecture

## Overview

Quickpad is deployed on Google Cloud Platform using a cloud-native architecture that meets all CMPE 48A project requirements.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Google Cloud Platform                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              Google Kubernetes Engine (GKE)                  │  │
│  │                                                               │  │
│  │  ┌───────────────────────────────────────────────────────┐  │  │
│  │  │                    Ingress Controller                 │  │  │
│  │  │              (Cloud Load Balancer + SSL)               │  │  │
│  │  └──────────────┬──────────────────┬───────────────────┘  │  │
│  │                 │                    │                      │  │
│  │  ┌──────────────▼──────────┐  ┌──────▼───────────────────┐  │  │
│  │  │   Frontend Service       │  │   Backend Service        │  │  │
│  │  │   (ClusterIP)            │  │   (ClusterIP +           │  │  │
│  │  │                          │  │    SessionAffinity)     │  │  │
│  │  └──────────────┬──────────┘  └──────┬───────────────────┘  │  │
│  │                 │                     │                      │  │
│  │  ┌──────────────▼──────────┐  ┌──────▼───────────────────┐  │  │
│  │  │  Frontend Deployment     │  │  Backend Deployment      │  │  │
│  │  │  • 2 replicas            │  │  • 2-5 replicas (HPA)   │  │  │
│  │  │  • React + Nginx         │  │  • Express + Socket.IO  │  │  │
│  │  │  • Stateless              │  │  • Stateful (sessions)  │  │  │
│  │  └──────────────────────────┘  └─────────────────────────┘  │  │
│  │                                                               │  │
│  │  ┌───────────────────────────────────────────────────────┐  │  │
│  │  │         Horizontal Pod Autoscaler (HPA)               │  │  │
│  │  │  • CPU threshold: 70%                                 │  │  │
│  │  │  • Memory threshold: 80%                               │  │  │
│  │  │  • Min replicas: 2                                    │  │  │
│  │  │  • Max replicas: 5                                    │  │  │
│  │  └───────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐  │
│  │  Compute Engine VM       │  │  Cloud Functions             │  │
│  │                          │  │                              │  │
│  │  • e2-small instance     │  │  • cleanup-expired-notes     │  │
│  │  • MongoDB 7.0           │  │    (HTTP trigger +           │  │
│  │  • 20GB SSD disk         │  │     Cloud Scheduler)        │  │
│  │  • Internal IP only      │  │                              │  │
│  │  • Firewall: 10.0.0.0/8  │  │  • process-analytics        │  │
│  │                          │  │    (HTTP trigger)            │  │
│  └──────────┬───────────────┘  └──────────────────────────────┘  │
│             │                                                     │
│             └───────────────────┐                                │
│                                 │                                 │
│  ┌──────────────────────────────▼──────────────────────────────┐ │
│  │                    MongoDB Database                         │ │
│  │  • Database: quickpad                                       │ │
│  │  • Collections: notes, users                               │ │
│  │  • TTL index on expires_at                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Frontend (React Application)

**Deployment**: Kubernetes Deployment  
**Replicas**: 2 (fixed)  
**Container**: Nginx serving static React build  
**Resource Limits**:
- CPU: 200m (request: 50m)
- Memory: 256Mi (request: 128Mi)

**Why Kubernetes?**
- Stateless application, perfect for containerization
- Easy scaling and updates
- Load balancing built-in

### 2. Backend (Express.js + Socket.IO)

**Deployment**: Kubernetes Deployment with HPA  
**Replicas**: 2-5 (auto-scaled)  
**Container**: Node.js 20 Alpine  
**Resource Limits**:
- CPU: 500m (request: 100m)
- Memory: 512Mi (request: 256Mi)

**HPA Configuration**:
- **CPU Threshold**: 70% average utilization
- **Memory Threshold**: 80% average utilization
- **Min Replicas**: 2
- **Max Replicas**: 5
- **Scale Down**: 50% reduction, 5min stabilization
- **Scale Up**: 100% increase or +2 pods, 15sec stabilization

**Why HPA?**
- Handles traffic spikes during load testing
- Cost-effective (scales down during low traffic)
- Meets project requirement for scalable deployment

**Socket.IO Considerations**:
- Uses `sessionAffinity: ClientIP` in Service
- Ensures sticky sessions for WebSocket connections
- For larger scale, consider Redis adapter

### 3. MongoDB (Database)

**Deployment**: Compute Engine VM  
**Instance Type**: e2-small  
**Storage**: 20GB SSD persistent disk  
**Network**: Internal IP only (10.0.0.0/8)  
**Firewall**: Port 27017, internal traffic only

**Why VM instead of Managed Service?**
- **Meets project requirement** for VM integration
- More cost-effective for $300 budget
- Full control over configuration

**Security**:
- No public IP (internal only)
- Firewall restricts access to GKE cluster
- Database user authentication

### 4. Cloud Functions (Serverless)

#### cleanup-expired-notes
- **Trigger**: HTTP (called by Cloud Scheduler)
- **Schedule**: Every hour (cron: `0 * * * *`)
- **Function**: Deletes notes where `expires_at < now()`
- **Replaces**: Previous `setInterval` in server.js

#### process-analytics
- **Trigger**: HTTP
- **Function**: Generates statistics (total notes, users, etc.)
- **Use Case**: Analytics dashboard or monitoring

**Why Cloud Functions?**
- Meets serverless requirement
- Cost-effective (pay per invocation)
- Reduces server load
- Easy to schedule recurring tasks

## Data Flow

### Note Creation Flow
```
User → Ingress → Frontend Service → Frontend Pod
                                    ↓
User → Ingress → Backend Service → Backend Pod → MongoDB VM
```

### Real-time Collaboration Flow
```
User 1 → Socket.IO → Backend Pod 1 → MongoDB
User 2 → Socket.IO → Backend Pod 2 → MongoDB
                    ↓
            Socket.IO broadcasts changes
```

### Cleanup Flow
```
Cloud Scheduler (hourly) → Cloud Function → MongoDB VM
```

## Scaling Behavior

### Normal Load (< 70% CPU)
- Backend: 2 replicas
- Frontend: 2 replicas
- Cost: ~$50-70/month

### High Load (> 70% CPU)
- Backend: Auto-scales to 3-5 replicas
- Frontend: Remains at 2 replicas (stateless)
- Cost: ~$80-120/month

### Load Testing Scenario
- Locust generates 100-500 concurrent users
- HPA detects CPU spike
- Backend scales to 5 replicas
- After test, scales back to 2 replicas

## Security Considerations

1. **Network Security**
   - MongoDB only accessible from internal network
   - Ingress uses managed SSL certificates
   - Firewall rules restrict access

2. **Secrets Management**
   - Kubernetes Secrets for sensitive data
   - Environment variables for configuration
   - No hardcoded credentials

3. **Application Security**
   - JWT authentication
   - Password hashing (bcrypt)
   - CORS configured for production domain

## Cost Breakdown (Estimated)

| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| GKE Cluster | Autopilot or 2x e2-small | $50-70 |
| Compute Engine | e2-small + 20GB SSD | $15-20 |
| Cloud Functions | Minimal invocations | $0-5 |
| Load Balancer | Ingress | $18 |
| Container Registry | Image storage | $2-5 |
| **Total** | | **$85-120/month** |

✅ **Well within $300 trial credit** for 2-3 months of testing

## Performance Metrics

### Key Metrics to Monitor

1. **Request Latency**
   - P50, P95, P99 percentiles
   - Target: < 200ms for API calls

2. **Throughput**
   - Requests per second (RPS)
   - Target: Handle 100+ concurrent users

3. **Resource Usage**
   - CPU utilization (target: < 70%)
   - Memory usage (target: < 80%)
   - Pod count (should scale with load)

4. **Error Rates**
   - HTTP 5xx errors (target: < 1%)
   - Database connection errors
   - Socket.IO connection failures

### Load Testing Scenarios

1. **Light Load**: 50 users, 5 RPS
2. **Medium Load**: 100 users, 10 RPS
3. **Heavy Load**: 200 users, 20 RPS
4. **Stress Test**: 500 users, 50 RPS

## Disaster Recovery

1. **Database Backup**
   - Manual: `mongodump` scheduled via Cloud Scheduler
   - Consider: Automated backup to Cloud Storage

2. **Application Recovery**
   - Kubernetes automatically restarts failed pods
   - HPA ensures minimum replicas
   - Ingress provides high availability

3. **Data Persistence**
   - MongoDB data on persistent disk
   - Consider: Regular snapshots

## Future Improvements

1. **Redis for Socket.IO** (multi-pod scaling)
2. **MongoDB Replica Set** (high availability)
3. **CDN for Frontend** (Cloud CDN)
4. **Monitoring Stack** (Prometheus + Grafana)
5. **CI/CD Pipeline** (Cloud Build)
6. **Automated Backups** (Cloud Storage)

