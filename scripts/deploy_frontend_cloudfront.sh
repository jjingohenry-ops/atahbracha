#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
FRONTEND_BUCKET="${FRONTEND_BUCKET:-}"
CLOUDFRONT_DISTRIBUTION_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"

if [[ -z "$FRONTEND_BUCKET" || -z "$CLOUDFRONT_DISTRIBUTION_ID" ]]; then
  echo "Usage: FRONTEND_BUCKET=<bucket> CLOUDFRONT_DISTRIBUTION_ID=<id> [AWS_PROFILE=...] ./scripts/deploy_frontend_cloudfront.sh"
  exit 1
fi

if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS=(aws --profile "$AWS_PROFILE" --region "$AWS_REGION")
else
  AWS=(aws --region "$AWS_REGION")
fi

echo "[1/4] Building Flutter web"
pushd frontend >/dev/null
flutter pub get
flutter build web --release
popd >/dev/null

echo "[2/4] Syncing build to S3 bucket: s3://${FRONTEND_BUCKET}"
"${AWS[@]}" s3 sync frontend/build/web/ "s3://${FRONTEND_BUCKET}/" --delete

echo "[3/4] Creating CloudFront invalidation"
INVALIDATION_ID="$(${AWS[@]} cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" --paths "/*" --query 'Invalidation.Id' --output text)"

echo "[4/4] Deployment submitted"
echo "Invalidation ID: ${INVALIDATION_ID}"
echo "Monitor status in CloudFront console or with:"
echo "aws cloudfront get-invalidation --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} --id ${INVALIDATION_ID}"
