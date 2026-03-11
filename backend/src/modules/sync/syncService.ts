import { db } from '../../config/dexie';
import { SyncLog, SyncStatus, SYNC_ACTIONS } from '../../types';

// Initialize Prisma client when needed
let prisma: any = null;

const getPrismaClient = () => {
  if (!prisma) {
    try {
      const { PrismaClient } = require('@prisma/client');
      prisma = new PrismaClient();
    } catch (error) {
      console.warn('Prisma client not available, running in offline mode');
      return null;
    }
  }
  return prisma;
};

export class SyncService {
  private static instance: SyncService;
  private isSyncing = false;
  private syncInterval: NodeJS.Timeout | null = null;

  private constructor() {}

  static getInstance(): SyncService {
    if (!SyncService.instance) {
      SyncService.instance = new SyncService();
    }
    return SyncService.instance;
  }

  async startAutoSync(intervalMs: number = 30000): Promise<void> {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
    }

    this.syncInterval = setInterval(async () => {
      if (!this.isSyncing) {
        await this.syncPendingChanges();
      }
    }, intervalMs);
  }

  stopAutoSync(): void {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
      this.syncInterval = null;
    }
  }

  async syncPendingChanges(): Promise<void> {
    if (this.isSyncing) {
      console.log('Sync already in progress, skipping...');
      return;
    }

    const client = getPrismaClient();
    if (!client) {
      console.log('Prisma client not available, skipping sync');
      return;
    }

    this.isSyncing = true;
    console.log('Starting sync process...');

    try {
      const pendingLogs = await db.getPendingSyncLogs();
      
      for (const log of pendingLogs) {
        try {
          await this.processSyncLog(log, client);
          await db.markSyncAsCompleted(log.id);
          console.log(`Successfully synced ${log.entityType} ${log.entityId}`);
        } catch (error) {
          console.error(`Failed to sync ${log.entityType} ${log.entityId}:`, error);
          await db.markSyncAsError(log.id, error instanceof Error ? error.message : 'Unknown error');
        }
      }

      console.log(`Sync process completed. Processed ${pendingLogs.length} changes.`);
    } catch (error) {
      console.error('Sync process failed:', error);
    } finally {
      this.isSyncing = false;
    }
  }

  private async processSyncLog(log: SyncLog, client: any): Promise<void> {
    switch (log.entityType) {
      case 'users':
        await this.syncUser(log, client);
        break;
      case 'farms':
        await this.syncFarm(log, client);
        break;
      case 'animals':
        await this.syncAnimal(log, client);
        break;
      case 'feedingLogs':
        await this.syncFeedingLog(log, client);
        break;
      case 'gestations':
        await this.syncGestation(log, client);
        break;
      case 'treatments':
        await this.syncTreatment(log, client);
        break;
      case 'cautionNotes':
        await this.syncCautionNote(log, client);
        break;
      case 'dailyActivities':
        await this.syncDailyActivity(log, client);
        break;
      default:
        throw new Error(`Unknown entity type: ${log.entityType}`);
    }
  }

  private async syncUser(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for user sync');
        await client.user.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.user.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncFarm(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for farm sync');
        await client.farm.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.farm.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncAnimal(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for animal sync');
        await client.animal.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.animal.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncFeedingLog(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for feeding log sync');
        await client.feedingLog.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.feedingLog.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncGestation(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for gestation sync');
        await client.gestation.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.gestation.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncTreatment(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for treatment sync');
        await client.treatment.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.treatment.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncCautionNote(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for caution note sync');
        await client.cautionNote.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.cautionNote.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  private async syncDailyActivity(log: SyncLog, client: any): Promise<void> {
    switch (log.action) {
      case SYNC_ACTIONS.CREATE:
      case SYNC_ACTIONS.UPDATE:
        if (!log.data) throw new Error('No data provided for daily activity sync');
        await client.dailyActivity.upsert({
          where: { id: log.entityId },
          update: log.data,
          create: { ...log.data, id: log.entityId }
        });
        break;
      case SYNC_ACTIONS.DELETE:
        await client.dailyActivity.delete({
          where: { id: log.entityId }
        });
        break;
    }
  }

  async forceFullSync(): Promise<void> {
    console.log('Starting full sync...');
    
    try {
      // Sync all users
      const users = await db.users.toArray();
      for (const user of users) {
        await prisma.user.upsert({
          where: { id: user.id },
          update: user,
          create: user
        });
      }

      // Sync all farms
      const farms = await db.farms.toArray();
      for (const farm of farms) {
        await prisma.farm.upsert({
          where: { id: farm.id },
          update: farm,
          create: farm
        });
      }

      // Sync all animals
      const animals = await db.animals.toArray();
      for (const animal of animals) {
        await prisma.animal.upsert({
          where: { id: animal.id },
          update: animal,
          create: animal
        });
      }

      // Sync all related data
      const feedingLogs = await db.feedingLogs.toArray();
      for (const log of feedingLogs) {
        await prisma.feedingLog.upsert({
          where: { id: log.id },
          update: log,
          create: log
        });
      }

      const gestations = await db.gestations.toArray();
      for (const gestation of gestations) {
        await prisma.gestation.upsert({
          where: { id: gestation.id },
          update: gestation,
          create: gestation
        });
      }

      const treatments = await db.treatments.toArray();
      for (const treatment of treatments) {
        await prisma.treatment.upsert({
          where: { id: treatment.id },
          update: treatment,
          create: treatment
        });
      }

      const cautionNotes = await db.cautionNotes.toArray();
      for (const note of cautionNotes) {
        await prisma.cautionNote.upsert({
          where: { id: note.id },
          update: note,
          create: note
        });
      }

      const dailyActivities = await db.dailyActivities.toArray();
      for (const activity of dailyActivities) {
        await prisma.dailyActivity.upsert({
          where: { id: activity.id },
          update: activity,
          create: activity
        });
      }

      console.log('Full sync completed successfully');
    } catch (error) {
      console.error('Full sync failed:', error);
      throw error;
    }
  }

  async getSyncStatus(): Promise<{
    pendingCount: number;
    errorCount: number;
    lastSyncTime?: Date;
    isSyncing: boolean;
  }> {
    const pendingLogs = await db.getPendingSyncLogs();
    const errorCount = pendingLogs.filter(log => log.status === SyncStatus.ERROR).length;
    const pendingCount = pendingLogs.filter(log => log.status === SyncStatus.PENDING).length;

    return {
      pendingCount,
      errorCount,
      lastSyncTime: new Date(), // This could be stored in a separate table
      isSyncing: this.isSyncing
    };
  }
}

export const syncService = SyncService.getInstance();
