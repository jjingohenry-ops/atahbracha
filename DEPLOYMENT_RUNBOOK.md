# Atahbracha Production Runbook (ECS + CloudFront Auto Deploy)

This runbook deploys:

- Backend API on Amazon ECS (Fargate)
- Frontend static web on S3 + CloudFront
- Database on RDS PostgreSQL
- CI/CD on GitHub Actions (push to main auto-deploy)

This follows AWS guidance to prioritize ECS over App Runner for new deployments.

## 1. AWS Services In Use

- ECS Service (Fargate): runs backend container
- ECR: stores backend image
- S3: stores frontend build files
- CloudFront: serves frontend globally
- RDS PostgreSQL: backend database
- IAM: roles for ECS tasks and GitHub OIDC deploy role
- GitHub Actions: build + deploy pipelines

## 2. Where To Find Each Service In AWS Console

1. ECS service
   - AWS Console -> ECS -> Clusters -> `atahbracha-prod` -> Services -> `atahbracha-api`
2. ECR repository
   - AWS Console -> Elastic Container Registry -> Repositories -> `atahbracha-api`
3. Frontend bucket
   - AWS Console -> S3 -> Buckets -> your frontend bucket (example: `atahbracha-web-prod`)
4. CloudFront distribution
   - AWS Console -> CloudFront -> Distributions -> your distribution ID
5. Database
   - AWS Console -> RDS -> Databases -> production DB/cluster

## 3. Backend Environment Variables

Set these in ECS task definition container environment or secrets:

- NODE_ENV=production
- PORT=3000
- DATABASE_URL=postgresql://... (production RDS)
- JWT_SECRET=<long-random-secret>
- CORS_ORIGIN=https://atahbracha.com
- FIREBASE_PROJECT_ID
- FIREBASE_PRIVATE_KEY_ID
- FIREBASE_PRIVATE_KEY
- FIREBASE_CLIENT_EMAIL
- FIREBASE_CLIENT_ID
- FIREBASE_CLIENT_X509_CERT_URL

Optional:

- AWS_REGION
- BEDROCK_USE_ENV_CREDENTIALS
- BEDROCK_MODEL_ID
- AWS_S3_BUCKET
- AWS_CLOUDFRONT_URL

## 4. One-Time Setup Checklist

1. Create ECR repo for backend image.
2. Create ECS cluster and Fargate service (`atahbracha-prod` / `atahbracha-api`).
   - Container port: 3000
   - Health check path: /health (via target group / ALB)
   - Configure environment variables listed above.
3. Create S3 bucket for frontend hosting artifacts.
4. Create CloudFront distribution with S3 bucket origin.
5. Point domain DNS to CloudFront distribution.
6. Create GitHub OIDC IAM role for deployments.

## 5. GitHub Auto Deploy Setup

Create these repository variables (Settings -> Secrets and variables -> Actions -> Variables):

- AWS_REGION=us-east-1
- ECR_REPOSITORY=atahbracha-api
- ECS_CLUSTER=atahbracha-prod
- ECS_SERVICE=atahbracha-api
- ECS_TASK_FAMILY=atahbracha-api
- ECS_CONTAINER_NAME=api
- FRONTEND_BUCKET=<your-s3-bucket>
- CLOUDFRONT_DISTRIBUTION_ID=<your-distribution-id>

Create this repository secret:

- AWS_GITHUB_OIDC_ROLE_ARN=<iam-role-arn-for-github-actions>

Workflows:

- `.github/workflows/deploy-backend-ecs.yml`
- `.github/workflows/deploy-frontend-cloudfront.yml`

Both run on push to `main`. Backend deploys to ECS. Frontend deploys to S3 and invalidates CloudFront.

## 6. Pre-Release Gate

From repository root:

```bash
npm run release:check
```

Do not deploy if this fails.

## 7. Manual Deployment (Fallback)

### Backend (ECS)

Use script:

```bash
AWS_PROFILE=atahbracha-admin \
AWS_REGION=us-east-1 \
ECR_REPOSITORY=atahbracha-api \
ECS_CLUSTER=atahbracha-prod \
ECS_SERVICE=atahbracha-api \
ECS_TASK_FAMILY=atahbracha-api \
ECS_CONTAINER_NAME=api \
./scripts/deploy_backend_ecs.sh
```

What it does:

1. Builds backend Docker image from repo root Dockerfile.
2. Pushes image to ECR (`latest` and commit tag).
3. Updates ECS task definition and forces new ECS deployment.

### Frontend (S3 + CloudFront)

Use script:

```bash
AWS_PROFILE=atahbracha-admin \
AWS_REGION=us-east-1 \
FRONTEND_BUCKET=atahbracha-web-prod \
CLOUDFRONT_DISTRIBUTION_ID=E123456789ABC \
./scripts/deploy_frontend_cloudfront.sh
```

What it does:

1. Builds Flutter web (`frontend/build/web`).
2. Syncs files to S3 bucket.
3. Creates CloudFront invalidation (`/*`).

## 8. Post-Deploy Validation

1. ECS service status is `Stable`.
2. Backend health endpoint returns `{"status":"OK"...}`.
3. Frontend loads at `https://atahbracha.com`.
4. Login, dashboard, reminders, and graph data load correctly.

## 9. Troubleshooting Quick Guide

### ECS tasks are unhealthy

1. Check ECS -> Service -> Tasks -> stopped reason.
2. Check CloudWatch Logs for the service.
3. Confirm `/health` responds and `PORT=3000` is set.
4. Verify `DATABASE_URL` and Firebase env vars are valid.

### Deployment stuck on old backend image

1. Confirm latest workflow run succeeded in GitHub Actions.
2. Confirm ECR latest tag changed.
3. Confirm ECS service deployed newest task revision.

### Website still shows old frontend

1. Check CloudFront invalidation status is `Completed`.
2. Confirm new files exist in S3 bucket.
3. Hard refresh browser (`Cmd+Shift+R`).

## 10. Rollback

### Backend rollback (ECS)

1. Re-tag a previous known-good image in ECR as `latest`.
2. Re-run `./scripts/deploy_backend_ecs.sh`.

### Frontend rollback

1. Re-sync previous build artifacts to S3.
2. Create CloudFront invalidation again.
