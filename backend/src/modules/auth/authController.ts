import { Request, Response } from 'express';
import { authService } from './authService';
import { z } from 'zod';
import { Role } from '../../types';
import { firebaseAdmin } from '../../config/firebaseAdmin';

// Validation schemas
const registerSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  role: z.enum(['FARMER', 'ADMIN']).optional()
});

const loginSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(1, 'Password is required')
});

const updateProfileSchema = z.object({
  firstName: z.string().min(1, 'First name is required').optional(),
  lastName: z.string().min(1, 'Last name is required').optional()
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: z.string().min(6, 'New password must be at least 6 characters long')
});

const firebaseAuthSchema = z.object({
  firebaseToken: z.string().min(1, 'Firebase token is required')
});

const setRoleSchema = z.object({
  role: z.enum(['FARMER', 'ADMIN'])
});

export class AuthController {
  async register(req: Request, res: Response): Promise<void> {
    try {
      const validatedData = registerSchema.parse(req.body);
      // Ensure role has a default value
      const registerData = {
        ...validatedData,
        role: (validatedData.role as Role) || Role.FARMER
      };
      const result = await authService.register(registerData);

      if (result.success) {
        res.status(201).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }

  async login(req: Request, res: Response): Promise<void> {
    try {
      const validatedData = loginSchema.parse(req.body);
      const result = await authService.login(validatedData);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(401).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }

  async getCurrentUser(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'User not authenticated'
        });
        return;
      }

      const result = await authService.getCurrentUser(userId);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(404).json(result);
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }

  async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'User not authenticated'
        });
        return;
      }

      const validatedData = updateProfileSchema.parse(req.body);
      // Filter out undefined values to match the expected type
      const updateData: { firstName?: string; lastName?: string } = {};
      if (validatedData.firstName !== undefined) {
        updateData.firstName = validatedData.firstName;
      }
      if (validatedData.lastName !== undefined) {
        updateData.lastName = validatedData.lastName;
      }

      const result = await authService.updateProfile(userId, updateData);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }

  async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'User not authenticated'
        });
        return;
      }

      const validatedData = changePasswordSchema.parse(req.body);
      const result = await authService.changePassword(
        userId,
        validatedData.currentPassword,
        validatedData.newPassword
      );

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }

  async logout(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;
      const result = await authService.logout(userId);

      res.json(result);
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }

  async getOfflineUser(_req: Request, res: Response): Promise<void> {
    try {
      const cachedUser = await authService.getCachedOfflineUser();
      
      res.status(200).json({
        success: true,
        data: cachedUser
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }

  async checkOnlineStatus(_req: Request, res: Response): Promise<void> {
    try {
      const isOnline = await authService.isOnline();
      
      res.status(200).json({
        success: true,
        data: { isOnline }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }

  // Firebase authentication methods
  async authenticateWithFirebase(req: Request, res: Response): Promise<void> {
    try {
      const validatedData = firebaseAuthSchema.parse(req.body);
      const result = await authService.authenticateWithFirebase(validatedData.firebaseToken);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }

  async getCurrentUserFirebase(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'User not authenticated'
        });
        return;
      }

      const result = await authService.getCurrentUser(userId);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }

  async updateProfileFirebase(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'User not authenticated'
        });
        return;
      }

      const validatedData = updateProfileSchema.parse(req.body);
      // Filter out undefined values
      const updateData: { firstName?: string; lastName?: string } = {};
      if (validatedData.firstName !== undefined) {
        updateData.firstName = validatedData.firstName;
      }
      if (validatedData.lastName !== undefined) {
        updateData.lastName = validatedData.lastName;
      }
      
      const result = await authService.updateProfile(userId, updateData);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }

  async setUserRole(req: Request, res: Response): Promise<void> {
    try {
      const { userId } = req.params;
      const validatedData = setRoleSchema.parse(req.body);
      
      // Ensure userId is a string
      const userIdStr = Array.isArray(userId) ? userId[0] : userId;
      
      // Set custom claims in Firebase
      await firebaseAdmin.auth().setCustomUserClaims(userIdStr, { role: validatedData.role });
      
      // Update role in database
      const result = await authService.updateUserRole(userIdStr, validatedData.role);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.issues
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    }
  }
}

export const authController = new AuthController();
