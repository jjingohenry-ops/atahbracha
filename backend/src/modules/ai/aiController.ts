import { Request, Response } from 'express';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { z } from 'zod';
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

const messageSchema = z.object({
  role: z.enum(['user', 'assistant']),
  content: z.string().trim().min(1).max(2000),
});

const chatRequestSchema = z.object({
  messages: z.array(messageSchema).min(1).max(20),
  systemPrompt: z.string().trim().max(1200).optional(),
});

export const chatWithBedrock = async (req: Request, res: Response) => {
  try {
    const { messages, systemPrompt } = chatRequestSchema.parse(req.body);

    // Anthropic Messages API expects text content blocks and user/assistant roles.
    const formattedMessages = messages
      .map((msg) => ({
        role: msg.role,
        content: [
          {
            type: 'text',
            text: msg.content,
          },
        ],
      }));

    const bedrockRequest = {
      modelId:
        config.BEDROCK_MODEL_ID || 'anthropic.claude-3-haiku-20240307-v1:0',
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        anthropic_version: 'bedrock-2023-05-31',
        messages: formattedMessages,
        system: systemPrompt || 'You are a helpful livestock assistant.',
        max_tokens: 800,
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
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Invalid AI chat request',
        details: error.issues,
      });
    }

    console.error('Bedrock API Error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get AI response',
      ...(config.NODE_ENV === 'production'
        ? {}
        : {
            details: {
              name: error.name,
              message: error.message,
              credentialSource: useEnvCredentials ? 'explicit-env-credentials' : 'default-provider-chain',
              region: config.AWS_REGION || 'us-east-1',
              modelId:
                config.BEDROCK_MODEL_ID || 'anthropic.claude-3-haiku-20240307-v1:0',
            },
          }),
    });
  }
};
