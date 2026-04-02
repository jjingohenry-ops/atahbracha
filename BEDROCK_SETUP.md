# Amazon Bedrock Setup Guide

## Prerequisites
- AWS Account
- AWS CLI configured (optional but recommended)
- Access to AWS Console

## Step 1: Enable DeepSeek v3.2 in AWS Bedrock

1. Go to [AWS Console](https://console.aws.amazon.com)
2. Navigate to **Amazon Bedrock**
3. In the left sidebar, click **Base models**
4. Search for **DeepSeek** or **deepseek-v3**
5. Click on **DeepSeek v3.2**
6. Click **Get Started** or **Enable**
   - This grants your AWS account access to the model
   - May take a few minutes to activate
7. Note the **Model ID**: `deepseek.v3.2`

## Step 2: Create IAM User with Bedrock Permissions

1. Go to **IAM Dashboard**
2. Click **Users** → **Create user**
3. Enter username: `atahbracha-bedrock-user`
4. Click **Next**
5. Click **Attach policies directly**
6. Search and select: `AmazonBedrockFullAccess` (or create custom policy below)
7. Click **Create user**

### Custom Policy (Minimal Permissions)
If you prefer restricted access, create a custom policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*:*:foundation-model/deepseek.v3.2"
    }
  ]
}
```

## Step 3: Generate Access Keys

1. Go to **IAM** → **Users** → Click your user
2. Click **Security credentials** tab
3. Scroll to **Access keys**
4. Click **Create access key**
5. Select **Application running outside AWS**
6. Copy the **Access Key ID** and **Secret Access Key**
   - ⚠️ Save these securely! You won't see the secret again.

## Step 4: Update Backend Environment Variables

Add to `backend/.env`:

```env
# AWS Bedrock Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID_HERE
AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY_HERE
BEDROCK_MODEL_ID=deepseek.v3.2
```

**Replace with your actual credentials from Step 3**

### Available AWS Regions for Bedrock:
- `us-east-1` (N. Virginia) ← Recommended
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-southeast-1` (Singapore)

Check [AWS Bedrock regions](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html#bedrock-regions) for latest availability.

## Step 5: Verify Setup

### Test Backend Connection
```bash
cd backend
npm run dev
```

Then test with curl:
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "systemPrompt": "You are a helpful assistant."
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "role": "assistant",
    "content": "Hello! How can I help you today?"
  }
}
```

### Test Frontend
1. Start frontend: `cd frontend && flutter run -d web-server --web-port=8080`
2. Open `http://localhost:8080`
3. Click the AI chat button (💬)
4. Send a message
5. Should get response from DeepSeek via Bedrock

## Troubleshooting

### Error: "ModelNotFoundException"
- Bedrock model access not enabled
- Solution: Go to Bedrock → Base Models → Enable DeepSeek v3.2

### Error: "AccessDeniedException"
- AWS credentials are invalid or lack permissions
- Solution: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in `.env`
- Ensure IAM user has `bedrock:InvokeModel` permission

### Error: "No region configured"
- `AWS_REGION` not set in `.env`
- Solution: Add `AWS_REGION=us-east-1` to `.env`

### Error: "InvalidRequestException"
- Message format incorrect or model ID wrong
- Solution: Verify `BEDROCK_MODEL_ID=deepseek.v3.2` in `.env`

## Cost Considerations

DeepSeek v3.2 pricing on Bedrock:
- Input: $0.50 per 1M tokens
- Output: $1.50 per 1M tokens

**Example**: 1000 user messages × 500 tokens input + 200 tokens output ≈ $0.70

Monitor usage in AWS Cost Explorer.

## Production Deployment

For production:

1. **Use AWS Secrets Manager** instead of `.env`:
   ```bash
   aws secretsmanager create-secret --name bedrock-api-key \
     --secret-string '{"accessKeyId":"...","secretAccessKey":"..."}'
   ```

2. **Use IAM Roles** on EC2:
   - Attach role with Bedrock permissions to EC2 instance
   - Don't store credentials in `.env`

3. **Enable CloudWatch Logging**:
   - Monitor API calls and errors

4. **Rate Limiting**:
   - Add middleware to limit API calls per user
   - Default: 10 requests/minute

## API Response Format

### Success
```json
{
  "success": true,
  "data": {
    "role": "assistant",
    "content": "Response text here",
    "reasoning_details": null
  }
}
```

### Error
```json
{
  "success": false,
  "error": "Failed to get AI response",
  "details": {
    "name": "AccessDeniedException",
    "message": "User is not authorized..."
  }
}
```

## Switching Back to OpenRouter

If needed, revert to OpenRouter:

1. Remove AWS variables from `.env`
2. Restore original `ai_chat_screen.dart` from git
3. Implement custom `/api/ai/chat` endpoint using OpenRouter API

## References

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [DeepSeek v3.2 on Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids-arns.html)
- [Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)
