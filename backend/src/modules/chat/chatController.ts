import { Request, Response } from 'express';
import { PrismaClient, ChatConversationStatus } from '@prisma/client';
import { z } from 'zod';

const prisma = new PrismaClient();

const createRequestSchema = z.object({
  recipientUserId: z.string().min(1, 'recipientUserId is required'),
  message: z.string().trim().min(1, 'message is required').max(2000, 'message is too long'),
});

const respondSchema = z.object({
  action: z.enum(['ACCEPT', 'REJECT']),
});

const sendMessageSchema = z.object({
  content: z.string().trim().min(1, 'content is required').max(2000, 'content is too long'),
});

function getCurrentUserId(req: Request): string | null {
  const uid = (req as any).user?.uid;
  if (!uid || typeof uid !== 'string') {
    return null;
  }
  return uid;
}

export const searchUsers = async (req: Request, res: Response) => {
  try {
    const currentUserId = getCurrentUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const query = (req.query.q ?? '').toString().trim();
    if (query.length < 2) {
      return res.json({ success: true, data: [] });
    }

    const users = await prisma.user.findMany({
      where: {
        id: { not: currentUserId },
        OR: [
          { firstName: { contains: query, mode: 'insensitive' } },
          { lastName: { contains: query, mode: 'insensitive' } },
          { email: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
      },
      take: 20,
      orderBy: [{ firstName: 'asc' }, { lastName: 'asc' }],
    });

    return res.json({
      success: true,
      data: users.map((u) => ({
        id: u.id,
        username: `${u.firstName} ${u.lastName}`.trim(),
        firstName: u.firstName,
        lastName: u.lastName,
        email: u.email,
      })),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: 'Failed to search users',
      details: error,
    });
  }
};

export const getConversations = async (req: Request, res: Response) => {
  try {
    const currentUserId = getCurrentUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const conversations = await prisma.chatConversation.findMany({
      where: {
        members: {
          some: {
            userId: currentUserId,
          },
        },
      },
      include: {
        requestedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
        requestedTo: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            content: true,
            createdAt: true,
            senderId: true,
          },
        },
      },
      orderBy: [{ lastMessageAt: 'desc' }, { createdAt: 'desc' }],
    });

    return res.json({
      success: true,
      data: conversations.map((c) => {
        const otherUser = c.requestedById === currentUserId ? c.requestedTo : c.requestedBy;
        return {
          id: c.id,
          status: c.status,
          requestedById: c.requestedById,
          requestedToId: c.requestedToId,
          acceptedAt: c.acceptedAt,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          lastMessageAt: c.lastMessageAt,
          otherUser: {
            id: otherUser.id,
            username: `${otherUser.firstName} ${otherUser.lastName}`.trim(),
            firstName: otherUser.firstName,
            lastName: otherUser.lastName,
            email: otherUser.email,
          },
          lastMessage: c.messages[0] ?? null,
          isIncomingRequest: c.status === 'PENDING' && c.requestedToId === currentUserId,
        };
      }),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch conversations',
      details: error,
    });
  }
};

