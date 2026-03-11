import { Router } from 'express';
import { getFarmsByUser } from './farmController';
import { authenticateToken } from '../../middlewares/auth';

const router = Router();

router.get('/', authenticateToken, getFarmsByUser);

export { router as farmRoutes };