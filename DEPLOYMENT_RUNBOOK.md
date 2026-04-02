# Atahbracha Production Runbook

This runbook is the minimum path to deploy safely to atahbracha.com.

## 1. Required Environment Variables

Set these on the backend runtime:

- NODE_ENV=production
- PORT=3000
- DATABASE_URL=postgresql://... (production DB)
- JWT_SECRET=<long-random-secret>
- CORS_ORIGIN=https://atahbracha.com
- FIREBASE_PROJECT_ID
- FIREBASE_PRIVATE_KEY_ID
- FIREBASE_PRIVATE_KEY
- FIREBASE_CLIENT_EMAIL
- FIREBASE_CLIENT_ID
- FIREBASE_CLIENT_X509_CERT_URL

Optional for AI and media:

- AWS_REGION
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_SESSION_TOKEN
- BEDROCK_USE_ENV_CREDENTIALS
- BEDROCK_MODEL_ID
- AWS_S3_BUCKET
- AWS_CLOUDFRONT_URL

## 2. Pre-Release Gate

From repository root run:

```bash
npm run release:check
```

This performs:

- backend build
- backend smoke test (/health)
- frontend release web build

Do not deploy if this command fails.

## 3. Database

Before first release of new code:

```bash
cd backend
npx prisma migrate deploy
```

Verify migration status:

```bash
npx prisma migrate status
```

## 4. Build and Deploy

### Backend container (from repo root)

```bash
docker build -t atahbracha-api:latest .
```

### Compose deployment

```bash
docker compose up -d postgres redis app
```

## 5. Post-Deploy Validation

- Health endpoint: GET /health returns status OK
- Auth flow: signup/login on atahbracha.com
- Dashboard load and quick actions create records
- Reminders can be completed
- Chat request/accept/send works
- AI chat endpoint responds within expected quota limits

## 6. Rollback Plan

- Keep previous stable image tag
- Revert app service to previous tag
- Re-run smoke check on restored version
- If migration introduced breakage, restore DB from backup taken before migration
