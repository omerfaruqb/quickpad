#!/bin/bash
# MongoDB Setup Script for GCP Compute Engine VM
# Run this script on your MongoDB VM instance

set -e

echo "🚀 Starting MongoDB setup..."

# Update system
sudo apt-get update
sudo apt-get install -y gnupg curl wget

# Install MongoDB 7.0
echo "📦 Installing MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update
sudo apt-get install -y mongodb-org

# Configure MongoDB to listen on all interfaces (for internal network access)
echo "⚙️  Configuring MongoDB..."
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Enable MongoDB service
echo "🔄 Enabling MongoDB service..."
sudo systemctl enable mongod
sudo systemctl start mongod

# Wait for MongoDB to start
sleep 5

# Create database user
echo "👤 Creating database user..."
mongosh <<EOF
use admin
db.createUser({
  user: "quickpad",
  pwd: "quickpad_mongo_password",
  roles: [{ role: "readWrite", db: "quickpad" }]
})
EOF

# Create quickpad database
mongosh <<EOF
use quickpad
db.createCollection("notes")
db.createCollection("users")
EOF

echo "✅ MongoDB setup complete!"
echo ""
echo "📝 Next steps:"
echo "2. Update your Kubernetes secrets with the MongoDB connection string:"
echo "   mongodb://quickpad:PASSWORD@INTERNAL_IP:27017/quickpad"
echo "3. Get the internal IP with: curl -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/ip"

