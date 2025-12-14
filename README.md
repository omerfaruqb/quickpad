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

### Option 1: Docker Setup (Recommended)

The easiest way to get started is using Docker Compose, which sets up MongoDB, the server, and frontend automatically.

#### Prerequisites
- Docker Desktop (or Docker Engine + Docker Compose)
- Git

#### Installation with Docker

1. Clone the repository
```bash
git clone https://github.com/SidhuAchary02/quickpad.git
cd quickpad
```

2. Create environment files (optional - defaults are provided)
```bash
# Copy example files if you want to customize
# cp server/.env.example server/.env
# cp frontend/.env.example frontend/.env
```

3. Start all services with Docker Compose
```bash
docker-compose up
```

This will start:
- MongoDB on port 27017
- Server on port 5030
- Frontend on port 5173

4. Open your browser to `http://localhost:5173`

#### Docker Commands

```bash
# Start services in detached mode (background)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes (clean MongoDB data)
docker-compose down -v

# Rebuild after code changes
docker-compose up --build

# View logs for specific service
docker-compose logs -f server
docker-compose logs -f frontend
docker-compose logs -f mongodb
```

### Option 2: Manual Setup

#### Prerequisites
- Node.js (v22.19.0 or higher)
- React.js (19.1.10)
- MongoDB database (local or Atlas)
- Git

#### Installation

1. Clone the repository
```bash
git clone https://github.com/SidhuAchary02/quickpad.git
cd quickpad
```

2. Install server dependencies
```bash
cd server
npm install
```

3. Install frontend dependencies
```bash
cd frontend
npm install
```

4. Configure environment variables

Create `server/.env`:
```env
NODE_ENV=development
PORT=5030
MONGODB_URL=mongodb://localhost:27017/quickpad
JWT_SECRET=your_jwt_secret_key
CLIENT_URL=http://localhost:5173
```

Create `frontend/.env`:
```env
VITE_API_URL=http://localhost:5030
VITE_SOCKET_URL=http://localhost:5030
```

5. Start MongoDB (if running locally)
```bash
# Using Docker (if not using full Docker setup)
docker run -d -p 27017:27017 --name mongodb mongo:latest

# Or install MongoDB locally and start the service
```

6. Start the development servers

Server (terminal 1):
```bash
cd server
npm run dev
```

Frontend (terminal 2):
```bash
cd frontend
npm run dev
```

7. Open your browser to `http://localhost:5173`

## License
MIT License - see the [LICENSE](LICENSE) file for details.
