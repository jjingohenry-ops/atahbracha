import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { resolveDatabaseUserId } from '../../utils/resolveDatabaseUserId';

const prisma = new PrismaClient();
const MAX_TEXT_LENGTH = 500;
const MAX_PRESCRIPTION_ITEMS = 10;
const MAX_FREQUENCY_PER_DAY = 6;
const MAX_DURATION_DAYS = 90;
const MAX_WITHDRAWAL_DAYS = 365;
const MAX_SYNC_OPERATIONS = 50;

type DoseStatus = 'GREEN' | 'YELLOW' | 'RED';

class AppError extends Error {
  statusCode: number;

  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
  }
}

function addHours(date: Date, hours: number): Date {
  return new Date(date.getTime() + hours * 60 * 60 * 1000);
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function safeNum(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function boundedNum(value: unknown, fallback: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, safeNum(value, fallback)));
}

function limitedText(value: unknown, maxLength = MAX_TEXT_LENGTH): string {
  return String(value ?? '').trim().slice(0, maxLength);
}

function computeTotalDoses(frequencyPerDay: number, durationDays: number): number {
  return Math.max(1, frequencyPerDay) * Math.max(1, durationDays);
}

function computeNextDoseAt(startDate: Date, frequencyPerDay: number, completedDoses: number): Date {
  const intervalHours = 24 / Math.max(1, frequencyPerDay);
  return addHours(startDate, intervalHours * completedDoses);
}

function formatReminderTime(date: Date): string {
  return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
}

function computeDoseStatus(nextDoseAt: Date | null, isCompleted: boolean): DoseStatus {
  if (isCompleted) return 'GREEN';
  if (!nextDoseAt) return 'YELLOW';

  const now = Date.now();
  const dueAt = nextDoseAt.getTime();
  if (dueAt < now) return 'RED';
  if (dueAt - now <= 12 * 60 * 60 * 1000) return 'YELLOW';
  return 'GREEN';
}

function parseDate(value: unknown): Date {
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) {
    return new Date();
  }
  return date;
}

function asParam(value: string | string[] | undefined): string | null {
  if (Array.isArray(value)) {
    return value.length > 0 ? value[0] : null;
  }
  if (!value || value.trim().length == 0) return null;
  return value;
}

async function getOwnedAnimal(userId: string, animalId: string) {
  return prisma.animal.findFirst({
    where: {
      id: animalId,
      farm: { userId },
    },
    include: {
      farm: {
        select: {
          id: true,
          userId: true,
        },
      },
    },
  });
}

async function createDoseReminders(params: {
  client: any;
  userId: string;
  farmId: string;
  animalName: string;
  itemId: string;
  drugName: string;
  dosage: string;
  startDate: Date;
  frequencyPerDay: number;
  totalDoses: number;
}) {
  const marker = `[rx-dose:${params.itemId}]`;

  await params.client.reminder.deleteMany({
    where: {
      userId: params.userId,
      farmId: params.farmId,
      notes: { contains: marker },
    },
  });

  for (let doseIndex = 0; doseIndex < params.totalDoses; doseIndex += 1) {
    const doseAt = computeNextDoseAt(params.startDate, params.frequencyPerDay, doseIndex);

    await params.client.reminder.create({
      data: {
        userId: params.userId,
        farmId: params.farmId,
        title: `Give ${params.drugName}`,
        date: doseAt,
        notes: `${marker}:${doseIndex + 1}/${params.totalDoses} ${params.animalName}`,
        dosage: params.dosage,
        time: formatReminderTime(doseAt),
      },
    });
  }
}

async function upsertWithdrawalReminder(params: {
  client?: any;
  userId: string;
  farmId: string;
  animalName: string;
  itemId: string;
  drugName: string;
  withdrawalDueAt: Date | null;
}) {
  const client = params.client || prisma;
  const marker = `[rx-withdrawal:${params.itemId}]`;

  await (client as any).reminder.deleteMany({
    where: {
      userId: params.userId,
      farmId: params.farmId,
      notes: { contains: marker },
    },
  });

  if (!params.withdrawalDueAt) return;

  await (client as any).reminder.create({
    data: {
      userId: params.userId,
      farmId: params.farmId,
      title: `Withdrawal ends: ${params.drugName}`,
      date: params.withdrawalDueAt,
      notes: `${marker} ${params.animalName}`,
      dosage: null,
      time: null,
    },
  });
}

