import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { PrismaClient, Role, User } from '@prisma/client';
import { ApiResponse } from '../../types';
import { config } from '../../config/env';
import { firebaseAdmin, getFirebaseUser, setUserRole as setFirebaseUserRole } from '../../config/firebaseAdmin';

// Initialize Prisma client
const prisma = new PrismaClient();

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role?: Role;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  user: Omit<User, 'password'>;
  token: string;
}

export interface FirebaseAuthRequest {
  firebaseToken: string;
}

export class AuthService {
  private readonly JWT_SECRET = config.JWT_SECRET;
  private readonly JWT_EXPIRES_IN = config.JWT_EXPIRES_IN;

  async register(data: RegisterRequest): Promise<ApiResponse<AuthResponse>> {
    try {
      // Check if user already exists in Aurora PostgreSQL
      const existingUser = await prisma.user.findUnique({
        where: { email: data.email }
      });
      if (existingUser) {
        return {
          success: false,
          error: 'User with this email already exists'
        };
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(data.password, 10);

      // Create user in Aurora PostgreSQL
      const user = await prisma.user.create({
        data: {
          email: data.email,
          password: hashedPassword,
          firstName: data.firstName,
          lastName: data.lastName,
          role: (data.role as Role) || Role.FARMER
        }
      });

      // Generate JWT token
      const token = this.generateToken(user);

      // Remove password from response
      const { password, ...userWithoutPassword } = user;

      return {
        success: true,
        data: {
          user: userWithoutPassword,
          token
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Registration failed'
      };
    }
  }

  async login(data: LoginRequest): Promise<ApiResponse<AuthResponse>> {
    try {
      // Find user in Aurora PostgreSQL
      const user = await prisma.user.findUnique({
        where: { email: data.email }
      });

      if (!user) {
        return {
          success: false,
          error: 'Invalid email or password'
        };
      }

      // Check password
      const isPasswordValid = await bcrypt.compare(data.password, user.password);
      if (!isPasswordValid) {
        return {
          success: false,
          error: 'Invalid email or password'
        };
      }

      // Generate JWT token
      const token = this.generateToken(user);

      // Remove password from response
      const { password, ...userWithoutPassword } = user;

      return {
        success: true,
        data: {
          user: userWithoutPassword,
          token
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Login failed'
      };
    }
  }

  async getCurrentUser(userId: string): Promise<ApiResponse<Omit<User, 'password'>>> {
    try {
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        return {
          success: false,
          error: 'User not found'
        };
      }

      const { password, ...userWithoutPassword } = user;

      return {
        success: true,
        data: userWithoutPassword
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get user'
      };
    }
  }

  async updateProfile(userId: string, data: Partial<Pick<User, 'firstName' | 'lastName'>>): Promise<ApiResponse<Omit<User, 'password'>>> {
    try {
      const user = await prisma.user.update({
        where: { id: userId },
        data
      });

      const { password, ...userWithoutPassword } = user;

      return {
        success: true,
        data: userWithoutPassword
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update profile'
      };
    }
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<ApiResponse<boolean>> {
    try {
      // Get user with password
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        return {
          success: false,
          error: 'User not found'
        };
      }

      // Verify current password
      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
      if (!isCurrentPasswordValid) {
        return {
          success: false,
          error: 'Current password is incorrect'
        };
      }

      // Hash new password
      const hashedNewPassword = await bcrypt.hash(newPassword, 10);

      // Update password
      await prisma.user.update({
        where: { id: userId },
        data: { password: hashedNewPassword }
      });

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to change password'
      };
    }
  }

  async logout(userId: string): Promise<ApiResponse<boolean>> {
    try {
      // In a real-world scenario, you might want to implement token blacklisting
      // For now, we'll just update user's last activity
      await prisma.user.update({
        where: { id: userId },
        data: { updatedAt: new Date() }
      });

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Logout failed'
      };
    }
  }

