import { db } from '../../config/dexie';
import { Farm, AnimalType, ApiResponse } from '../../types';

export interface CreateFarmRequest {
  name: string;
  location?: string;
  animalTypes: AnimalType[];
}

export interface UpdateFarmRequest {
  name?: string;
  location?: string;
  animalTypes?: AnimalType[];
}

export class FarmService {
  async createFarm(userId: string, data: CreateFarmRequest): Promise<ApiResponse<Farm>> {
    try {
      const newFarm: Farm = {
        id: crypto.randomUUID(),
        userId,
        name: data.name,
        location: data.location,
        animalTypes: data.animalTypes,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      await db.farms.add(newFarm);

      return {
        success: true,
        data: newFarm
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create farm'
      };
    }
  }

  async getFarmById(farmId: string, userId: string): Promise<ApiResponse<Farm>> {
    try {
      const farm = await db.farms.get(farmId);
      
      if (!farm) {
        return {
          success: false,
          error: 'Farm not found'
        };
      }

      if (farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      return {
        success: true,
        data: farm
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get farm'
      };
    }
  }

  async getFarmsByUser(userId: string): Promise<ApiResponse<Farm[]>> {
    try {
      const farms = await db.farms.where('userId').equals(userId).toArray();
      
      return {
        success: true,
        data: farms
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get farms'
      };
    }
  }

  async updateFarm(farmId: string, userId: string, data: UpdateFarmRequest): Promise<ApiResponse<Farm>> {
    try {
      const existingFarm = await db.farms.get(farmId);
      
      if (!existingFarm) {
        return {
          success: false,
          error: 'Farm not found'
        };
      }

      if (existingFarm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const updateData = {
        ...data,
        updatedAt: new Date()
      };

      await db.farms.update(farmId, updateData);

      const updatedFarm = await db.farms.get(farmId);
      
      return {
        success: true,
        data: updatedFarm!
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update farm'
      };
    }
  }

  async deleteFarm(farmId: string, userId: string): Promise<ApiResponse<boolean>> {
    try {
      const existingFarm = await db.farms.get(farmId);
      
      if (!existingFarm) {
        return {
          success: false,
          error: 'Farm not found'
        };
      }

      if (existingFarm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      // Delete all animals associated with this farm
      const animals = await db.getAnimalsByFarm(farmId);
      for (const animal of animals) {
        await db.animals.delete(animal.id);
      }

      // Delete the farm
      await db.farms.delete(farmId);

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete farm'
      };
    }
  }

  async getFarmAnimals(farmId: string, userId: string): Promise<ApiResponse<any[]>> {
    try {
      const farm = await db.farms.get(farmId);
      
      if (!farm) {
        return {
          success: false,
          error: 'Farm not found'
        };
      }

      if (farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
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
        error: error instanceof Error ? error.message : 'Failed to get farm animals'
      };
    }
  }

  async getFarmStats(farmId: string, userId: string): Promise<ApiResponse<any>> {
    try {
      const farm = await db.farms.get(farmId);
      
      if (!farm) {
        return {
          success: false,
          error: 'Farm not found'
        };
      }

      if (farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const animals = await db.getAnimalsByFarm(farmId);
      
      const stats = {
        totalAnimals: animals.length,
        animalTypes: farm.animalTypes,
        animalsByType: animals.reduce((acc, animal) => {
          acc[animal.type] = (acc[animal.type] || 0) + 1;
          return acc;
        }, {} as Record<AnimalType, number>),
        createdAt: farm.createdAt,
        lastUpdated: farm.updatedAt
      };

      return {
        success: true,
        data: stats
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get farm stats'
      };
    }
  }
}

export const farmService = new FarmService();
