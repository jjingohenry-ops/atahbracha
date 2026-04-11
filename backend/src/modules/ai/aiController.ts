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

    // Anthropic Messages API expects text content blocks and user/assistant roles.
    const formattedMessages = messages
      .filter((msg: any) => (msg?.role === 'user' || msg?.role === 'assistant'))
      .map((msg: any) => ({
        role: msg.role,
        content: [
          {
            type: 'text',
            text: String(msg?.content ?? ''),
          },
        ],
      }));

    const bedrockRequest = {
      modelId:
        config.BEDROCK_MODEL_ID || 'us.anthropic.claude-3-5-haiku-20241022-v1:0',
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        anthropic_version: 'bedrock-2023-05-31',
        messages: formattedMessages,
        system: systemPrompt || 'You are a helpful assistant.',
        max_tokens: 1200,
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
      responseBody?.content?.find((item: any) => item?.type === 'text')?.text ||
      responseBody?.output?.message?.content?.find((item: any) => item?.type === 'text')?.text ||
      '';

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
        modelId:
          config.BEDROCK_MODEL_ID || 'us.anthropic.claude-3-5-haiku-20241022-v1:0',
      },
    });
  }
};