export const createChatRequest = async (req: Request, res: Response) => {
  try {
    const currentUserId = getCurrentUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const validated = createRequestSchema.parse(req.body);

    if (validated.recipientUserId === currentUserId) {
      return res.status(400).json({
        success: false,
        error: 'You cannot start a chat with yourself',
      });
    }

    const recipient = await prisma.user.findUnique({ where: { id: validated.recipientUserId } });
    if (!recipient) {
      return res.status(404).json({ success: false, error: 'Recipient user not found' });
    }

    const existingConversation = await prisma.chatConversation.findFirst({
      where: {
        AND: [
          { members: { some: { userId: currentUserId } } },
          { members: { some: { userId: validated.recipientUserId } } },
          { status: { in: [ChatConversationStatus.PENDING, ChatConversationStatus.ACCEPTED] } },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });

    if (existingConversation) {
      if (existingConversation.status === ChatConversationStatus.ACCEPTED) {
        const message = await prisma.chatMessage.create({
          data: {
            conversationId: existingConversation.id,
            senderId: currentUserId,
            content: validated.message,
          },
        });

        await prisma.chatConversation.update({
          where: { id: existingConversation.id },
          data: { lastMessageAt: message.createdAt },
        });

        return res.status(200).json({
          success: true,
          data: {
            conversationId: existingConversation.id,
            message,
            status: ChatConversationStatus.ACCEPTED,
          },
        });
      }

      return res.status(409).json({
        success: false,
        error: 'A pending chat request already exists for this user',
      });
    }

    const created = await prisma.chatConversation.create({
      data: {
        requestedById: currentUserId,
        requestedToId: validated.recipientUserId,
        status: ChatConversationStatus.PENDING,
        lastMessageAt: new Date(),
        members: {
          create: [{ userId: currentUserId }, { userId: validated.recipientUserId }],
        },
        messages: {
          create: {
            senderId: currentUserId,
            content: validated.message,
          },
        },
      },
      include: {
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    return res.status(201).json({
      success: true,
      data: {
        conversationId: created.id,
        status: created.status,
        message: created.messages[0],
      },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.issues,
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Failed to create chat request',
      details: error,
    });
  }
};

export const respondToChatRequest = async (req: Request, res: Response) => {
  try {
    const currentUserId = getCurrentUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const conversationIdRaw = req.params.conversationId;
    const conversationId = Array.isArray(conversationIdRaw) ? conversationIdRaw[0] : conversationIdRaw;
    if (!conversationId) {
      return res.status(400).json({ success: false, error: 'conversationId is required' });
    }
    const validated = respondSchema.parse(req.body);

    const conversation = await prisma.chatConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }

    if (conversation.requestedToId !== currentUserId) {
      return res.status(403).json({ success: false, error: 'Only the recipient can respond to this request' });
    }

    if (conversation.status !== ChatConversationStatus.PENDING) {
      return res.status(400).json({ success: false, error: 'This chat request is already resolved' });
    }

    const nextStatus =
      validated.action === 'ACCEPT' ? ChatConversationStatus.ACCEPTED : ChatConversationStatus.REJECTED;

    const updated = await prisma.chatConversation.update({
      where: { id: conversationId },
      data: {
        status: nextStatus,
        acceptedAt: validated.action === 'ACCEPT' ? new Date() : null,
      },
    });

    return res.json({
      success: true,
      data: {
        id: updated.id,
        status: updated.status,
        acceptedAt: updated.acceptedAt,
      },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.issues,
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Failed to respond to chat request',
      details: error,
    });
  }
};

export const getConversationMessages = async (req: Request, res: Response) => {
  try {
    const currentUserId = getCurrentUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const conversationIdRaw = req.params.conversationId;
    const conversationId = Array.isArray(conversationIdRaw) ? conversationIdRaw[0] : conversationIdRaw;
    if (!conversationId) {
      return res.status(400).json({ success: false, error: 'conversationId is required' });
    }

    const membership = await prisma.chatConversationMember.findFirst({
      where: {
        conversationId,
        userId: currentUserId,
      },
    });

    if (!membership) {
      return res.status(403).json({ success: false, error: 'Access denied to this conversation' });
    }

    const conversation = await prisma.chatConversation.findUnique({
      where: { id: conversationId },
      include: {
        requestedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
        requestedTo: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
    });

    if (!conversation) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }

    const messages = await prisma.chatMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });

    return res.json({
      success: true,
      data: {
        conversation: {
          id: conversation.id,
          status: conversation.status,
          requestedById: conversation.requestedById,
          requestedToId: conversation.requestedToId,
          acceptedAt: conversation.acceptedAt,
          createdAt: conversation.createdAt,
          updatedAt: conversation.updatedAt,
        },
        messages: messages.map((m) => ({
          id: m.id,
          content: m.content,
          senderId: m.senderId,
          createdAt: m.createdAt,
          editedAt: m.editedAt,
        })),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch conversation messages',
      details: error,
    });
  }
};

export const sendMessage = async (req: Request, res: Response) => {
  try {
    const currentUserId = getCurrentUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const conversationIdRaw = req.params.conversationId;
    const conversationId = Array.isArray(conversationIdRaw) ? conversationIdRaw[0] : conversationIdRaw;
    if (!conversationId) {
      return res.status(400).json({ success: false, error: 'conversationId is required' });
    }
    const validated = sendMessageSchema.parse(req.body);

    const conversation = await prisma.chatConversation.findUnique({
      where: { id: conversationId },
      include: {
        members: true,
      },
    });

    if (!conversation) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }

    const isMember = conversation.members.some((m) => m.userId === currentUserId);
    if (!isMember) {
      return res.status(403).json({ success: false, error: 'Access denied to this conversation' });
    }

    if (conversation.status !== ChatConversationStatus.ACCEPTED) {
      return res.status(403).json({
        success: false,
        error: 'Chat request must be accepted before sending normal messages',
      });
    }

    const message = await prisma.chatMessage.create({
      data: {
        conversationId,
        senderId: currentUserId,
        content: validated.content,
      },
    });

    await prisma.chatConversation.update({
      where: { id: conversationId },
      data: {
        lastMessageAt: message.createdAt,
      },
    });

    return res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.issues,
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Failed to send message',
      details: error,
    });
  }
};