async function hydratePrescription(prescriptionId: string) {
  const prescription = await (prisma as any).prescription.findUnique({
    where: { id: prescriptionId },
    include: {
      animal: {
        select: {
          id: true,
          name: true,
          farmId: true,
          farm: { select: { userId: true } },
        },
      },
      items: {
        orderBy: { createdAt: 'asc' },
      },
      treatmentLogs: {
        orderBy: { givenAt: 'desc' },
        take: 50,
      },
    },
  });

  if (!prescription) return null;

  const items = (prescription.items as any[]).map((item) => {
    const completedDoses = safeNum(item.completedDoses, 0);
    const totalDoses = Math.max(1, safeNum(item.totalDoses, 1));
    const remainingDoses = Math.max(0, totalDoses - completedDoses);
    const nextDoseAt = item.nextDoseAt ? new Date(item.nextDoseAt) : null;
    const statusColor = computeDoseStatus(nextDoseAt, remainingDoses <= 0);

    return {
      ...item,
      remainingDoses,
      progress: Number((completedDoses / totalDoses).toFixed(3)),
      statusColor,
    };
  });

  const averageProgress = items.length == 0
    ? 0
    : items.map((item) => item.progress as number).reduce((a, b) => a + b, 0) / items.length;

  return {
    ...prescription,
    progress: Number(averageProgress.toFixed(3)),
    items,
  };
}

export const getAnimalPrescriptions = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const animalId = asParam(req.params.animalId);
    if (!animalId) {
      return res.status(400).json({ success: false, error: 'animalId is required' });
    }

    const animal = await getOwnedAnimal(userId, animalId);
    if (!animal) {
      return res.status(404).json({ success: false, error: 'Animal not found' });
    }

    const prescriptions = await (prisma as any).prescription.findMany({
      where: { animalId },
      orderBy: { createdAt: 'desc' },
      include: {
        items: { orderBy: { createdAt: 'asc' } },
        treatmentLogs: { orderBy: { givenAt: 'desc' }, take: 50 },
      },
    });

    const enriched = prescriptions.map((prescription: any) => {
      const items = (prescription.items as any[]).map((item) => {
        const completedDoses = safeNum(item.completedDoses, 0);
        const totalDoses = Math.max(1, safeNum(item.totalDoses, 1));
        const remainingDoses = Math.max(0, totalDoses - completedDoses);
        const nextDoseAt = item.nextDoseAt ? new Date(item.nextDoseAt) : null;

        return {
          ...item,
          remainingDoses,
          progress: Number((completedDoses / totalDoses).toFixed(3)),
          statusColor: computeDoseStatus(nextDoseAt, remainingDoses <= 0),
        };
      });

      const progress = items.length == 0
        ? 0
        : items.map((item) => item.progress as number).reduce((a, b) => a + b, 0) / items.length;

      return {
        ...prescription,
        progress: Number(progress.toFixed(3)),
        items,
      };
    });

    return res.status(200).json({
      success: true,
      data: enriched,
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to fetch prescriptions', details: error });
  }
};

export const getPrescriptionDrugs = async (_req: Request, res: Response) => {
  try {
    const drugs = await (prisma as any).prescriptionDrug.findMany({
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });

    return res.status(200).json({ success: true, data: drugs });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to fetch prescription drugs', details: error });
  }
};

