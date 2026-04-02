import { Router } from 'express';
import { getFarmsByUser, createFarm } from './farmController';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';

const router = Router();

router.get('/', authenticateFirebaseToken, getFarmsByUser);
router.post('/', authenticateFirebaseToken, createFarm);

export { router as farmRoutes };