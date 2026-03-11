import Dexie, { Table } from 'dexie';
import {
  User,
  Farm,
  Animal,
  FeedingLog,
  Gestation,
  Treatment,
  CautionNote,
  DailyActivity,
  SyncLog,
  GestationStatus,
  SyncStatus
} from '../types';

export class AnimalManagementDB extends Dexie {
  users!: Table<User>;
  farms!: Table<Farm>;
  animals!: Table<Animal>;
  feedingLogs!: Table<FeedingLog>;
  gestations!: Table<Gestation>;
  treatments!: Table<Treatment>;
  cautionNotes!: Table<CautionNote>;
  dailyActivities!: Table<DailyActivity>;
  syncLogs!: Table<SyncLog>;

  constructor() {
    super('AnimalManagementDB');

    this.version(1).stores({
      users: '++id, email, role, createdAt, updatedAt, lastSyncAt',
      farms: '++id, userId, name, animalTypes, createdAt, updatedAt, lastSyncAt',
      animals: '++id, farmId, name, type, age, weight, gender, createdAt, updatedAt, lastSyncAt',
      feedingLogs: '++id, animalId, time, quantity, foodType, createdAt, lastSyncAt',
      gestations: '++id, animalId, startDate, expectedDate, status, createdAt, updatedAt, lastSyncAt',
      treatments: '++id, animalId, drugName, dosage, date, createdAt, lastSyncAt',
      cautionNotes: '++id, animalId, note, createdAt, lastSyncAt',
      dailyActivities: '++id, animalId, activity, time, createdAt, lastSyncAt',
      syncLogs: '++id, entityType, entityId, action, status, createdAt, updatedAt, retryCount'
    });

    // Hooks for automatic sync logging
    this.users.hook('creating', this.createSyncHook('users'));
    this.users.hook('updating', this.createSyncHook('users'));
    this.users.hook('deleting', this.createSyncHook('users'));

    this.farms.hook('creating', this.createSyncHook('farms'));
    this.farms.hook('updating', this.createSyncHook('farms'));
    this.farms.hook('deleting', this.createSyncHook('farms'));

    this.animals.hook('creating', this.createSyncHook('animals'));
    this.animals.hook('updating', this.createSyncHook('animals'));
    this.animals.hook('deleting', this.createSyncHook('animals'));

    this.feedingLogs.hook('creating', this.createSyncHook('feedingLogs'));
    this.feedingLogs.hook('updating', this.createSyncHook('feedingLogs'));
    this.feedingLogs.hook('deleting', this.createSyncHook('feedingLogs'));

    this.gestations.hook('creating', this.createSyncHook('gestations'));
    this.gestations.hook('updating', this.createSyncHook('gestations'));
    this.gestations.hook('deleting', this.createSyncHook('gestations'));

    this.treatments.hook('creating', this.createSyncHook('treatments'));
    this.treatments.hook('updating', this.createSyncHook('treatments'));
    this.treatments.hook('deleting', this.createSyncHook('treatments'));

    this.cautionNotes.hook('creating', this.createSyncHook('cautionNotes'));
    this.cautionNotes.hook('updating', this.createSyncHook('cautionNotes'));
    this.cautionNotes.hook('deleting', this.createSyncHook('cautionNotes'));

    this.dailyActivities.hook('creating', this.createSyncHook('dailyActivities'));
    this.dailyActivities.hook('updating', this.createSyncHook('dailyActivities'));
    this.dailyActivities.hook('deleting', this.createSyncHook('dailyActivities'));
  }

  private createSyncHook(entityType: string) {
    return (primaryKey: any, obj: any, trans: any) => {
      if (!obj) return; // Handle delete operations
      
      const action: 'CREATE' | 'UPDATE' | 'DELETE' = obj ? 'UPDATE' : 'DELETE';
      const syncLog: SyncLog = {
        id: crypto.randomUUID(),
        entityType,
        entityId: typeof primaryKey === 'object' ? primaryKey.id : primaryKey,
        action,
        status: SyncStatus.PENDING,
        data: obj,
        createdAt: new Date(),
        retryCount: 0
      };

      // Add sync log to transaction
      trans.table('syncLogs').add(syncLog);
    };
  }

  // Helper methods for common queries
  async getAnimalsByFarm(farmId: string): Promise<Animal[]> {
    return this.animals.where('farmId').equals(farmId).toArray();
  }

  async getFeedingLogsByAnimal(animalId: string): Promise<FeedingLog[]> {
    return this.feedingLogs.where('animalId').equals(animalId).reverse().sortBy('time');
  }

  async getActiveGestation(animalId: string): Promise<Gestation | undefined> {
    return this.gestations
      .where('animalId')
      .equals(animalId)
      .and(gestation => gestation.status === GestationStatus.IN_PROGRESS)
      .first();
  }

  async getPendingSyncLogs(): Promise<SyncLog[]> {
    return this.syncLogs
      .where('status')
      .equals(SyncStatus.PENDING)
      .or('status')
      .equals(SyncStatus.ERROR)
      .toArray();
  }

  async markSyncAsCompleted(syncLogId: string): Promise<void> {
    await this.syncLogs.update(syncLogId, {
      status: SyncStatus.SYNCED,
      updatedAt: new Date()
    });
  }

  async markSyncAsError(syncLogId: string, errorMessage: string): Promise<void> {
    const currentLog = await this.syncLogs.get(syncLogId);
    const retryCount = (currentLog?.retryCount || 0) + 1;
    
    await this.syncLogs.update(syncLogId, {
      status: SyncStatus.ERROR,
      errorMessage,
      retryCount,
      updatedAt: new Date()
    });
  }
}

export const db = new AnimalManagementDB();
