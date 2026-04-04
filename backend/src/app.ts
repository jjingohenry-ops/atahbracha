import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import path from 'path';
import { config } from './config/env';
import { authRoutes } from './modules/auth/authRoutes';
// import { syncService } from './modules/sync/syncService'; // Sync service uses Dexie (browser-only), not compatible with Node.js backend
import { dashboardRoutes } from './modules/dashboard/dashboardRoutes';
import { farmRoutes } from './modules/farm/farmRoutes';
import { animalRoutes } from './modules/animal/animalRoutes';
import { remindersRoutes } from './modules/treatment/treatmentRoutes';
import { aiRoutes } from './modules/ai/aiRoutes';
import { chatRoutes } from './modules/chat/chatRoutes';
import { insuranceRoutes } from './modules/insurance/insuranceRoutes';
import { prescriptionRoutes } from './modules/prescription/prescriptionRoutes';

const app = express();

// Prevent stale API payloads due to browser ETag/304 behavior.
app.set('etag', false);

const shouldSkipRequestLog = (req: express.Request, res: express.Response): boolean => {
  const requestPath = req.path || req.originalUrl || '';

  if (res.statusCode === 304) {
    return true;
  }

  if (requestPath.startsWith('/api/chat/conversations')) {
    return true;
  }

  if (requestPath.startsWith('/api/auth/firebase')) {
    return true;
  }

  return false;
};

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: config.CORS_ORIGIN,
  credentials: true
}));

// Compression middleware
app.use(compression());

app.use('/api', (_req, res, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
});

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
if (config.NODE_ENV === 'development') {
  app.use(morgan('dev', { skip: shouldSkipRequestLog }));
} else {
  app.use(morgan('combined', { skip: shouldSkipRequestLog }));
}

// Static file serving
app.use('/uploads', express.static(path.join(__dirname, '../public/uploads')));
app.use('/images', express.static(path.join(__dirname, '../public/images')));

// Health check endpoint
app.get('/health', (_req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.NODE_ENV
  });
});

// Dashboard endpoint
app.get('/dashboard', (_req, res) => {
  res.sendFile(path.join(process.cwd(), 'src/public/dashboard.html'));
});

// Register animal endpoint
app.get('/register-animal', (_req, res) => {
  res.sendFile(path.join(process.cwd(), 'src/public/register-animal.html'));
});

// Marketing page endpoint
app.get('/marketing', (_req, res) => {
  res.sendFile(path.join(process.cwd(), 'src/public/marketing.html'));
});

console.log('🔧 Registering routes...');
console.log('remindersRoutes:', typeof remindersRoutes, remindersRoutes);

app.use('/api/auth', authRoutes);
console.log('✅ Auth routes registered');
app.use('/api/dashboard', dashboardRoutes);
console.log('✅ Dashboard routes registered');
app.use('/api/farms', farmRoutes);
console.log('✅ Farms routes registered');
app.use('/api/animals', animalRoutes);
console.log('✅ Animals routes registered');
app.use('/api/reminders', remindersRoutes);
console.log('✅ Reminders routes registered');
app.use('/api/ai', aiRoutes);
console.log('✅ AI routes registered');
app.use('/api/chat', chatRoutes);
console.log('✅ Chat routes registered');
app.use('/api/insurance', insuranceRoutes);
console.log('✅ Insurance routes registered');
app.use('/api/prescriptions', prescriptionRoutes);
console.log('✅ Prescription routes registered');

// Global error handler
app.use((_err: any, _req: express.Request, res: express.Response, _next: express.NextFunction): void => {
  console.error('Global error handler:', _err);

  // Handle specific error types
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

  // Default error response
  res.status(_err.status || 500).json({
    success: false,
    error: config.NODE_ENV === 'production' ? 'Internal server error' : _err.message
  });
});

// 404 handler - catch all non-API routes
app.use((req, res, next) => {
  // Skip API routes
  if (req.path.startsWith('/api/')) {
    return next();
  }

  // Handle static file routes that might not exist
  if (req.path.startsWith('/uploads/') || req.path.startsWith('/images/')) {
    return res.status(404).json({
      success: false,
      error: 'File not found'
    });
  }

  // Handle other routes
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Start sync service if enabled
// Sync service is for Flutter client app only, not needed on Node.js backend
// if (config.SYNC_INTERVAL > 0) {
//   syncService.startAutoSync(config.SYNC_INTERVAL);
//   console.log(`Auto-sync started with ${config.SYNC_INTERVAL}ms interval`);
// }

export { app };
