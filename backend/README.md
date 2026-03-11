# Smart Livestock Backend

Backend API server for Smart Livestock Manager application.

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

## Production

```bash
npm run build
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile
- `POST /api/auth/logout` - User logout

### Frontend Pages
- `GET /dashboard` - Main dashboard
- `GET /register-animal` - Animal registration
- `GET /marketing` - Marketing assistant

### System
- `GET /health` - Health check

## Features

- ✅ JWT Authentication
- ✅ Offline-first with Dexie
- ✅ File uploads with Multer
- ✅ PostgreSQL sync (when available)
- ✅ CORS enabled
- ✅ Security with Helmet
- ✅ Compression middleware
- ✅ Request logging

## Environment

Create `.env` file:
```env
PORT=3000
NODE_ENV=development
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
SYNC_INTERVAL=30000
DATABASE_URL=postgresql://user:password@localhost:5432/db
```