export const createPrescription = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const animalId = req.body?.animalId?.toString();
    const diagnosis = limitedText(req.body?.diagnosis, 160);
    const vetName = limitedText(req.body?.vetName, 120);
    const notes = limitedText(req.body?.notes, 1000);
    const itemsRaw = Array.isArray(req.body?.items) ? req.body.items : [];

    if (!animalId || !diagnosis) {
      return res.status(400).json({ success: false, error: 'animalId and diagnosis are required' });
    }

    if (itemsRaw.length === 0) {
      return res.status(400).json({ success: false, error: 'At least one prescription item is required' });
    }

    if (itemsRaw.length > MAX_PRESCRIPTION_ITEMS) {
      return res.status(400).json({ success: false, error: `At most ${MAX_PRESCRIPTION_ITEMS} prescription items are allowed` });
    }

    const animal = await getOwnedAnimal(userId, animalId);
    if (!animal?.farm) {
      return res.status(404).json({ success: false, error: 'Animal not found' });
    }

    const created = await prisma.$transaction(async (tx) => {
      const prescription = await (tx as any).prescription.create({
        data: {
          animalId,
          diagnosis,
          vetName: vetName || null,
          notes: notes || null,
          status: 'ACTIVE',
        },
      });

      for (const raw of itemsRaw) {
        const drugName = limitedText(raw?.drugName, 120);
        const dosage = limitedText(raw?.dosage, 120);
        const frequencyPerDay = boundedNum(raw?.frequencyPerDay, 1, 1, MAX_FREQUENCY_PER_DAY);
        const durationDays = boundedNum(raw?.durationDays, 1, 1, MAX_DURATION_DAYS);
        const withdrawalPeriodDaysRaw = raw?.withdrawalPeriodDays;
        const withdrawalPeriodDays = withdrawalPeriodDaysRaw === null || withdrawalPeriodDaysRaw === undefined
          ? null
          : boundedNum(withdrawalPeriodDaysRaw, 0, 0, MAX_WITHDRAWAL_DAYS);
        const startDate = parseDate(raw?.startDate ?? new Date().toISOString());

        if (!drugName || !dosage) {
          continue;
        }

        const totalDoses = computeTotalDoses(frequencyPerDay, durationDays);
        const nextDoseAt = computeNextDoseAt(startDate, frequencyPerDay, 0);

        const item = await (tx as any).prescriptionItem.create({
          data: {
            prescriptionId: prescription.id,
            drugName,
            dosage,
            frequencyPerDay,
            durationDays,
            withdrawalPeriodDays,
            startDate,
            totalDoses,
            completedDoses: 0,
            nextDoseAt,
            status: 'ACTIVE',
          },
        });

        await createDoseReminders({
          client: tx,
          userId,
          farmId: animal.farm.id,
          animalName: animal.name,
          itemId: item.id,
          drugName,
          dosage,
          startDate,
          frequencyPerDay,
          totalDoses,
        });

        if (withdrawalPeriodDays !== null) {
          await upsertWithdrawalReminder({
            client: tx,
            userId,
            farmId: animal.farm.id,
            animalName: animal.name,
            itemId: item.id,
            drugName,
            withdrawalDueAt: addDays(startDate, durationDays + withdrawalPeriodDays),
          });
        }
      }

      return prescription;
    });

    const hydrated = await hydratePrescription(created.id);
    return res.status(201).json({ success: true, data: hydrated });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to create prescription', details: error });
  }
};

export const updatePrescription = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const prescriptionId = asParam(req.params.prescriptionId);
    if (!prescriptionId) {
      return res.status(400).json({ success: false, error: 'prescriptionId is required' });
    }

    const existing = await (prisma as any).prescription.findFirst({
      where: {
        id: prescriptionId,
        animal: {
          farm: { userId },
        },
      },
      select: { id: true },
    });

    if (!existing) {
      return res.status(404).json({ success: false, error: 'Prescription not found' });
    }

    const data: Record<string, unknown> = {};
    if (req.body?.diagnosis !== undefined) data.diagnosis = limitedText(req.body.diagnosis, 160);
    if (req.body?.vetName !== undefined) data.vetName = limitedText(req.body.vetName, 120) || null;
    if (req.body?.notes !== undefined) data.notes = limitedText(req.body.notes, 1000) || null;
    if (req.body?.status !== undefined) data.status = String(req.body.status || 'ACTIVE').toUpperCase();

    const updated = await (prisma as any).prescription.update({
      where: { id: prescriptionId },
      data,
    });

    return res.status(200).json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to update prescription', details: error });
  }
};

