import { Router } from 'express';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';
import { config } from '../../config/env';
import { createRateLimiter } from '../../middlewares/rateLimit';
import { chatWithBedrock } from './aiController';

const router = Router();

router.use(authenticateFirebaseToken);
router.use(createRateLimiter({
  windowMs: config.API_RATE_LIMIT_WINDOW_MS,
  max: config.AI_RATE_LIMIT_MAX,
  keyPrefix: 'ai',
}));

router.post('/chat', chatWithBedrock);

export { router as aiRoutes };
