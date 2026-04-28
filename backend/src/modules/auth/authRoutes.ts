import { Router } from 'express';
import { authController } from './authController';
import { authenticateToken, requireRole } from '../../middlewares/auth';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';

const router = Router();

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Firebase authentication routes
router.post('/firebase', authController.authenticateWithFirebase);

// Protected routes (JWT token)
router.get('/me', authenticateToken, authController.getCurrentUser);
router.put('/profile', authenticateToken, authController.updateProfile);
router.put('/password', authenticateToken, authController.changePassword);
router.post('/logout', authenticateToken, authController.logout);

// Firebase protected routes (Firebase token)
router.get('/firebase/me', authenticateFirebaseToken, authController.getCurrentUserFirebase);
router.put('/firebase/profile', authenticateFirebaseToken, authController.updateProfileFirebase);

// User management
router.put('/user/:userId/role', authenticateToken, requireRole(['ADMIN']), authController.setUserRole);

// Offline support routes
router.get('/offline', authController.getOfflineUser);
router.get('/status', authController.checkOnlineStatus);

export { router as authRoutes };
