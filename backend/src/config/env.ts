import * as dotenv from 'dotenv';

dotenv.config();
dotenv.config({ path: '.env.local', override: true });

const config = {
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

  // AWS Bedrock (AI Chat)
  AWS_REGION: process.env['AWS_REGION'] || 'us-east-1',
  AWS_ACCESS_KEY_ID: process.env['AWS_ACCESS_KEY_ID'],
  AWS_SECRET_ACCESS_KEY: process.env['AWS_SECRET_ACCESS_KEY'],
  AWS_SESSION_TOKEN: process.env['AWS_SESSION_TOKEN'],
  BEDROCK_USE_ENV_CREDENTIALS: process.env['BEDROCK_USE_ENV_CREDENTIALS'] || 'false',
  BEDROCK_MODEL_ID: process.env['BEDROCK_MODEL_ID'] || 'anthropic.claude-3-5-haiku-20241022-v1:0',
  AWS_S3_BUCKET: process.env['AWS_S3_BUCKET'],
  AWS_CLOUDFRONT_URL: process.env['AWS_CLOUDFRONT_URL'],

  // CORS
  CORS_ORIGIN: process.env['CORS_ORIGIN'] || 'http://localhost:3000',
};

const validateProductionConfig = (): void => {
  if (config.NODE_ENV !== 'production') {
    return;
  }

  const missing: string[] = [];

  if (!process.env['DATABASE_URL']) {
    missing.push('DATABASE_URL');
  }

  if (!process.env['JWT_SECRET'] || process.env['JWT_SECRET'] === 'your-secret-key-change-in-production') {
    missing.push('JWT_SECRET');
  }

  if (!process.env['CORS_ORIGIN']) {
    missing.push('CORS_ORIGIN');
  }

  if (missing.length > 0) {
    throw new Error(
      `Missing required production environment variables: ${missing.join(', ')}`
    );
  }

  const corsOrigin = (process.env['CORS_ORIGIN'] || '').toLowerCase();
  if (corsOrigin.includes('localhost') || corsOrigin.includes('127.0.0.1')) {
    throw new Error('CORS_ORIGIN cannot point to localhost in production.');
  }
};

validateProductionConfig();

export { config };
