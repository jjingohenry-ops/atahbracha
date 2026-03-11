import multer from 'multer';
import path from 'path';
import * as fs from 'fs/promises';
import { db } from '../../config/dexie';
import { Animal, AnimalType, Gender, ApiResponse } from '../../types';
import { config as appConfig } from '../../config/env';

export interface CreateAnimalRequest {
  farmId: string;
  name: string;
  type: AnimalType;
  age: number;
  weight: number;
  gender: Gender;
  notes?: string;
}

export interface UpdateAnimalRequest {
  name?: string;
  age?: number;
  weight?: number;
  gender?: Gender;
  notes?: string;
}

export class AnimalService {
  private uploadDir: string;

  constructor() {
    this.uploadDir = appConfig.UPLOAD_DIR;
    this.ensureUploadDir();
  }

  private async ensureUploadDir(): Promise<void> {
    try {
      await fs.mkdir(this.uploadDir, { recursive: true });
      await fs.mkdir(path.join(this.uploadDir, 'images'), { recursive: true });
      await fs.mkdir(path.join(this.uploadDir, 'videos'), { recursive: true });
    } catch (error) {
      console.error('Failed to create upload directories:', error);
    }
  }

  private generateFileName(originalName: string, _type?: string): string {
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(2, 15);
    const extension = path.extname(originalName);
    return `${timestamp}_${randomString}${extension}`;
  }

  private getFileType(mimetype: string): 'image' | 'video' | null {
    if (mimetype.startsWith('image/')) return 'image';
    if (mimetype.startsWith('video/')) return 'video';
    return null;
  }

  getMulterConfig(): multer.Multer {
    const storage = multer.diskStorage({
      destination: (_req, file, cb) => {
        const fileType = this.getFileType(file.mimetype);
        if (!fileType) {
          return cb(new Error('Invalid file type'), '');
        }

        const uploadPath = path.join(this.uploadDir, fileType === 'image' ? 'images' : 'videos');
        cb(null, uploadPath);
      },
      filename: (_req, file, cb) => {
        const fileName = this.generateFileName(file.originalname);
        cb(null, fileName);
      }
    });

    const fileFilter = (_req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
      const allowedTypes = appConfig.ALLOWED_FILE_TYPES.split(',');
      if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
      } else {
        cb(new Error(`File type ${file.mimetype} not allowed`));
      }
    };

