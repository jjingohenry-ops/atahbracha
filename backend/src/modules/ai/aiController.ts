import { Request, Response } from 'express';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { config } from '../../config/env';

const useEnvCredentials = (config.BEDROCK_USE_ENV_CREDENTIALS || 'false').toLowerCase() === 'true';

const buildBedrockClient = () => {
  if (useEnvCredentials) {
    if (!config.AWS_ACCESS_KEY_ID || !config.AWS_SECRET_ACCESS_KEY) {
      throw new Error(
        'BEDROCK_USE_ENV_CREDENTIALS=true but AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY are missing.'
      );
    }

    return new BedrockRuntimeClient({
      region: config.AWS_REGION || 'us-east-1',
      credentials: {
        accessKeyId: config.AWS_ACCESS_KEY_ID,
        secretAccessKey: config.AWS_SECRET_ACCESS_KEY,
        ...(config.AWS_SESSION_TOKEN ? { sessionToken: config.AWS_SESSION_TOKEN } : {}),
      },
    });
  }

  // Default provider chain (IAM role, shared profile, env, etc.).
  return new BedrockRuntimeClient({
    region: config.AWS_REGION || 'us-east-1',
  });
};

export const chatWithBedrock = async (req: Request, res: Response) => {
  try {
    const { messages, systemPrompt } = req.body;

    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid request: messages array required',
      });
    }

    // Format messages for DeepSeek v3.2
    const formattedMessages = messages.map((msg) => ({
      role: msg.role,
      content: msg.content,
    }));

    const bedrockRequest = {
      modelId: config.BEDROCK_MODEL_ID || 'deepseek.v3.2',
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        messages: formattedMessages,
        system: systemPrompt || 'You are a helpful assistant.',
        max_tokens: 2048,
        temperature: 0.7,
        top_p: 0.95,
      }),
    };

    const bedrockClient = buildBedrockClient();
    const command = new InvokeModelCommand(bedrockRequest);
    const response = await bedrockClient.send(command);

    // Parse Bedrock response
    const responseBody = JSON.parse(
      new TextDecoder().decode(response.body)
    );

    // Extract the text from the response
    const assistantMessage =
      responseBody?.content?.[0]?.text || responseBody?.output?.message?.content || '';

    res.json({
      success: true,
      data: {
        role: 'assistant',
        content: assistantMessage,
        reasoning_details: responseBody?.reasoning_details || null,
      },
    });
  } catch (error: any) {
    console.error('Bedrock API Error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get AI response',
      details: {
        name: error.name,
        message: error.message,
        credentialSource: useEnvCredentials ? 'explicit-env-credentials' : 'default-provider-chain',
        region: config.AWS_REGION || 'us-east-1',
        modelId: config.BEDROCK_MODEL_ID || 'deepseek.v3.2',
      },
    });
  }
};
