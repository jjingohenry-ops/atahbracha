# Atahbracah Animal Management System

A livestock management system with Flutter frontend and Node.js backend.

## 📁 Project Structure

```
atahbracah/
├── frontend/    # Flutter web/mobile app
├── backend/     # Node.js + Express API (port 3000)
├── package.json # Monorepo root
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Flutter SDK 3.0+

### 1. Install dependencies

```bash
# From project root
cd /path/to/atahbracah
npm install
cd backend && npm install
cd ../frontend && flutter pub get
```

### 2. Start the Backend (port 3000)

```bash
cd backend
npm run dev
```

Wait until you see: `🚀 Smart Livestock Backend Server running on port 3000`

### 3. Start the Frontend (port 8080) — in a separate terminal

```bash
cd frontend
flutter run -d web-server --web-port=8080
```

Wait until you see: `lib/main.dart is being served at http://localhost:8080`

Then open **http://localhost:8080** in your browser.

---

### Alternatively — start both at once from project root

```bash
npm run dev
```

> ⚠️ Note: Both commands are long-running. Use two separate terminal windows.

---

### Useful Commands

| Task | Command |
|------|---------|
| Backend only | `cd backend && npm run dev` |
| Frontend only | `cd frontend && flutter run -d web-server --web-port=8080` |
| Build backend | `cd backend && npm run build` |
| Build Flutter web | `cd frontend && flutter build web` |
| Prisma Studio (DB UI) | `cd backend && npx prisma studio` |
| Push DB schema | `cd backend && npx prisma db push` |

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter with Material Design 3
- **State Management**: Provider pattern
- **Authentication**: Firebase Auth
- **Offline Storage**: Dexie.js integration
- **Platform Support**: iOS, Android, Web

### Backend (Node.js)
- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js with middleware
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT with Firebase Admin SDK
- **Offline Sync**: Dexie.js synchronization
- **File Storage**: Multer for uploads

### Database
- **Primary**: PostgreSQL for cloud storage
- **Offline**: IndexedDB via Dexie.js
- **Sync**: Bidirectional synchronization

## 🔧 Development

### Backend Development
```bash
cd backend
npm run dev          # Development with nodemon
npm run build        # Build TypeScript
npm run start        # Production server
npm run db:generate  # Generate Prisma client
npm run db:push      # Push schema changes
npm run db:migrate   # Run migrations
npm run db:studio    # Open Prisma Studio
```

### Frontend Development
```bash
cd frontend
flutter pub get      # Install dependencies
flutter run          # Run on connected device
flutter build web    # Build for web
flutter build apk    # Build Android APK
flutter build ios    # Build iOS app
```

### Docker Development
```bash
docker-compose up -d  # Start all services
docker-compose down   # Stop all services
```

## 📱 Features

- ✅ **Animal Management**: Track livestock with detailed profiles
- ✅ **Health Monitoring**: Vaccination and treatment records
- ✅ **Offline-First**: Works without internet connection
- ✅ **Data Synchronization**: Automatic sync when online
- ✅ **Dashboard Analytics**: Real-time insights and reports
- ✅ **Multi-Platform**: iOS, Android, and Web support
- ✅ **Secure Authentication**: Firebase Auth integration
- ✅ **File Uploads**: Image and document management
- ✅ **RESTful API**: Well-documented endpoints

## 🌐 API Documentation

### Base URL
- **Development**: `http://localhost:3000`
- **Production**: Configure in environment variables

### Authentication
All API endpoints require JWT authentication except `/api/auth/*`.

### Key Endpoints
- `POST /api/auth/login` - User authentication
- `GET /api/animals` - List animals
- `POST /api/animals` - Create animal
- `GET /api/dashboard/stats` - Dashboard statistics
- `POST /api/sync` - Data synchronization

## 🔐 Environment Variables

### Backend (.env)
```env
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5432/atahbracah
JWT_SECRET=your-secret-key
FIREBASE_PROJECT_ID=your-project-id
```

### Frontend (Firebase Config)
Update `frontend/lib/firebase_options.dart` with your Firebase configuration.

## 🚀 Deployment

### Backend Deployment
```bash
cd backend
npm run build
npm run start
```

### Frontend Deployment
```bash
cd frontend
flutter build web --release
# Deploy dist/ folder to web server
```

### Docker Deployment
```bash
docker-compose -f docker-compose.yml up -d
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## 📄 License

ISC License - see LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Contact the development team

---

**Built with ❤️ for livestock farmers worldwide**

### Flutter App Features
- 📱 Mobile-first UI design
- 🔐 Firebase Authentication (Email, Google, Phone)
- 📊 Animal management dashboard
- 📝 Feeding logs and health records
- 🔄 Offline-first data storage
- 🌐 Real-time sync with backend

## Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL 12+
- npm or yarn

### Installation

1. **Clone and install dependencies**
```bash
git clone <repository-url>
cd animal-management-system
npm install
```

2. **Environment setup**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Database setup**
```bash
# Generate Prisma client
npm run db:generate

