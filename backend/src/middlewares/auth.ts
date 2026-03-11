import { Request, Response, NextFunction } from 'express';
import { authService } from '../modules/auth/authService';

interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    email: string;
    role: string;
  };
}

export const authenticateToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      res.status(401).json({
        success: false,
        error: 'Access token required'
      });
      return;
    }

    const result = await authService.validateToken(token);
    
    if (!result.success || !result.data) {
      res.status(401).json({
        success: false,
        error: result.error || 'Invalid token'
      });
      return;
    }

    req.user = {
      userId: result.data.id,
      email: result.data.email,
      role: result.data.role
    };

    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      error: 'Invalid token'
    });
  }
};

export const requireRole = (roles: string[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
      return;
    }

    if (!roles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        error: 'Insufficient permissions'
      });
      return;
    }

    next();
  };
};

export const optionalAuth = async (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const result = await authService.validateToken(token);
      
      if (result.success && result.data) {
        req.user = {
          userId: result.data.id,
          email: result.data.email,
          role: result.data.role
        };
      }
    }

    next();
  } catch (_error) {
    // For optional auth, we don't return an error, just continue without user
    next();
  }
};

export { AuthenticatedRequest };
