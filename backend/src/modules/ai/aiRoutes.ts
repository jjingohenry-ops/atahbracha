import { Router } from 'express';
import { chatWithBedrock } from './aiController';

const router = Router();

router.post('/chat', chatWithBedrock);

export { router as aiRoutes };
