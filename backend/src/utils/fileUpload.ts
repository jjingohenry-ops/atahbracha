import multer from 'multer';
import path from 'path';
import fs from 'fs/promises';
import { Request, Response, NextFunction } from 'express';
import { config } from '../config/env';

export interface UploadedFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  destination: string;
  filename: string;
  path: string;
}

export class FileUploadUtils {
  private static uploadDir: string = config.UPLOAD_DIR;

  static async ensureUploadDir(): Promise<void> {
    try {
      await fs.mkdir(this.uploadDir, { recursive: true });
      await fs.mkdir(path.join(this.uploadDir, 'images'), { recursive: true });
      await fs.mkdir(path.join(this.uploadDir, 'videos'), { recursive: true });
      await fs.mkdir(path.join(this.uploadDir, 'documents'), { recursive: true });
    } catch (error) {
      console.error('Failed to create upload directories:', error);
    }
  }

  static generateFileName(originalName: string, prefix?: string): string {
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(2, 15);
    const extension = path.extname(originalName);
    const nameWithoutExt = path.basename(originalName, extension);
    const sanitizedName = nameWithoutExt.replace(/[^a-zA-Z0-9]/g, '_');
    
    return `${prefix || ''}${timestamp}_${randomString}_${sanitizedName}${extension}`;
  }

  static getFileType(mimetype: string): 'image' | 'video' | 'document' | null {
    if (mimetype.startsWith('image/')) return 'image';
    if (mimetype.startsWith('video/')) return 'video';
    if (mimetype.includes('pdf') || mimetype.includes('document')) return 'document';
    return null;
  }

  static isValidFileType(mimetype: string): boolean {
    const allowedTypes = config.ALLOWED_FILE_TYPES.split(',');
    return allowedTypes.includes(mimetype);
  }

  static isValidFileSize(size: number): boolean {
    return size <= config.MAX_FILE_SIZE;
  }

  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  static getMulterConfig(options: {
    maxFiles?: number;
    allowedTypes?: string[];
    maxSize?: number;
  } = {}): multer.Multer {
    this.ensureUploadDir();

    const storage = multer.diskStorage({
      destination: (_req, file, cb) => {
        const fileType = this.getFileType(file.mimetype);
        if (!fileType) {
          return cb(new Error('Invalid file type'), '');
        }

        let uploadPath: string;
        switch (fileType) {
          case 'image':
            uploadPath = path.join(this.uploadDir, 'images');
            break;
          case 'video':
            uploadPath = path.join(this.uploadDir, 'videos');
            break;
          case 'document':
            uploadPath = path.join(this.uploadDir, 'documents');
            break;
          default:
            uploadPath = this.uploadDir;
        }

        cb(null, uploadPath);
      },
      filename: (_req, file, cb) => {
        const fileType = this.getFileType(file.mimetype);
        const prefix = fileType ? `${fileType}_` : '';
        const fileName = this.generateFileName(file.originalname, prefix);
        cb(null, fileName);
      }
    });

    const fileFilter = (_req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
      const allowedTypes = options.allowedTypes || config.ALLOWED_FILE_TYPES.split(',');
      const isValidType = allowedTypes.includes(file.mimetype);
      const isValidSize = this.isValidFileSize(file.size);

      if (!isValidType) {
        return cb(new Error(`File type ${file.mimetype} not allowed`));
      }

      if (!isValidSize) {
        return cb(new Error(`File size ${this.formatFileSize(file.size)} exceeds maximum ${this.formatFileSize(options.maxSize || config.MAX_FILE_SIZE)}`));
      }

      cb(null, true);
    };

    return multer({
      storage,
      fileFilter,
      limits: {
        fileSize: options.maxSize || config.MAX_FILE_SIZE,
        files: options.maxFiles || 5
      }
    });
  }

  static async deleteFile(filePath: string): Promise<void> {
    try {
      const fullPath = path.isAbsolute(filePath) ? filePath : path.join(process.cwd(), filePath);
      await fs.unlink(fullPath);
    } catch (error) {
      console.error('Failed to delete file:', filePath, error);
    }
  }

  static async moveFile(oldPath: string, newPath: string): Promise<void> {
    try {
      await fs.rename(oldPath, newPath);
    } catch (error) {
      console.error('Failed to move file:', oldPath, 'to', newPath, error);
    }
  }

  static getFileUrl(filename: string, type: 'image' | 'video' | 'document'): string {
    const baseUrl = process.env['NODE_ENV'] === 'production' 
      ? process.env['BASE_URL'] || 'http://localhost:3000'
      : 'http://localhost:3000';
    
    const folder = type === 'image' ? 'images' : type === 'video' ? 'videos' : 'documents';
    return `${baseUrl}/uploads/${folder}/${filename}`;
  }

  static async cleanupOldFiles(maxAge: number = 30 * 24 * 60 * 60 * 1000): Promise<void> {
    try {
      const files = await fs.readdir(this.uploadDir, { recursive: true });
      const now = Date.now();

      for (const file of files) {
        const filePath = path.join(this.uploadDir, file);
        const stats = await fs.stat(filePath);
        
        if (now - stats.mtime.getTime() > maxAge) {
          await fs.unlink(filePath);
        }
      }
    } catch (error) {
      console.error('Failed to cleanup old files:', error);
    }
  }
}

// Middleware for handling file upload errors
export const handleUploadError = (
  _error: any,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // This middleware is handled by multer error handling
  res.status(500).json({
    success: false,
    error: 'File upload error'
  });
};
