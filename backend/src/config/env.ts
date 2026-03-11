import * as dotenv from 'dotenv';

dotenv.config();

export const config = {
  // Server
  PORT: process.env['PORT'] || 3000,
  NODE_ENV: process.env['NODE_ENV'] || 'development',

  // Database
  DATABASE_URL: process.env['DATABASE_URL'] || 'postgresql://user:password@localhost:5432/animal_management',

  // JWT
  JWT_SECRET: process.env['JWT_SECRET'] || 'your-secret-key-change-in-production',
  JWT_EXPIRES_IN: process.env['JWT_EXPIRES_IN'] || '7d',

  // File Upload
  UPLOAD_DIR: process.env['UPLOAD_DIR'] || './src/public/uploads',
  MAX_FILE_SIZE: parseInt(process.env['MAX_FILE_SIZE'] || '10485760'), // 10MB
  ALLOWED_FILE_TYPES: process.env['ALLOWED_FILE_TYPES'] || 'image/jpeg,image/png,image/gif,video/mp4,video/webm',

  // Sync
  SYNC_INTERVAL: parseInt(process.env['SYNC_INTERVAL'] || '30000'), // 30 seconds
  MAX_RETRY_ATTEMPTS: parseInt(process.env['MAX_RETRY_ATTEMPTS'] || '3'),

  // External Services
  WHATSAPP_API_KEY: process.env['WHATSAPP_API_KEY'],
  IP_CAMERA_URLS: process.env['IP_CAMERA_URLS']?.split(',') || [],

  // CORS
  CORS_ORIGIN: process.env['CORS_ORIGIN'] || 'http://localhost:3000',
};