    return multer({
      storage,
      fileFilter,
      limits: {
        fileSize: appConfig.MAX_FILE_SIZE,
        files: 2 // max 2 files (1 photo, 1 video)
      }
    });
  }

  async createAnimal(
    userId: string,
    data: CreateAnimalRequest,
    files?: { photo?: Express.Multer.File; video?: Express.Multer.File }
  ): Promise<ApiResponse<Animal>> {
    try {
      // Verify user owns the farm
      const farm = await db.farms.get(data.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied or farm not found'
        };
      }

      let photoUrl: string | undefined;
      let videoUrl: string | undefined;

      // Handle file uploads
      if (files?.photo) {
        const fileType = this.getFileType(files.photo.mimetype);
        if (fileType === 'image') {
          photoUrl = `/uploads/images/${files.photo.filename}`;
        }
      }

      if (files?.video) {
        const fileType = this.getFileType(files.video.mimetype);
        if (fileType === 'video') {
          videoUrl = `/uploads/videos/${files.video.filename}`;
        }
      }

      const newAnimal: Animal = {
        id: crypto.randomUUID(),
        farmId: data.farmId,
        name: data.name,
        type: data.type,
        age: data.age,
        weight: data.weight,
        gender: data.gender,
        photoUrl,
        videoUrl,
        notes: data.notes,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      await db.animals.add(newAnimal);

      return {
        success: true,
        data: newAnimal
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create animal'
      };
    }
  }

  async getAnimalById(animalId: string, userId: string): Promise<ApiResponse<Animal>> {
    try {
      const animal = await db.animals.get(animalId);
      
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      // Verify user owns the farm
      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      return {
        success: true,
        data: animal
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get animal'
      };
    }
  }

  async getAnimalsByFarm(farmId: string, userId: string): Promise<ApiResponse<Animal[]>> {
    try {
      // Verify user owns the farm
      const farm = await db.farms.get(farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied or farm not found'
        };
      }

      const animals = await db.getAnimalsByFarm(farmId);
      
      return {
        success: true,
        data: animals
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get animals'
      };
    }
  }

  async getAnimalsByType(farmId: string, animalType: AnimalType, userId: string): Promise<ApiResponse<Animal[]>> {
    try {
      // Verify user owns the farm
      const farm = await db.farms.get(farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied or farm not found'
        };
      }

      const animals = await db.animals
        .where('farmId')
        .equals(farmId)
        .and(animal => animal.type === animalType)
        .toArray();
      
      return {
        success: true,
        data: animals
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get animals by type'
      };
    }
  }

  async updateAnimal(
    animalId: string,
    userId: string,
    data: UpdateAnimalRequest,
    files?: { photo?: Express.Multer.File; video?: Express.Multer.File }
  ): Promise<ApiResponse<Animal>> {
    try {
      const existingAnimal = await db.animals.get(animalId);
      
      if (!existingAnimal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      // Verify user owns the farm
      const farm = await db.farms.get(existingAnimal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      let photoUrl = existingAnimal.photoUrl;
      let videoUrl = existingAnimal.videoUrl;

      // Handle file updates
      if (files?.photo) {
        const fileType = this.getFileType(files.photo.mimetype);
        if (fileType === 'image') {
          // Delete old photo if exists
          if (photoUrl) {
            const oldPhotoPath = path.join(process.cwd(), 'src/public', photoUrl);
            await fs.unlink(oldPhotoPath).catch(() => {}); // Ignore errors
          }
          photoUrl = `/uploads/images/${files.photo.filename}`;
        }
      }

      if (files?.video) {
        const fileType = this.getFileType(files.video.mimetype);
        if (fileType === 'video') {
          // Delete old video if exists
          if (videoUrl) {
            const oldVideoPath = path.join(process.cwd(), 'src/public', videoUrl);
            await fs.unlink(oldVideoPath).catch(() => {}); // Ignore errors
          }
          videoUrl = `/uploads/videos/${files.video.filename}`;
        }
      }

      const updateData = {
        ...data,
        photoUrl,
        videoUrl,
        updatedAt: new Date()
      };

      await db.animals.update(animalId, updateData);

      const updatedAnimal = await db.animals.get(animalId);
      
      return {
        success: true,
        data: updatedAnimal!
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update animal'
      };
    }
  }

  async deleteAnimal(animalId: string, userId: string): Promise<ApiResponse<boolean>> {
    try {
      const existingAnimal = await db.animals.get(animalId);
      
      if (!existingAnimal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      // Verify user owns the farm
      const farm = await db.farms.get(existingAnimal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      // Delete associated files
      if (existingAnimal.photoUrl) {
        const photoPath = path.join(process.cwd(), 'src/public', existingAnimal.photoUrl);
        await fs.unlink(photoPath).catch(() => {}); // Ignore errors
      }

      if (existingAnimal.videoUrl) {
        const videoPath = path.join(process.cwd(), 'src/public', existingAnimal.videoUrl);
        await fs.unlink(videoPath).catch(() => {}); // Ignore errors
      }

      // Delete related records
      const feedingLogs = await db.feedingLogs.where('animalId').equals(animalId).toArray();
      for (const log of feedingLogs) {
        await db.feedingLogs.delete(log.id);
      }

      const gestations = await db.gestations.where('animalId').equals(animalId).toArray();
      for (const gestation of gestations) {
        await db.gestations.delete(gestation.id);
      }

      const treatments = await db.treatments.where('animalId').equals(animalId).toArray();
      for (const treatment of treatments) {
        await db.treatments.delete(treatment.id);
      }

      const activities = await db.dailyActivities.where('animalId').equals(animalId).toArray();
      for (const activity of activities) {
        await db.dailyActivities.delete(activity.id);
      }

      const cautionNotes = await db.cautionNotes.where('animalId').equals(animalId).toArray();
      for (const note of cautionNotes) {
        await db.cautionNotes.delete(note.id);
      }

      // Delete the animal
      await db.animals.delete(animalId);

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete animal'
      };
    }
  }

  async searchAnimals(
    userId: string,
    query: string,
    farmId?: string
  ): Promise<ApiResponse<Animal[]>> {
    try {
      let animals: Animal[] = [];

      if (farmId) {
        // Search within specific farm
        const farm = await db.farms.get(farmId);
        if (!farm || farm.userId !== userId) {
          return {
            success: false,
            error: 'Access denied or farm not found'
          };
        }
        animals = await db.getAnimalsByFarm(farmId);
      } else {
        // Search all user's animals
        const userFarms = await db.farms.where('userId').equals(userId).toArray();
        for (const farm of userFarms) {
          const farmAnimals = await db.getAnimalsByFarm(farm.id);
          animals.push(...farmAnimals);
        }
      }

      // Filter by search query
      const filteredAnimals = animals.filter(animal =>
        animal.name.toLowerCase().includes(query.toLowerCase()) ||
        animal.type.toLowerCase().includes(query.toLowerCase()) ||
        (animal.notes && animal.notes.toLowerCase().includes(query.toLowerCase()))
      );

      return {
        success: true,
        data: filteredAnimals
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to search animals'
      };
    }
  }
}

export const animalService = new AnimalService();
