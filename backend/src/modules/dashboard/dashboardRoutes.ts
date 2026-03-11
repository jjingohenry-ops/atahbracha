import { Router } from 'express';
import { getDashboardStats } from './dashboardController';

const router = Router();

router.get('/', getDashboardStats);

export { router as dashboardRoutes };