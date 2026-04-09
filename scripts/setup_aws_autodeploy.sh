#!/usr/bin/env bash
set -euo pipefail

PROFILE="${AWS_PROFILE:-atahbracha-admin}"
REGION="${AWS_REGION:-us-east-1}"
REPO_SLUG="${GITHUB_REPO:-jjingohenry-ops/atahbracha}"

ECR_REPO="${ECR_REPOSITORY:-atahbracha-api}"
ECS_CLUSTER="${ECS_CLUSTER:-atahbracha-prod}"
ECS_SERVICE="${ECS_SERVICE:-atahbracha-api}"
ECS_TASK_FAMILY="${ECS_TASK_FAMILY:-atahbracha-api}"
ECS_CONTAINER_NAME="${ECS_CONTAINER_NAME:-api}"

ALB_NAME="${ALB_NAME:-atahbracha-alb}"
TG_NAME="${TG_NAME:-atahbracha-api-tg}"
ALB_SG_NAME="${ALB_SG_NAME:-atahbracha-alb-sg}"
ECS_SG_NAME="${ECS_SG_NAME:-atahbracha-ecs-service-sg}"

EXEC_ROLE="${ECS_EXEC_ROLE_NAME:-ecsTaskExecutionRole}"
TASK_ROLE="${ECS_TASK_ROLE_NAME:-atahbrachaEcsTaskRoleV2}"
OIDC_ROLE="${OIDC_ROLE_NAME:-atahbracha-github-actions-deploy-role}"

AWS=(aws --profile "$PROFILE" --region "$REGION")

echo "== SSO login =="
"${AWS[@]}" sso login >/dev/null
ACCOUNT_ID="$(${AWS[@]} sts get-caller-identity --query Account --output text)"
echo "Account: $ACCOUNT_ID"

ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO"
FRONTEND_BUCKET="${FRONTEND_BUCKET:-atahbracha-web-prod-$ACCOUNT_ID}"

echo "== ECR =="
"${AWS[@]}" ecr describe-repositories --repository-names "$ECR_REPO" >/dev/null 2>&1 || \
  "${AWS[@]}" ecr create-repository --repository-name "$ECR_REPO" >/dev/null

echo "== IAM ECS roles =="
TRUST_DOC=$(mktemp)
cat > "$TRUST_DOC" <<EOF
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF

"${AWS[@]}" iam get-role --role-name "$EXEC_ROLE" >/dev/null 2>&1 || \
  "${AWS[@]}" iam create-role --role-name "$EXEC_ROLE" --assume-role-policy-document "file://$TRUST_DOC" >/dev/null
"${AWS[@]}" iam update-assume-role-policy --role-name "$EXEC_ROLE" --policy-document "file://$TRUST_DOC" >/dev/null
"${AWS[@]}" iam attach-role-policy --role-name "$EXEC_ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy >/dev/null

"${AWS[@]}" iam get-role --role-name "$TASK_ROLE" >/dev/null 2>&1 || \
  "${AWS[@]}" iam create-role --role-name "$TASK_ROLE" --assume-role-policy-document "file://$TRUST_DOC" >/dev/null
"${AWS[@]}" iam update-assume-role-policy --role-name "$TASK_ROLE" --policy-document "file://$TRUST_DOC" >/dev/null

echo "== CloudWatch log group =="
"${AWS[@]}" logs create-log-group --log-group-name /ecs/atahbracha-api >/dev/null 2>&1 || true

echo "== ECS cluster =="
"${AWS[@]}" ecs describe-clusters --clusters "$ECS_CLUSTER" --query 'clusters[0].clusterName' --output text | grep -q "$ECS_CLUSTER" || \
  "${AWS[@]}" ecs create-cluster --cluster-name "$ECS_CLUSTER" >/dev/null

echo "== ECS task definition =="
TASKDEF=$(mktemp)
jq -n \
  --arg family "$ECS_TASK_FAMILY" \
  --arg execRole "arn:aws:iam::$ACCOUNT_ID:role/$EXEC_ROLE" \
  --arg taskRole "arn:aws:iam::$ACCOUNT_ID:role/$TASK_ROLE" \
  --arg image "$ECR_URI:latest" \
  '{family:$family,networkMode:"awsvpc",requiresCompatibilities:["FARGATE"],cpu:"512",memory:"1024",executionRoleArn:$execRole,taskRoleArn:$taskRole,containerDefinitions:[{name:"api",image:$image,essential:true,portMappings:[{containerPort:3000,protocol:"tcp"}],environment:[{name:"NODE_ENV",value:"production"},{name:"PORT",value:"3000"},{name:"CORS_ORIGIN",value:"https://atahbracha.com"}],logConfiguration:{logDriver:"awslogs",options:{"awslogs-group":"/ecs/atahbracha-api","awslogs-region":"us-east-1","awslogs-stream-prefix":"ecs"}}}]}' > "$TASKDEF"
