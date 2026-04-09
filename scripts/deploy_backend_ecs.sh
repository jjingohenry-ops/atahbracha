#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPOSITORY="${ECR_REPOSITORY:-atahbracha-api}"
ECS_CLUSTER="${ECS_CLUSTER:-atahbracha-prod}"
ECS_SERVICE="${ECS_SERVICE:-atahbracha-api}"
ECS_TASK_FAMILY="${ECS_TASK_FAMILY:-atahbracha-api}"
ECS_CONTAINER_NAME="${ECS_CONTAINER_NAME:-api}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"

if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS=(aws --profile "$AWS_PROFILE" --region "$AWS_REGION")
else
  AWS=(aws --region "$AWS_REGION")
fi

echo "[1/8] Resolve AWS account"
ACCOUNT_ID="$(${AWS[@]} sts get-caller-identity --query Account --output text)"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "[2/8] Ensure ECR repository exists"
if ! "${AWS[@]}" ecr describe-repositories --repository-names "$ECR_REPOSITORY" >/dev/null 2>&1; then
  "${AWS[@]}" ecr create-repository --repository-name "$ECR_REPOSITORY" >/dev/null
fi

echo "[3/8] Login to ECR"
"${AWS[@]}" ecr get-login-password | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "[4/8] Build and tag backend image"
docker build -t "${ECR_REPOSITORY}:latest" .
docker tag "${ECR_REPOSITORY}:latest" "${ECR_URI}:latest"
docker tag "${ECR_REPOSITORY}:latest" "${ECR_URI}:${IMAGE_TAG}"

echo "[5/8] Push image tags"
docker push "${ECR_URI}:latest"
docker push "${ECR_URI}:${IMAGE_TAG}"

echo "[6/8] Fetch current task definition"
"${AWS[@]}" ecs describe-task-definition --task-definition "$ECS_TASK_FAMILY" --query taskDefinition > /tmp/task-definition.json
jq 'del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)' /tmp/task-definition.json > /tmp/task-definition-clean.json
jq --arg IMAGE "${ECR_URI}:${IMAGE_TAG}" --arg NAME "$ECS_CONTAINER_NAME" '
  .containerDefinitions |= map(if .name == $NAME then .image = $IMAGE else . end)
' /tmp/task-definition-clean.json > /tmp/task-definition-updated.json

echo "[7/8] Register new task definition revision"
NEW_TASK_DEF_ARN="$(${AWS[@]} ecs register-task-definition --cli-input-json file:///tmp/task-definition-updated.json --query 'taskDefinition.taskDefinitionArn' --output text)"

echo "[8/8] Deploy to ECS service"
"${AWS[@]}" ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --task-definition "$NEW_TASK_DEF_ARN" --force-new-deployment >/dev/null
"${AWS[@]}" ecs wait services-stable --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE"

echo "ECS deployment complete"
echo "Image: ${ECR_URI}:${IMAGE_TAG}"
echo "Task definition: ${NEW_TASK_DEF_ARN}"
