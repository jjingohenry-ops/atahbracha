import { Router } from 'express';
import { getReminders, addReminder } from './treatmentController';

const router = Router();

// generic reminders endpoint (treatments table is used as reminders)
router.get('/', getReminders);
router.post('/', addReminder);

export { router as remindersRoutes };