async function performMarkDoseGiven(params: {
  userId: string;
  prescriptionId: string;
  itemId: string;
  scheduledFor?: string;
  givenBy?: string;
  notes?: string;
  syncedFromOffline?: boolean;
}) {
  const { userId, prescriptionId, itemId } = params;

    const prescription = await (prisma as any).prescription.findFirst({
      where: {
        id: prescriptionId,
        animal: {
          farm: { userId },
        },
      },
      include: {
        animal: {
          select: {
            id: true,
            name: true,
            farmId: true,
            farm: { select: { id: true, userId: true } },
          },
        },
      },
    });

    if (!prescription?.animal?.farm) {
      throw new AppError(404, 'Prescription not found');
    }

    const item = await (prisma as any).prescriptionItem.findFirst({
      where: { id: itemId, prescriptionId },
    });

    if (!item) {
      throw new AppError(404, 'Prescription item not found');
    }

    const scheduledFor = params.scheduledFor ? parseDate(params.scheduledFor) : item.nextDoseAt ?? null;
    const givenBy = params.givenBy?.toString().trim();
    const notes = params.notes?.toString().trim();
    const syncedFromOffline = Boolean(params.syncedFromOffline);

    await (prisma as any).treatmentLog.create({
      data: {
        prescriptionId,
        itemId,
        givenAt: new Date(),
        scheduledFor,
        givenBy: givenBy || null,
        notes: notes || null,
        syncedFromOffline,
      },
    });

    const completedDoses = Math.min(item.totalDoses, safeNum(item.completedDoses, 0) + 1);
    const isCompleted = completedDoses >= item.totalDoses;
    const nextDoseAt = isCompleted
      ? null
      : computeNextDoseAt(new Date(item.startDate), item.frequencyPerDay, completedDoses);

    const updatedItem = await (prisma as any).prescriptionItem.update({
      where: { id: itemId },
      data: {
        completedDoses,
        nextDoseAt,
        status: isCompleted ? 'COMPLETED' : 'ACTIVE',
      },
    });

    const withdrawalDueAt = isCompleted && item.withdrawalPeriodDays != null
      ? addDays(new Date(), item.withdrawalPeriodDays)
      : null;

    await upsertWithdrawalReminder({
      userId,
      farmId: prescription.animal.farm.id,
      animalName: prescription.animal.name,
      itemId,
      drugName: item.drugName,
      withdrawalDueAt,
    });

    const hydrated = await hydratePrescription(prescriptionId);

    return {
      item: {
        ...updatedItem,
        statusColor: computeDoseStatus(nextDoseAt ? new Date(nextDoseAt) : null, isCompleted),
      },
      prescription: hydrated,
    };
}

export const markDoseGiven = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const prescriptionId = asParam(req.params.prescriptionId);
    const itemId = asParam(req.params.itemId);
    if (!prescriptionId || !itemId) {
      return res.status(400).json({ success: false, error: 'prescriptionId and itemId are required' });
    }

    const data = await performMarkDoseGiven({
      userId,
      prescriptionId,
      itemId,
      scheduledFor: req.body?.scheduledFor?.toString(),
      givenBy: req.body?.givenBy?.toString(),
      notes: req.body?.notes?.toString(),
      syncedFromOffline: Boolean(req.body?.syncedFromOffline),
    });

    return res.status(200).json({ success: true, data });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({ success: false, error: error.message });
    }
    return res.status(500).json({ success: false, error: 'Failed to mark dose as given', details: error });
  }
};

export const syncPrescriptionOperations = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const operations = Array.isArray(req.body?.operations) ? req.body.operations.slice(0, MAX_SYNC_OPERATIONS) : [];
    const results: Array<Record<string, unknown>> = [];

    for (const operation of operations) {
      const type = (operation?.type ?? '').toString();
      try {
        if (type == 'mark-dose-given') {
          const prescriptionId = operation?.payload?.prescriptionId?.toString();
          const itemId = operation?.payload?.itemId?.toString();
          if (!prescriptionId || !itemId) {
            results.push({ type, success: false, error: 'Missing prescriptionId or itemId' });
            continue;
          }

          const payload = await performMarkDoseGiven({
            userId,
            prescriptionId,
            itemId,
            scheduledFor: operation?.payload?.scheduledFor?.toString(),
            givenBy: operation?.payload?.givenBy?.toString(),
            notes: operation?.payload?.notes?.toString(),
            syncedFromOffline: true,
          });

          results.push({ type, success: true, payload });
          continue;
        }

        results.push({ type, success: false, error: 'Unsupported operation type' });
      } catch (error) {
        if (error instanceof AppError) {
          results.push({
            type,
            success: false,
            error: error.message,
            statusCode: error.statusCode,
          });
          continue;
        }
        results.push({
          type,
          success: false,
          error: 'Operation failed',
          details: String(error),
        });
      }
    }

    return res.status(200).json({ success: true, data: results });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to sync prescription operations', details: error });
  }
};