"${AWS[@]}" ecs register-task-definition --cli-input-json "file://$TASKDEF" >/dev/null
LATEST_TD="$(${AWS[@]} ecs list-task-definitions --family-prefix "$ECS_TASK_FAMILY" --sort DESC --query 'taskDefinitionArns[0]' --output text | head -n 1)"
if [[ -z "$LATEST_TD" || "$LATEST_TD" == "None" ]]; then
  echo "ERROR: Could not resolve latest task definition ARN for family $ECS_TASK_FAMILY"
  exit 1
fi

echo "== Networking + ALB =="
VPC_ID="$(${AWS[@]} ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"
read -r SUBNET1 SUBNET2 < <("${AWS[@]}" ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" Name=default-for-az,Values=true --query 'Subnets[0:2].SubnetId' --output text)

ALB_SG_ID="$(${AWS[@]} ec2 create-security-group --group-name "$ALB_SG_NAME" --description 'ALB SG' --vpc-id "$VPC_ID" --query GroupId --output text 2>/dev/null || ${AWS[*]} ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$ALB_SG_NAME --query 'SecurityGroups[0].GroupId' --output text)"
"${AWS[@]}" ec2 authorize-security-group-ingress --group-id "$ALB_SG_ID" --ip-permissions '[{"IpProtocol":"tcp","FromPort":80,"ToPort":80,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]},{"IpProtocol":"tcp","FromPort":443,"ToPort":443,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}]' >/dev/null 2>&1 || true

ECS_SG_ID="$(${AWS[@]} ec2 create-security-group --group-name "$ECS_SG_NAME" --description 'ECS SG' --vpc-id "$VPC_ID" --query GroupId --output text 2>/dev/null || ${AWS[*]} ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$ECS_SG_NAME --query 'SecurityGroups[0].GroupId' --output text)"
"${AWS[@]}" ec2 authorize-security-group-ingress --group-id "$ECS_SG_ID" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":3000,\"ToPort\":3000,\"UserIdGroupPairs\":[{\"GroupId\":\"$ALB_SG_ID\"}]}]" >/dev/null 2>&1 || true

LB_ARN="$(${AWS[@]} elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)"
if [[ -z "$LB_ARN" || "$LB_ARN" == "None" ]]; then
  LB_ARN="$(${AWS[@]} elbv2 create-load-balancer --name "$ALB_NAME" --type application --scheme internet-facing --security-groups "$ALB_SG_ID" --subnets "$SUBNET1" "$SUBNET2" --query 'LoadBalancers[0].LoadBalancerArn' --output text)"
fi

TG_ARN="$(${AWS[@]} elbv2 describe-target-groups --names "$TG_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)"
if [[ -z "$TG_ARN" || "$TG_ARN" == "None" ]]; then
  TG_ARN="$(${AWS[@]} elbv2 create-target-group --name "$TG_NAME" --protocol HTTP --port 3000 --target-type ip --vpc-id "$VPC_ID" --health-check-protocol HTTP --health-check-path /health --query 'TargetGroups[0].TargetGroupArn' --output text)"
fi

LISTENER_ARN="$(${AWS[@]} elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text)"
if [[ -z "$LISTENER_ARN" || "$LISTENER_ARN" == "None" ]]; then
  "${AWS[@]}" elbv2 create-listener --load-balancer-arn "$LB_ARN" --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn="$TG_ARN" >/dev/null
fi

echo "== ECS service =="
SERVICE_STATUS="$(${AWS[@]} ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --query 'services[0].status' --output text 2>/dev/null || true)"
if [[ "$SERVICE_STATUS" == "ACTIVE" ]]; then
  "${AWS[@]}" ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --task-definition "$LATEST_TD" --force-new-deployment >/dev/null
else
  "${AWS[@]}" ecs create-service --cluster "$ECS_CLUSTER" --service-name "$ECS_SERVICE" --task-definition "$LATEST_TD" --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" --load-balancers "targetGroupArn=$TG_ARN,containerName=api,containerPort=3000" >/dev/null
