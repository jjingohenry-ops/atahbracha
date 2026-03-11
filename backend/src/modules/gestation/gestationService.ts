import { db } from '../../config/dexie';
import { Gestation, GestationStatus, ApiResponse } from '../../types';

export interface CreateGestationRequest {
  startDate: Date;
  expectedDate: Date;
  notes?: string;
}

export interface UpdateGestationRequest {
  startDate?: Date;
  expectedDate?: Date;
  status?: GestationStatus;
  notes?: string;
}

export class GestationService {
  async createGestation(
    animalId: string,
    userId: string,
    data: CreateGestationRequest
  ): Promise<ApiResponse<Gestation>> {
    try {
      // Verify user owns the animal
      const animal = await db.animals.get(animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      // Check if animal already has active gestation
      const activeGestation = await db.getActiveGestation(animalId);
      if (activeGestation) {
        return {
          success: false,
          error: 'Animal already has an active gestation period'
        };
      }

      const newGestation: Gestation = {
        id: crypto.randomUUID(),
        animalId,
        startDate: data.startDate,
        expectedDate: data.expectedDate,
        status: GestationStatus.PENDING,
        notes: data.notes,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      await db.gestations.add(newGestation);

      return {
        success: true,
        data: newGestation
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create gestation record'
      };
    }
  }

  async getGestationById(gestationId: string, userId: string): Promise<ApiResponse<Gestation>> {
    try {
      const gestation = await db.gestations.get(gestationId);
      
      if (!gestation) {
        return {
          success: false,
          error: 'Gestation record not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(gestation.animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      return {
        success: true,
        data: gestation
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get gestation record'
      };
    }
  }

  async getGestationsByAnimal(
    animalId: string,
    userId: string,
    limit?: number,
    offset?: number
  ): Promise<ApiResponse<Gestation[]>> {
    try {
      // Verify user owns the animal
      const animal = await db.animals.get(animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const gestations = await db.gestations
        .where('animalId')
        .equals(animalId)
        .reverse()
        .sortBy('startDate');
      
      // Apply pagination
      const startIndex = offset || 0;
      const endIndex = limit ? startIndex + limit : gestations.length;
      const paginatedGestations = gestations.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedGestations
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get gestation records'
      };
    }
  }

  async updateGestation(
    gestationId: string,
    userId: string,
    data: UpdateGestationRequest
  ): Promise<ApiResponse<Gestation>> {
    try {
      const existingGestation = await db.gestations.get(gestationId);
      
      if (!existingGestation) {
        return {
          success: false,
          error: 'Gestation record not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(existingGestation.animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const updateData = {
        ...data,
        updatedAt: new Date()
      };

      await db.gestations.update(gestationId, updateData);

      const updatedGestation = await db.gestations.get(gestationId);
      
      return {
        success: true,
        data: updatedGestation!
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update gestation record'
      };
    }
  }

  async deleteGestation(gestationId: string, userId: string): Promise<ApiResponse<boolean>> {
    try {
      const existingGestation = await db.gestations.get(gestationId);
      
      if (!existingGestation) {
        return {
          success: false,
          error: 'Gestation record not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(existingGestation.animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      await db.gestations.delete(gestationId);

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete gestation record'
      };
    }
  }

  async getActiveGestation(animalId: string, userId: string): Promise<ApiResponse<Gestation | null>> {
    try {
      // Verify user owns the animal
      const animal = await db.animals.get(animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const activeGestation = await db.getActiveGestation(animalId);
      
      return {
        success: true,
        data: activeGestation || null
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get active gestation'
      };
    }
  }

  async completeGestation(gestationId: string, userId: string): Promise<ApiResponse<Gestation>> {
    try {
      const existingGestation = await db.gestations.get(gestationId);
      
      if (!existingGestation) {
        return {
          success: false,
          error: 'Gestation record not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(existingGestation.animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const updateData = {
        status: GestationStatus.COMPLETED,
        updatedAt: new Date()
      };

      await db.gestations.update(gestationId, updateData);

      const updatedGestation = await db.gestations.get(gestationId);
      
      return {
        success: true,
        data: updatedGestation!
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to complete gestation'
      };
    }
  }

  async getGestationStats(animalId: string, userId: string): Promise<ApiResponse<any>> {
    try {
      // Verify user owns the animal
      const animal = await db.animals.get(animalId);
      if (!animal) {
        return {
          success: false,
          error: 'Animal not found'
        };
      }

      const farm = await db.farms.get(animal.farmId);
      if (!farm || farm.userId !== userId) {
        return {
          success: false,
          error: 'Access denied'
        };
      }

      const gestations = await db.gestations
        .where('animalId')
        .equals(animalId)
        .reverse()
        .sortBy('startDate');

      if (gestations.length === 0) {
        return {
          success: true,
          data: {
            totalGestations: 0,
            successfulGestations: 0,
            averageGestationPeriod: 0,
            currentGestation: null
          }
        };
      }

      const successfulGestations = gestations.filter((g: any) => g.status === GestationStatus.COMPLETED);
      const totalGestationDays = successfulGestations.reduce((sum: number, g: any) => {
        const start = new Date(g.startDate);
        const end = new Date(g.expectedDate);
        return sum + Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
      }, 0);

      const averageGestationPeriod = successfulGestations.length > 0 
        ? Math.round(totalGestationDays / successfulGestations.length)
        : 0;

      const currentGestation = await db.getActiveGestation(animalId);

      const stats = {
        totalGestations: gestations.length,
        successfulGestations: successfulGestations.length,
        averageGestationPeriod,
        currentGestation,
        gestationHistory: gestations.map((g: any) => ({
          id: g.id,
          startDate: g.startDate,
          expectedDate: g.expectedDate,
          status: g.status,
          duration: g.status === GestationStatus.COMPLETED 
            ? Math.ceil((new Date(g.expectedDate).getTime() - new Date(g.startDate).getTime()) / (1000 * 60 * 60 * 24))
            : null
        }))
      };

      return {
        success: true,
        data: stats
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get gestation stats'
      };
    }
  }

  async getUpcomingGestations(userId: string, days: number = 30): Promise<ApiResponse<any>> {
    try {
      // Get all user's farms
      const userFarms = await db.farms.where('userId').equals(userId).toArray();
      const farmIds = userFarms.map(farm => farm.id);

      // Get all animals from user's farms
      const allAnimals: any[] = [];
      for (const farmId of farmIds) {
        const farmAnimals = await db.getAnimalsByFarm(farmId);
        allAnimals.push(...farmAnimals);
      }

      // Get all gestations for user's animals
      const allGestations: any[] = [];
      for (const animal of allAnimals) {
        const animalGestations = await db.gestations
          .where('animalId')
          .equals(animal.id)
          .toArray();
        allGestations.push(...animalGestations);
      }

      // Filter for upcoming gestations
      const targetDate = new Date();
      targetDate.setDate(targetDate.getDate() + days);

      const upcomingGestations = allGestations.filter(gestation => {
        return new Date(gestation.expectedDate) <= targetDate && 
               gestation.status !== GestationStatus.COMPLETED;
      });

      // Sort by expected date
      upcomingGestations.sort((a, b) => 
        new Date(a.expectedDate).getTime() - new Date(b.expectedDate).getTime()
      );

      return {
        success: true,
        data: {
          upcomingGestations,
          totalUpcoming: upcomingGestations.length,
          dateRange: {
            start: new Date(),
            end: targetDate
          }
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get upcoming gestations'
      };
    }
  }
}

export const gestationService = new GestationService();
