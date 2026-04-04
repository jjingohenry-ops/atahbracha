import { Router } from 'express';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';
import { insuranceController } from './insuranceController';

const router = Router();

router.use(authenticateFirebaseToken);

router.get('/providers', insuranceController.getProviders);

export { router as insuranceRoutes };