fi

echo "== S3 + CloudFront =="
"${AWS[@]}" s3api head-bucket --bucket "$FRONTEND_BUCKET" >/dev/null 2>&1 || "${AWS[@]}" s3api create-bucket --bucket "$FRONTEND_BUCKET" >/dev/null
"${AWS[@]}" s3api put-public-access-block --bucket "$FRONTEND_BUCKET" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null

OAC_ID="$(${AWS[@]} cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='atahbracha-web-oac'].Id | [0]" --output text)"
if [[ -z "$OAC_ID" || "$OAC_ID" == "None" ]]; then
  OAC_CFG=$(mktemp)
  jq -n '{Name:"atahbracha-web-oac",Description:"OAC for atahbracha frontend",SigningProtocol:"sigv4",SigningBehavior:"always",OriginAccessControlOriginType:"s3"}' > "$OAC_CFG"
  OAC_ID="$(${AWS[@]} cloudfront create-origin-access-control --origin-access-control-config file://$OAC_CFG --query 'OriginAccessControl.Id' --output text)"
fi

DIST_ID="$(${AWS[@]} cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[0].DomainName=='$FRONTEND_BUCKET.s3.$REGION.amazonaws.com'].Id | [0]" --output text)"
if [[ -z "$DIST_ID" || "$DIST_ID" == "None" ]]; then
  DIST_CFG=$(mktemp)
  CALLER="atah-$(date +%s)"
  jq -n --arg caller "$CALLER" --arg origin "$FRONTEND_BUCKET.s3.$REGION.amazonaws.com" --arg oac "$OAC_ID" '{CallerReference:$caller,Comment:"atahbracha frontend",Enabled:true,DefaultRootObject:"index.html",Origins:{Quantity:1,Items:[{Id:"s3-origin",DomainName:$origin,S3OriginConfig:{OriginAccessIdentity:""},OriginAccessControlId:$oac}]},DefaultCacheBehavior:{TargetOriginId:"s3-origin",ViewerProtocolPolicy:"redirect-to-https",AllowedMethods:{Quantity:2,Items:["GET","HEAD"],CachedMethods:{Quantity:2,Items:["GET","HEAD"]}},Compress:true,ForwardedValues:{QueryString:false,Cookies:{Forward:"none"},Headers:{Quantity:0},QueryStringCacheKeys:{Quantity:0}},MinTTL:0},CustomErrorResponses:{Quantity:2,Items:[{ErrorCode:403,ResponsePagePath:"/index.html",ResponseCode:"200",ErrorCachingMinTTL:0},{ErrorCode:404,ResponsePagePath:"/index.html",ResponseCode:"200",ErrorCachingMinTTL:0}]},PriceClass:"PriceClass_100",ViewerCertificate:{CloudFrontDefaultCertificate:true},Restrictions:{GeoRestriction:{RestrictionType:"none",Quantity:0}}}' > "$DIST_CFG"
  DIST_ID="$(${AWS[@]} cloudfront create-distribution --distribution-config file://$DIST_CFG --query 'Distribution.Id' --output text)"
fi

DIST_ARN="arn:aws:cloudfront::$ACCOUNT_ID:distribution/$DIST_ID"
BUCKET_POLICY=$(mktemp)
jq -n --arg bucket "$FRONTEND_BUCKET" --arg distArn "$DIST_ARN" '{Version:"2012-10-17",Statement:[{Sid:"AllowCloudFrontServicePrincipalReadOnly",Effect:"Allow",Principal:{Service:"cloudfront.amazonaws.com"},Action:["s3:GetObject"],Resource:["arn:aws:s3:::\($bucket)/*"],Condition:{StringEquals:{"AWS:SourceArn":$distArn}}}]}' > "$BUCKET_POLICY"
"${AWS[@]}" s3api put-bucket-policy --bucket "$FRONTEND_BUCKET" --policy "file://$BUCKET_POLICY" >/dev/null

echo "== GitHub OIDC role =="
OIDC_ARN="$(${AWS[@]} iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text | tr '\t' '\n' | grep token.actions.githubusercontent.com || true)"
if [[ -z "$OIDC_ARN" ]]; then
  OIDC_ARN="$(${AWS[@]} iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 --query 'OpenIDConnectProviderArn' --output text)"
fi

