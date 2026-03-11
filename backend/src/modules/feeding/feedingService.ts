import { db } from '../../config/dexie';
import { FeedingLog, ApiResponse } from '../../types';

export interface CreateFeedingLogRequest {
  time: Date;
  quantity: number;
  foodType: string;
  notes?: string;
}

export interface UpdateFeedingLogRequest {
  time?: Date;
  quantity?: number;
  foodType?: string;
  notes?: string;
}

export class FeedingService {
  async createFeedingLog(
    animalId: string,
    userId: string,
    data: CreateFeedingLogRequest
  ): Promise<ApiResponse<FeedingLog>> {
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

      const newFeedingLog: FeedingLog = {
        id: crypto.randomUUID(),
        animalId,
        time: data.time,
        quantity: data.quantity,
        foodType: data.foodType,
        notes: data.notes || undefined,
        createdAt: new Date()
      };

      await db.feedingLogs.add(newFeedingLog);

      return {
        success: true,
        data: newFeedingLog
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create feeding log'
      };
    }
  }

  async getFeedingLogById(logId: string, userId: string): Promise<ApiResponse<FeedingLog>> {
    try {
      const log = await db.feedingLogs.get(logId);

      if (!log) {
        return {
          success: false,
          error: 'Feeding log not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(log.animalId);
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
        data: log
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get feeding log'
      };
    }
  }

  async getFeedingLogsByAnimal(
    animalId: string,
    userId: string,
    limit?: number,
    offset?: number
  ): Promise<ApiResponse<FeedingLog[]>> {
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

      const logs = await db.getFeedingLogsByAnimal(animalId);

      // Apply pagination
      const startIndex = offset || 0;
      const endIndex = limit ? startIndex + limit : logs.length;
      const paginatedLogs = logs.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedLogs
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get feeding logs'
      };
    }
  }

  async updateFeedingLog(
    logId: string,
    userId: string,
    data: UpdateFeedingLogRequest
  ): Promise<ApiResponse<FeedingLog>> {
    try {
      const existingLog = await db.feedingLogs.get(logId);

      if (!existingLog) {
        return {
          success: false,
          error: 'Feeding log not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(existingLog.animalId);
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
        lastSyncAt: new Date()
      };

      await db.feedingLogs.update(logId, updateData);

      const updatedLog = await db.feedingLogs.get(logId);

      return {
        success: true,
        data: updatedLog!
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update feeding log'
      };
    }
  }

  async deleteFeedingLog(logId: string, userId: string): Promise<ApiResponse<boolean>> {
    try {
      const existingLog = await db.feedingLogs.get(logId);

      if (!existingLog) {
        return {
          success: false,
          error: 'Feeding log not found'
        };
      }

      // Verify user owns the animal
      const animal = await db.animals.get(existingLog.animalId);
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

      await db.feedingLogs.delete(logId);

      return {
        success: true,
        data: true
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete feeding log'
      };
    }
  }

  async getFeedingStats(animalId: string, userId: string): Promise<ApiResponse<any>> {
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

      const logs = await db.getFeedingLogsByAnimal(animalId);

      if (logs.length === 0) {
        return {
          success: true,
          data: {
            totalFeedings: 0,
            averageQuantity: 0,
            lastFeeding: null,
            foodTypes: [],
            weeklyFeedings: []
          }
        };
      }

      const totalQuantity = logs.reduce((sum, log) => sum + log.quantity, 0);
      const averageQuantity = totalQuantity / logs.length;
      const lastFeeding = logs[logs.length - 1];

      const foodTypes = logs.reduce((acc, log) => {
        acc[log.foodType] = (acc[log.foodType] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);

      // Calculate weekly feedings (last 7 days)
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      const weeklyFeedings = logs.filter(log => new Date(log.time) >= sevenDaysAgo);

      const stats = {
        totalFeedings: logs.length,
        averageQuantity: Math.round(averageQuantity * 100) / 100,
        lastFeeding,
        foodTypes,
        weeklyFeedings: weeklyFeedings.length,
        totalQuantity,
        feedingFrequency: this.calculateFeedingFrequency(logs)
      };

      return {
        success: true,
        data: stats
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get feeding stats'
      };
    }
  }

  private calculateFeedingFrequency(logs: FeedingLog[]): string {
    if (logs.length < 2) return 'Insufficient data';

    const sortedLogs = logs.sort((a, b) => new Date(a.time).getTime() - new Date(b.time).getTime());
    const intervals: number[] = [];
    for (let i = 1; i < sortedLogs.length; i++) {
      const current = new Date(sortedLogs[i]?.time || new Date());
      const previous = new Date(sortedLogs[i - 1]?.time || new Date());
      const daysDiff = (current.getTime() - previous.getTime()) / (1000 * 60 * 60 * 24);
      intervals.push(daysDiff);
    }

    const averageInterval = intervals.reduce((sum: number, interval: number) => sum + interval, 0) / intervals.length;

    if (averageInterval < 1) return 'Multiple times per day';
    if (averageInterval < 2) return 'Daily';
    if (averageInterval < 4) return 'Every 2-3 days';
    if (averageInterval < 8) return 'Weekly';
    if (averageInterval < 15) return 'Bi-weekly';
    if (averageInterval < 32) return 'Monthly';
    return 'Irregular';
  }

  async getFeedingSchedule(animalId: string, userId: string, days: number = 7): Promise<ApiResponse<any>> {
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

      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const recentLogs = await db.feedingLogs
        .where('animalId')
        .equals(animalId)
        .filter(log => new Date(log.time) >= startDate)
        .toArray();

      const schedule = recentLogs.map(log => ({
        date: log.createdAt,
        quantity: log.quantity,
        foodType: log.foodType
      }));

      return {
        success: true,
        data: {
          schedule,
          totalFeedings: recentLogs.length,
          dateRange: {
            start: startDate,
            end: new Date()
          }
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get feeding schedule'
      };
    }
  }
}

export const feedingService = new FeedingService();