# Run database migrations
npm run db:migrate

# (Optional) Open Prisma Studio
npm run db:studio
```

4. **Start development server**
```bash
npm run dev
```

5. **Build for production**
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
- `PUT /api/auth/password` - Change password
- `POST /api/auth/logout` - User logout
- `GET /api/auth/offline` - Get offline cached user
- `GET /api/auth/status` - Check online status

### Farm Management
- `POST /api/farm/setup` - Create/setup farm
- `GET /api/farm` - Get user farms
- `GET /api/farm/:id` - Get farm by ID
- `PUT /api/farm/:id` - Update farm
- `DELETE /api/farm/:id` - Delete farm
- `GET /api/farm/:id/animals` - Get farm animals
- `GET /api/farm/:id/stats` - Get farm statistics

### Animal Management
- `POST /api/animals` - Create animal
- `GET /api/animals` - List animals
- `GET /api/animals/:id` - Get animal by ID
- `PUT /api/animals/:id` - Update animal
- `DELETE /api/animals/:id` - Delete animal

### Feeding Logs
- `POST /api/animals/:id/feeding` - Add feeding record
- `GET /api/animals/:id/feeding` - Get feeding records

### Gestation Tracking
- `POST /api/animals/:id/gestation` - Start gestation cycle
- `GET /api/animals/:id/gestation` - Get gestation history

### Treatment Records
- `POST /api/animals/:id/treatment` - Add treatment record
- `GET /api/animals/:id/treatment` - Get treatment history

### Daily Activities
- `POST /api/animals/:id/activity` - Add daily log
- `GET /api/animals/:id/activity` - Get daily logs

## Configuration

### Environment Variables
```env
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/animal_management

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# File Uploads
UPLOAD_DIR=./src/public/uploads
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,video/mp4,video/webm

# Sync
SYNC_INTERVAL=30000
MAX_RETRY_ATTEMPTS=3

# External Services
WHATSAPP_API_KEY=your-whatsapp-api-key
IP_CAMERA_URLS=http://camera1.local/stream,http://camera2.local/stream
```

## Animal Types Supported

- **DOG** - Dogs and puppies
- **CAT** - Cats and kittens  
- **CATTLE** - Cows, bulls, calves
- **CHICKEN** - Chickens, roosters
- **GOAT** - Goats and kids
- **SHEEP** - Sheep and lambs
- **PIG** - Pigs and piglets
- **RABBIT** - Rabbits and bunnies
- **FISH** - Fish and aquatic animals
- **HORSE** - Horses, ponies, foals

## Sync System

The system uses a sophisticated sync mechanism:

1. **Local First**: All operations are saved to Dexie (IndexedDB) immediately
2. **Background Sync**: Changes are automatically synced to PostgreSQL
3. **Conflict Resolution**: Automatic conflict detection and resolution
4. **Offline Support**: Full functionality available without internet
5. **Recovery**: Automatic retry mechanism for failed syncs

## File Upload

- **Photos**: JPEG, PNG, GIF (max 10MB)
- **Videos**: MP4, WebM (max 10MB)
- **Storage**: Local storage with optional cloud sync
- **Processing**: Automatic image optimization

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-Based Access**: FARMER and ADMIN roles
- **Input Validation**: Zod schema validation
- **File Security**: Type and size validation
- **CORS Protection**: Configurable CORS policies
- **Helmet**: Security headers protection

## Development

### Scripts
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run db:generate  # Generate Prisma client
npm run db:migrate    # Run database migrations
npm run db:studio    # Open Prisma Studio
```

### Database Schema
The system uses two databases:
1. **Dexie (IndexedDB)** - Client-side, offline-first
2. **PostgreSQL** - Server-side, backup and sync

Both schemas are identical for seamless synchronization.

## Production Deployment

### Docker Support
```bash
# Build image
docker build -t animal-management-system .

# Run container
docker run -p 3000:3000 --env-file .env animal-management-system
```

### Environment Setup
1. Set `NODE_ENV=production`
2. Configure secure `JWT_SECRET`
3. Set up PostgreSQL database
4. Configure file storage
5. Set up reverse proxy (nginx)

## Monitoring

### Health Check
- `GET /health` - System health status

### Sync Status
- `GET /api/sync/status` - Sync system status
- `POST /api/sync/force` - Force full sync

## Contributing

1. Fork the repository
2. Create feature branch
3. Make your changes
4. Add tests
5. Submit pull request

## License

ISC License - Feel free to use in commercial projects

## Support

For issues and questions:
- Create GitHub issue
- Check documentation
- Review API endpoints

---

**Built with ❤️ for farmers and animal managers**
