const { spawn } = require('node:child_process');
const { generateKeyPairSync } = require('node:crypto');
const { setTimeout: delay } = require('node:timers/promises');

const PORT = process.env.SMOKE_PORT || '3101';
const BASE_URL = `http://127.0.0.1:${PORT}`;

function createEphemeralPrivateKey() {
  const { privateKey } = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    privateKeyEncoding: {
      type: 'pkcs8',
      format: 'pem',
    },
    publicKeyEncoding: {
      type: 'spki',
      format: 'pem',
    },
  });

  return privateKey;
}

async function waitForHealth(timeoutMs = 15000) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    try {
      const res = await fetch(`${BASE_URL}/health`);
      if (res.ok) {
        const body = await res.json();
        if (body && body.status === 'OK') {
          return;
        }
      }
    } catch (_) {
      // Server not ready yet.
    }

    await delay(500);
  }

  throw new Error(`Health check did not pass within ${timeoutMs}ms`);
}

async function run() {
  const smokePrivateKey = createEphemeralPrivateKey();

  const child = spawn('node', ['dist/server.js'], {
    stdio: ['ignore', 'pipe', 'pipe'],
    env: {
      ...process.env,
      NODE_ENV: 'production',
      PORT,
      CORS_ORIGIN: process.env.CORS_ORIGIN || 'https://atahbracha.com',
      JWT_SECRET: process.env.JWT_SECRET || 'smoke-test-jwt-secret-not-for-production',
      DATABASE_URL:
        process.env.DATABASE_URL ||
        'postgresql://user:password@localhost:5432/animal_management',
      FIREBASE_PROJECT_ID: 'smoke-project',
      FIREBASE_PRIVATE_KEY_ID: 'smoke-key-id',
      FIREBASE_PRIVATE_KEY: smokePrivateKey,
      FIREBASE_CLIENT_EMAIL: 'firebase-adminsdk-smoke@smoke-project.iam.gserviceaccount.com',
      FIREBASE_CLIENT_ID: 'smoke-client-id',
      FIREBASE_CLIENT_X509_CERT_URL:
        'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-smoke%40smoke-project.iam.gserviceaccount.com',
    },
  });

  let stderr = '';

  child.stdout.on('data', (chunk) => {
    process.stdout.write(chunk);
  });

  child.stderr.on('data', (chunk) => {
    const text = chunk.toString();
    stderr += text;
    process.stderr.write(chunk);
  });

  try {
    await waitForHealth();
    console.log('\nSmoke test passed: /health responded with status OK');
  } finally {
    child.kill('SIGTERM');
    await delay(500);
    if (!child.killed) {
      child.kill('SIGKILL');
    }
  }

  if (stderr.toLowerCase().includes('error')) {
    console.warn('\nSmoke test warning: startup logged error output. Review logs above.');
  }
}

run().catch((error) => {
  console.error(`\nSmoke test failed: ${error.message}`);
  process.exit(1);
});
