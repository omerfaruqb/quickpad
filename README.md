# QuickPad
A minimalist, browser-based notepad for quick, secure, and anonymous note-taking.

## Features
- **Instant note creation** - No registration required, start writing immediately
- **Unique URLs** - Each note gets its own shareable link
- **Optional password protection** - Secure your notes with custom passwords
- **Anonymous or authenticated** - Use without signup or create an account for additional features
- **Real-time collaboration** - Multiple users can edit notes simultaneously
- **Clean interface** - Distraction-free writing environment
- **Fast and lightweight** - Optimized for speed and minimal resource usage

## Usage
1. **Create a note** - Visit the homepage and start typing
2. **Share instantly** - Copy the unique URL to share with others
3. **Add protection** - Set a password for sensitive notes
4. **Collaborate** - Share the URL with others for real-time editing
5. **Optional account** - Sign up to manage and organize your notes

## Security
- **Client-side encryption** - Passwords are hashed before transmission
- **No data mining** - We don't track or analyze your content
- **Secure connections** - All data transmitted over HTTPS
- **Anonymous by default** - No personal information required
- **Auto-cleanup** - Notes can be set to expire automatically

## Local Setup
### Prerequisites
- Node.js (v22.19.0 or higher)
- React.js (19.1.10)
- MongoDB database
- Git

### Installation
1. Clone the repository

```
git clone https://github.com/SidhuAchary02/quickpad.git
cd quickpad
```

2. Install server dependencies
```
cd server
npm install
```


3. Install frontend dependencies
```
cd frontend
npm install
```


4. Configure environment variables
```
#server (.env)
NODE_ENV=development
MONGODB_URL=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
CLIENT_URL=http://localhost:5173

#Frontend (.env)
VITE_API_URL=http://localhost:5030
VITE_SOCKET_URL=http://localhost:5030
```


5. Start the development servers

server (terminal 1)
```
cd server
npm run dev
```

Frontend (terminal 2)
```
cd frontend
npm run dev
```


6. Open your browser to `http://localhost:5173`

## ☁️ GCP Cloud Deployment

This project is configured for deployment on Google Cloud Platform to meet CMPE 48A requirements.

### Architecture Components

- **Frontend**: React app deployed on GKE (Kubernetes)
- **Backend**: Express.js + Socket.IO deployed on GKE with HPA (Horizontal Pod Autoscaler)
- **Database**: MongoDB on Compute Engine VM
- **Serverless**: Cloud Functions for cleanup and analytics
- **Load Testing**: Locust scripts for performance evaluation

### Quick Start Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

**Quick commands:**
```bash
# Build and push Docker images
./scripts/build-and-push.sh YOUR_PROJECT_ID https://your-domain.com

# Deploy to Kubernetes
./scripts/deploy-k8s.sh YOUR_PROJECT_ID

# Deploy Cloud Functions
./scripts/deploy-functions.sh YOUR_PROJECT_ID "mongodb://..." us-central1
```

### Project Structure

```
quickpad/
├── frontend/              # React frontend application
├── server/                # Express.js backend API
├── docker/                # Dockerfiles for containerization
├── k8s/                   # Kubernetes manifests
│   ├── frontend-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── backend-hpa.yaml   # Horizontal Pod Autoscaler
│   └── ingress.yaml
├── cloud-functions/       # Serverless functions
│   ├── cleanup-notes/     # Expired notes cleanup
│   └── analytics/         # Analytics processing
├── vm-scripts/            # MongoDB VM setup scripts
├── locust/                # Performance testing scripts
├── terraform/             # Infrastructure as Code (bonus)
└── scripts/               # Deployment automation scripts
```

### Performance Testing

Run Locust load tests:
```bash
cd locust
pip install -r requirements.txt
./run-locust.sh https://your-domain.com 100 10 5m
```

### Requirements Met

✅ **Containerized workloads on Kubernetes** - Frontend and backend deployed on GKE  
✅ **Virtual Machines** - MongoDB on Compute Engine VM  
✅ **Serverless Functions** - Cloud Functions for cleanup and analytics  
✅ **Scalable deployment** - HPA configured for auto-scaling  
✅ **Performance testing** - Locust scripts included  
✅ **Infrastructure as Code** - Terraform configuration (bonus)

## License
MIT License - see the [LICENSE](LICENSE) file for details.
