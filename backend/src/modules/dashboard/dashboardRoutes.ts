import { Router } from 'express';
import {
	addActivity,
	getDashboardStats,
	logFeeding,
	recordPregnancy,
	recordTreatment,
	scanTag,
} from './dashboardController';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';

const router = Router();

router.use(authenticateFirebaseToken);

router.get('/', getDashboardStats);
router.post('/actions/treatment', recordTreatment);
router.post('/actions/feeding', logFeeding);
router.post('/actions/pregnancy', recordPregnancy);
router.post('/actions/activity', addActivity);
router.post('/actions/scan-tag', scanTag);

export { router as dashboardRoutes };