GITHUB_TRUST=$(mktemp)
cat > "$GITHUB_TRUST" <<EOF
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Federated":"$OIDC_ARN"},"Action":"sts:AssumeRoleWithWebIdentity","Condition":{"StringEquals":{"token.actions.githubusercontent.com:aud":"sts.amazonaws.com"},"StringLike":{"token.actions.githubusercontent.com:sub":"repo:$REPO_SLUG:ref:refs/heads/main"}}}]}
EOF

"${AWS[@]}" iam get-role --role-name "$OIDC_ROLE" >/dev/null 2>&1 || "${AWS[@]}" iam create-role --role-name "$OIDC_ROLE" --assume-role-policy-document "file://$GITHUB_TRUST" >/dev/null
"${AWS[@]}" iam update-assume-role-policy --role-name "$OIDC_ROLE" --policy-document "file://$GITHUB_TRUST" >/dev/null

GH_POLICY=$(mktemp)
cat > "$GH_POLICY" <<EOF
{"Version":"2012-10-17","Statement":[
 {"Effect":"Allow","Action":["ecr:GetAuthorizationToken"],"Resource":"*"},
 {"Effect":"Allow","Action":["ecr:BatchCheckLayerAvailability","ecr:CompleteLayerUpload","ecr:InitiateLayerUpload","ecr:PutImage","ecr:UploadLayerPart","ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"],"Resource":"arn:aws:ecr:$REGION:$ACCOUNT_ID:repository/$ECR_REPO"},
 {"Effect":"Allow","Action":["ecs:DescribeServices","ecs:DescribeTaskDefinition","ecs:RegisterTaskDefinition","ecs:UpdateService","ecs:ListTaskDefinitions"],"Resource":"*"},
 {"Effect":"Allow","Action":["iam:PassRole"],"Resource":["arn:aws:iam::$ACCOUNT_ID:role/$EXEC_ROLE","arn:aws:iam::$ACCOUNT_ID:role/$TASK_ROLE"]},
 {"Effect":"Allow","Action":["s3:ListBucket"],"Resource":"arn:aws:s3:::$FRONTEND_BUCKET"},
 {"Effect":"Allow","Action":["s3:GetObject","s3:PutObject","s3:DeleteObject"],"Resource":"arn:aws:s3:::$FRONTEND_BUCKET/*"},
 {"Effect":"Allow","Action":["cloudfront:CreateInvalidation","cloudfront:GetInvalidation","cloudfront:ListInvalidations"],"Resource":"*"}
]}
EOF
"${AWS[@]}" iam put-role-policy --role-name "$OIDC_ROLE" --policy-name atahbracha-github-deploy-inline --policy-document "file://$GH_POLICY"

OIDC_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$OIDC_ROLE"
ALB_DNS="$(${AWS[@]} elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].DNSName' --output text)"
CF_DOMAIN="$(${AWS[@]} cloudfront get-distribution --id "$DIST_ID" --query 'Distribution.DomainName' --output text)"

echo ""
echo "SETUP COMPLETE"
echo "ECR_URI=$ECR_URI"
echo "ECS_CLUSTER=$ECS_CLUSTER"
echo "ECS_SERVICE=$ECS_SERVICE"
echo "ECS_TASK_FAMILY=$ECS_TASK_FAMILY"
echo "ALB_DNS=$ALB_DNS"
echo "FRONTEND_BUCKET=$FRONTEND_BUCKET"
echo "CLOUDFRONT_DISTRIBUTION_ID=$DIST_ID"
echo "CLOUDFRONT_DOMAIN=$CF_DOMAIN"
echo "AWS_GITHUB_OIDC_ROLE_ARN=$OIDC_ROLE_ARN"

echo ""
echo "If gh is authenticated, run:"
echo "gh variable set AWS_REGION --body '$REGION'"
echo "gh variable set ECR_REPOSITORY --body '$ECR_REPO'"
echo "gh variable set ECS_CLUSTER --body '$ECS_CLUSTER'"
echo "gh variable set ECS_SERVICE --body '$ECS_SERVICE'"
echo "gh variable set ECS_TASK_FAMILY --body '$ECS_TASK_FAMILY'"
echo "gh variable set ECS_CONTAINER_NAME --body '$ECS_CONTAINER_NAME'"
echo "gh variable set FRONTEND_BUCKET --body '$FRONTEND_BUCKET'"
echo "gh variable set CLOUDFRONT_DISTRIBUTION_ID --body '$DIST_ID'"
echo "gh secret set AWS_GITHUB_OIDC_ROLE_ARN --body '$OIDC_ROLE_ARN'"
