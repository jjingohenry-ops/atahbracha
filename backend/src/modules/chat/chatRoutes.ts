import { Router } from 'express';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';
import {
  searchUsers,
  getConversations,
  createChatRequest,
  respondToChatRequest,
  getConversationMessages,
  sendMessage,
} from './chatController';

const router = Router();

router.use(authenticateFirebaseToken);

router.get('/users/search', searchUsers);
router.get('/conversations', getConversations);
router.post('/conversations/request', createChatRequest);
router.post('/conversations/:conversationId/respond', respondToChatRequest);
router.get('/conversations/:conversationId/messages', getConversationMessages);
router.post('/conversations/:conversationId/messages', sendMessage);

export { router as chatRoutes };
