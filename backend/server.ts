import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import path from 'path';
import { config } from './src/config/env';
import { authRoutes } from './src/modules/auth/authRoutes';
import { dashboardRoutes } from './src/modules/dashboard/dashboardRoutes';
import { farmRoutes } from './src/modules/farm/farmRoutes';
import { animalRoutes } from './src/modules/animal/animalRoutes';
import { remindersRoutes } from './src/modules/treatment/treatmentRoutes';
import { aiRoutes } from './src/modules/ai/aiRoutes';
import { chatRoutes } from './src/modules/chat/chatRoutes';
// import { syncService } from './src/modules/sync/syncService'; // Sync service uses Dexie (browser-only), not compatible with Node.js backend

const app = express();

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: config.CORS_ORIGIN,
  credentials: true
}));

// Compression middleware
app.use(compression());

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
if (config.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Static file serving
app.use('/uploads', express.static(path.join(__dirname, '../src/public/uploads')));
app.use('/images', express.static(path.join(__dirname, '../src/public/images')));

// Health check endpoint
app.get('/health', (_req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.NODE_ENV
  });
});

// Frontend pages
app.get('/dashboard', (_req, res) => {
  res.sendFile(path.join(__dirname, '../src/public/dashboard.html'));
});

app.get('/register-animal', (_req, res) => {
  res.sendFile(path.join(__dirname, '../src/public/register-animal.html'));
});

app.get('/marketing', (_req, res) => {
  res.sendFile(path.join(__dirname, '../src/public/marketing.html'));
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/farms', farmRoutes);
app.use('/api/animals', animalRoutes);
app.use('/api/reminders', remindersRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/chat', chatRoutes);

// 404 handler
app.use((req, res, next) => {
  if (req.path.startsWith('/api/')) {
    return next();
  }

  if (req.path.startsWith('/uploads/') || req.path.startsWith('/images/')) {
    return res.status(404).json({
      success: false,
      error: 'File not found'
    });
  }

  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Global error handler
app.use((_err: any, _req: express.Request, res: express.Response, _next: express.NextFunction): void => {
  console.error('Global error handler:', _err);

  if (_err.name === 'ValidationError') {
    res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: _err.details
    });
    return;
  }

  if (_err.name === 'UnauthorizedError') {
    res.status(401).json({
      success: false,
      error: 'Unauthorized'
    });
    return;
  }

  if (_err.code === 'LIMIT_FILE_SIZE') {
    res.status(413).json({
      success: false,
      error: 'File too large'
    });
    return;
  }

  res.status(_err.status || 500).json({
    success: false,
    error: config.NODE_ENV === 'production' ? 'Internal server error' : _err.message
  });
});

// Start sync service if enabled
// Sync service is for Flutter client app only, not needed on Node.js backend
// if (config.SYNC_INTERVAL > 0) {
//   syncService.startAutoSync(config.SYNC_INTERVAL);
//   console.log(`Auto-sync started with ${config.SYNC_INTERVAL}ms interval`);
// }

const PORT = config.PORT || 3000;
app.listen(PORT, () => {
  console.log('🚀 Smart Livestock Backend Server running on port', PORT);
  console.log('📝 Environment:', config.NODE_ENV);
  console.log('🔗 Health check: http://localhost:' + PORT + '/health');
  console.log('🔐 Auth endpoint: http://localhost:' + PORT + '/api/auth');
});

export { app };
