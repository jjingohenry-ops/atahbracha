export enum AnimalType {
  DOG = 'DOG',
  CAT = 'CAT',
  CATTLE = 'CATTLE',
  CHICKEN = 'CHICKEN',
  GOAT = 'GOAT',
  SHEEP = 'SHEEP',
  PIG = 'PIG',
  RABBIT = 'RABBIT',
  FISH = 'FISH',
  HORSE = 'HORSE'
}

export enum Role {
  ADMIN = 'ADMIN',
  FARMER = 'FARMER'
}

export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE'
}

export enum GestationStatus {
  PENDING = 'PENDING',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED'
}

export enum SyncStatus {
  PENDING = 'PENDING',
  SYNCED = 'SYNCED',
  CONFLICT = 'CONFLICT',
  ERROR = 'ERROR'
}

export interface User {
  id: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: Role;
  createdAt: Date;
  updatedAt: Date;
  lastSyncAt?: Date;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: Role;
}

export interface UpdateProfileRequest {
  firstName?: string | undefined;
  lastName?: string | undefined;
}

export interface Farm {
  id: string;
  userId: string;
  name: string;
  location?: string | undefined;
  animalTypes: AnimalType[];
  createdAt: Date;
  updatedAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface Animal {
  id: string;
  farmId: string;
  name: string;
  type: AnimalType;
  age: number;
  weight: number;
  gender: Gender;
  photoUrl?: string | undefined;
  videoUrl?: string | undefined;
  notes?: string | undefined;
  createdAt: Date;
  updatedAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface FeedingLog {
  id: string;
  animalId: string;
  time: Date;
  quantity: number;
  foodType: string;
  notes?: string | undefined;
  createdAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface Gestation {
  id: string;
  animalId: string;
  startDate: Date;
  expectedDate: Date;
  status: GestationStatus;
  notes?: string | undefined;
  createdAt: Date;
  updatedAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface Treatment {
  id: string;
  animalId: string;
  drugName: string;
  dosage: string;
  date: Date;
  notes?: string | undefined;
  createdAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface CautionNote {
  id: string;
  animalId: string;
  note: string;
  createdAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface DailyActivity {
  id: string;
  animalId: string;
  activity: string;
  time: Date;
  notes?: string | undefined;
  createdAt: Date;
  lastSyncAt?: Date | undefined;
}

export interface SyncLog {
  id: string;
  entityType: string;
  entityId: string;
  action: 'CREATE' | 'UPDATE' | 'DELETE';
  status: SyncStatus;
  data?: any;
  errorMessage?: string | undefined;
  createdAt: Date;
  updatedAt?: Date | undefined;
  retryCount?: number | undefined;
}

export type SyncAction = 'CREATE' | 'UPDATE' | 'DELETE';

export const SYNC_ACTIONS = {
  CREATE: 'CREATE' as const,
  UPDATE: 'UPDATE' as const,
  DELETE: 'DELETE' as const
} as const;

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}