  async authenticateWithFirebase(firebaseToken: string): Promise<ApiResponse<AuthResponse>> {
    try {
      // Verify Firebase token and get user info
      const decodedToken = await firebaseAdmin.auth().verifyIdToken(firebaseToken);

      // Get detailed Firebase user info
      const firebaseUser = await firebaseAdmin.auth().getUser(decodedToken.uid);

      // Check if user exists in Aurora PostgreSQL
      let dbUser = await prisma.user.findUnique({
        where: { id: firebaseUser.uid }
      });

      if (!dbUser) {
        // Create user in Aurora PostgreSQL if they don't exist
        const names = firebaseUser.displayName?.split(' ') || ['', ''];
        dbUser = await prisma.user.create({
          data: {
            id: firebaseUser.uid,
            email: firebaseUser.email || '',
            password: 'firebase-auth-user', // Default password for Firebase users
            firstName: names[0] || '',
            lastName: names.slice(1).join(' ') || '',
            role: Role.FARMER, // Default role
            phone: firebaseUser.phoneNumber || null
          }
        });
      } else {
        // Update user info if needed
        const names = firebaseUser.displayName?.split(' ') || ['', ''];
        dbUser = await prisma.user.update({
          where: { id: firebaseUser.uid },
          data: {
            email: firebaseUser.email || dbUser.email,
            firstName: names[0] || dbUser.firstName,
            lastName: names.slice(1).join(' ') || dbUser.lastName,
            phone: firebaseUser.phoneNumber || dbUser.phone,
            updatedAt: new Date()
          }
        });
      }

      // Generate JWT token for API authentication
      const jwtToken = this.generateToken(dbUser);

      // Remove password from response
      const { password, ...userWithoutPassword } = dbUser;

      return {
        success: true,
        data: {
          user: userWithoutPassword,
          token: jwtToken
        }
      };
    } catch (error) {
      console.error('Firebase authentication error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Firebase authentication failed'
      };
    }
  }

  async updateUserRole(userId: string, role: Role): Promise<ApiResponse<boolean>> {
    try {
      // Update role in Firebase custom claims
      await setFirebaseUserRole(userId, role);

      // Update role in Aurora PostgreSQL
      await prisma.user.update({
        where: { id: userId },
        data: { role, updatedAt: new Date() }
      });

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update user role'
      };
    }
  }

  async getUserByFirebaseId(firebaseId: string): Promise<ApiResponse<Omit<User, 'password'> | null>> {
    try {
      const user = await prisma.user.findUnique({
        where: { id: firebaseId }
      });

      if (!user) {
        return {
          success: true,
          data: null
        };
      }

      const { password, ...userWithoutPassword } = user;

      return {
        success: true,
        data: userWithoutPassword
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get user'
      };
    }
  }

  private generateToken(user: User): string {
    return jwt.sign(
      {
        userId: user.id,
        email: user.email,
        role: user.role
      },
      this.JWT_SECRET,
      { expiresIn: this.JWT_EXPIRES_IN } as jwt.SignOptions
    );
  }

  async isOnline(): Promise<boolean> {
    // For Node.js environment, assume online
    // In a real browser environment, you would check navigator.onLine
    return true;
  }

  async cacheUserForOffline(user: Omit<User, 'password'>): Promise<void> {
    try {
      // In a browser environment, you would use localStorage
      // For Node.js, we'll just log it
      console.log('Caching user for offline use:', user.email);
    } catch (error) {
      console.warn('Failed to cache user for offline:', error);
    }
  }

  async getCachedOfflineUser(): Promise<Omit<User, 'password'> | null> {
    try {
      // In a browser environment, you would read from localStorage
      // For Node.js, return null
      return null;
    } catch (error) {
      console.warn('Failed to get cached user:', error);
      return null;
    }
  }

  async clearOfflineCache(): Promise<void> {
    try {
      // In a browser environment, you would clear localStorage
      // For Node.js, we'll just log it
      console.log('Clearing offline cache');
    } catch (error) {
      console.warn('Failed to clear offline cache:', error);
    }
  }

  async validateToken(token: string): Promise<ApiResponse<Omit<User, 'password'>>> {
    try {
      // Verify JWT token
      const decoded = jwt.verify(token, this.JWT_SECRET) as any;
      
      if (!decoded || !decoded.userId) {
        return {
          success: false,
          error: 'Invalid token'
        };
      }

      // Get user from database
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId }
      });

      if (!user) {
        return {
          success: false,
          error: 'User not found'
        };
      }

      const { password, ...userWithoutPassword } = user;

      return {
        success: true,
        data: userWithoutPassword
      };
    } catch (error) {
      return {
        success: false,
        error: 'Invalid token'
      };
    }
  }
}

export const authService = new AuthService();
