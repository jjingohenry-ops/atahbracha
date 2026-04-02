import { Router } from 'express';
import { addReminder, completeReminder, getReminders } from './treatmentController';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';

const router = Router();

router.use(authenticateFirebaseToken);

// generic reminders endpoint (treatments table is used as reminders)
router.get('/', getReminders);
router.post('/', addReminder);
router.delete('/:id', completeReminder);

export { router as remindersRoutes };
