import { Request, Response } from 'express';
import { PrismaClient, GestationStatus } from '@prisma/client';
import { resolveDatabaseUserId } from '../../utils/resolveDatabaseUserId';
import { boundedNumber, limitedText, optionalLimitedText } from '../../utils/input';

const prisma = new PrismaClient();

const parseOptionalDate = (value: unknown): Date | null => {
  if (value === null || value === undefined) {
    return null;
  }

  const date = new Date(String(value));
  return Number.isNaN(date.getTime()) ? null : date;
};

const normalizeScanTag = (tag: string): string => {
  return tag.trim().replace(/\s+/g, '-').toUpperCase();
};

const resolveOwnedFarmId = async (
  userId: string,
  requestedFarmId: string | undefined,
): Promise<string | null> => {
  if (!requestedFarmId) {
    return null;
  }

  const farm = await prisma.farm.findFirst({
    where: { id: requestedFarmId, userId },
    select: { id: true },
  });

  return farm?.id ?? null;
};

const ensureAnimalOwnership = async (
  userId: string,
  farmId: string,
  animalId: string,
) => {
  return prisma.animal.findFirst({
    where: {
      id: animalId,
      farmId,
      farm: { userId },
    },
    select: {
      id: true,
      name: true,
      notes: true,
    },
  });
};

export const recordTreatment = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const farmId = req.body?.farmId?.toString();
    const animalId = req.body?.animalId?.toString();
    const drugName = limitedText(req.body?.drugName, 120);
    const dosage = limitedText(req.body?.dosage, 120);
    const notes = optionalLimitedText(req.body?.notes, 1000);
    const date = parseOptionalDate(req.body?.date) ?? new Date();

    if (!farmId || !animalId || !drugName || !dosage) {
      return res.status(400).json({
        success: false,
        error: 'farmId, animalId, drugName and dosage are required',
      });
    }

    const ownedFarmId = await resolveOwnedFarmId(userId, farmId);
    if (!ownedFarmId) {
      return res.status(403).json({ success: false, error: 'Selected farm is not owned by this account' });
    }

    const animal = await ensureAnimalOwnership(userId, ownedFarmId, animalId);
    if (!animal) {
      return res.status(404).json({ success: false, error: 'Animal not found in selected farm' });
    }

    const treatment = await prisma.treatment.create({
      data: {
        animalId: animal.id,
        drugName,
        dosage,
        date,
        notes: notes || null,
      },
    });

    await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity: 'Treatment',
        time: date,
        notes: `${drugName} (${dosage})${notes ? ` - ${notes}` : ''}`,
      },
    });

    return res.status(201).json({ success: true, data: treatment });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to record treatment', details: error });
  }
};

export const logFeeding = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const farmId = req.body?.farmId?.toString();
    const animalId = req.body?.animalId?.toString();
    const foodType = limitedText(req.body?.foodType, 120);
    const notes = optionalLimitedText(req.body?.notes, 1000);
    const quantity = boundedNumber(req.body?.quantity, Number.NaN, 0, 1000000);
    const time = parseOptionalDate(req.body?.time) ?? new Date();

    if (!farmId || !animalId || !foodType || !Number.isFinite(quantity) || quantity <= 0) {
      return res.status(400).json({
        success: false,
        error: 'farmId, animalId, foodType and a positive quantity are required',
      });
    }

    const ownedFarmId = await resolveOwnedFarmId(userId, farmId);
    if (!ownedFarmId) {
      return res.status(403).json({ success: false, error: 'Selected farm is not owned by this account' });
    }

    const animal = await ensureAnimalOwnership(userId, ownedFarmId, animalId);
    if (!animal) {
      return res.status(404).json({ success: false, error: 'Animal not found in selected farm' });
    }

    const feedingLog = await prisma.feedingLog.create({
      data: {
        animalId: animal.id,
        time,
        quantity,
        foodType,
        notes: notes || null,
      },
    });

    await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity: 'Feeding',
        time,
        notes: `${foodType} (${quantity} kg)${notes ? ` - ${notes}` : ''}`,
      },
    });

    return res.status(201).json({ success: true, data: feedingLog });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to log feeding', details: error });
  }
};

export const recordPregnancy = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const farmId = req.body?.farmId?.toString();
    const animalId = req.body?.animalId?.toString();
    const notes = optionalLimitedText(req.body?.notes, 1000);
    const startDate = parseOptionalDate(req.body?.startDate) ?? new Date();
    const expectedDate = parseOptionalDate(req.body?.expectedDate);

    if (!farmId || !animalId || !expectedDate) {
      return res.status(400).json({
        success: false,
        error: 'farmId, animalId and expectedDate are required',
      });
    }

    if (expectedDate <= startDate) {
      return res.status(400).json({ success: false, error: 'expectedDate must be after startDate' });
    }

    const ownedFarmId = await resolveOwnedFarmId(userId, farmId);
    if (!ownedFarmId) {
      return res.status(403).json({ success: false, error: 'Selected farm is not owned by this account' });
    }

    const animal = await ensureAnimalOwnership(userId, ownedFarmId, animalId);
    if (!animal) {
      return res.status(404).json({ success: false, error: 'Animal not found in selected farm' });
    }

    const gestation = await prisma.gestation.create({
      data: {
        animalId: animal.id,
        startDate,
        expectedDate,
        status: GestationStatus.IN_PROGRESS,
        notes: notes || null,
      },
    });

    await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity: 'Pregnancy Recorded',
        time: startDate,
        notes: `Expected date: ${expectedDate.toISOString().split('T')[0]}${notes ? ` - ${notes}` : ''}`,
      },
    });

    return res.status(201).json({ success: true, data: gestation });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to record pregnancy', details: error });
  }
};

export const addActivity = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const farmId = req.body?.farmId?.toString();
    const animalId = req.body?.animalId?.toString();
    const activity = limitedText(req.body?.activity, 160);
    const notes = optionalLimitedText(req.body?.notes, 1000);
    const time = parseOptionalDate(req.body?.time) ?? new Date();

    if (!farmId || !animalId || !activity) {
      return res.status(400).json({ success: false, error: 'farmId, animalId and activity are required' });
    }

    const ownedFarmId = await resolveOwnedFarmId(userId, farmId);
    if (!ownedFarmId) {
      return res.status(403).json({ success: false, error: 'Selected farm is not owned by this account' });
    }

    const animal = await ensureAnimalOwnership(userId, ownedFarmId, animalId);
    if (!animal) {
      return res.status(404).json({ success: false, error: 'Animal not found in selected farm' });
    }

    const dailyActivity = await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity,
        time,
        notes: notes || null,
      },
    });

    return res.status(201).json({ success: true, data: dailyActivity });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to record activity', details: error });
  }
};

export const scanTag = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const farmId = req.body?.farmId?.toString();
    const animalId = req.body?.animalId?.toString();
    const rawTag = req.body?.tag?.toString().trim();

    if (!farmId || !animalId || !rawTag) {
      return res.status(400).json({ success: false, error: 'farmId, animalId and tag are required' });
    }

    const ownedFarmId = await resolveOwnedFarmId(userId, farmId);
    if (!ownedFarmId) {
      return res.status(403).json({ success: false, error: 'Selected farm is not owned by this account' });
    }

    const animal = await ensureAnimalOwnership(userId, ownedFarmId, animalId);
    if (!animal) {
      return res.status(404).json({ success: false, error: 'Animal not found in selected farm' });
    }

    const tag = normalizeScanTag(rawTag);
    const existingNotes = animal.notes?.trim() ?? '';
    const notesWithoutTag = existingNotes
      .split('\n')
      .filter((line) => !line.trim().startsWith('Tag:'))
      .join('\n')
      .trim();
    const updatedNotes = [notesWithoutTag, `Tag: ${tag}`]
      .filter((part: string) => part.trim().length > 0)
      .join('\n');

    const updatedAnimal = await prisma.animal.update({
      where: { id: animal.id },
      data: { notes: updatedNotes },
    });

    await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity: 'Tag Scanned',
        time: new Date(),
        notes: `Tag assigned: ${tag}`,
      },
    });

    return res.status(200).json({ success: true, data: updatedAnimal });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to scan tag', details: error });
  }
};

export const getDashboardStats = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req, prisma);
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const requestedFarmId = req.query.farmId?.toString();
    const ownedFarmId = await resolveOwnedFarmId(userId, requestedFarmId);
    if (requestedFarmId && !ownedFarmId) {
      res.status(403).json({ error: 'Selected farm is not owned by this account' });
      return;
    }

    const now = new Date();
    const farmFilter = ownedFarmId ? { id: ownedFarmId, userId } : { userId };
    const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(now);
    endOfDay.setHours(23, 59, 59, 999);

    const trendStart = new Date(now);
    trendStart.setDate(trendStart.getDate() - 6);
    trendStart.setHours(0, 0, 0, 0);

    const [
      totalAnimals,
      pregnant,
      sick,
      upcomingTasks,
      upcomingGestations,
      nextFeeding,
      upcomingVaccinations,
      pendingTreatments,
      dueTodayBreedingCycles,
      recentActivity,
      recentTrendActivities,
      animalSnapshot,
    ] = await Promise.all([
      prisma.animal.count({
        where: {
          farm: farmFilter,
        },
      }),
      prisma.gestation.count({
        where: {
          animal: {
            farm: farmFilter,
          },
          OR: [
            { status: GestationStatus.PENDING },
            { status: GestationStatus.IN_PROGRESS },
          ],
        },
      }),
      prisma.animal.count({
        where: {
          farm: farmFilter,
          treatments: {
            some: {
              date: {
                gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
              },
            },
          },
        },
      }),
      prisma.treatment.count({
        where: {
          animal: {
            farm: farmFilter,
          },
          date: {
            gte: now,
            lte: nextWeek,
          },
        },
      }),
      prisma.gestation.count({
        where: {
          animal: {
            farm: farmFilter,
          },
          expectedDate: {
            gte: now,
            lte: nextWeek,
          },
        },
      }),
      prisma.feedingLog.findFirst({
        where: {
          animal: {
            farm: farmFilter,
          },
          time: {
            gte: now,
          },
        },
        orderBy: {
          time: 'asc',
        },
        include: {
          animal: {
            select: {
              name: true,
            },
          },
        },
      }),
      prisma.treatment.count({
        where: {
          animal: {
            farm: farmFilter,
          },
          date: {
            gte: now,
            lte: nextWeek,
          },
          OR: [
            { drugName: { contains: 'vacc', mode: 'insensitive' } },
            { notes: { contains: 'vacc', mode: 'insensitive' } },
          ],
        },
      }),
      prisma.treatment.count({
        where: {
          animal: {
            farm: farmFilter,
          },
          date: { gte: now },
        },
      }),
      prisma.gestation.count({
        where: {
          animal: {
            farm: farmFilter,
          },
          expectedDate: {
            gte: startOfDay,
            lte: endOfDay,
          },
        },
      }),
      prisma.dailyActivity.findMany({
        where: {
          animal: {
            farm: farmFilter,
          },
        },
        orderBy: { time: 'desc' },
        take: 2,
        include: { animal: true },
      }),
      prisma.dailyActivity.findMany({
        where: {
          animal: {
            farm: farmFilter,
          },
          time: {
            gte: trendStart,
            lte: now,
          },
        },
        select: {
          time: true,
          notes: true,
        },
      }),
      prisma.animal.findMany({
        where: {
          farm: farmFilter,
        },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: {
          gestations: {
            where: {
              OR: [
                { status: GestationStatus.PENDING },
                { status: GestationStatus.IN_PROGRESS },
              ],
            },
            orderBy: { expectedDate: 'asc' },
            take: 1,
          },
        },
      }),
    ]);

    const aiInsights = {
      message: [
        `You currently have ${totalAnimals} animal(s) in the system.`,
        `${pregnant} pregnancy case(s) are active.`,
        `${sick} animal(s) received treatment in the last 30 days.`,
        `${upcomingTasks + upcomingGestations} task(s) are scheduled in the next 7 days.`,
      ].join(' '),
    };

    const alerts = [
      {
        type: 'Treatments',
        count: pendingTreatments,
        label: 'pending tasks',
      },
      {
        type: 'Feeding',
        next: nextFeeding
          ? `${nextFeeding.time.toISOString()}${nextFeeding.animal?.name ? ` (${nextFeeding.animal.name})` : ''}`
          : 'No upcoming feeding',
      },
      {
        type: 'Breeding Cycles',
        count: dueTodayBreedingCycles,
        label: 'due today',
      },
      {
        type: 'Vaccinations',
        count: upcomingVaccinations,
        label: 'scheduled in 7 days',
      },
    ];

    const activityTrend = Array.from({ length: 7 }, (_unused, index) => {
      const date = new Date(trendStart);
      date.setDate(trendStart.getDate() + index);
      const dayStart = new Date(date);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(date);
      dayEnd.setHours(23, 59, 59, 999);

      const count = recentTrendActivities.filter((item) => item.time >= dayStart && item.time <= dayEnd).length;
      return {
        day: dayStart.toISOString().split('T')[0],
        count,
      };
    });

    const milkTrend = Array.from({ length: 7 }, (_unused, index) => {
      const date = new Date(trendStart);
      date.setDate(trendStart.getDate() + index);
      const dayStart = new Date(date);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(date);
      dayEnd.setHours(23, 59, 59, 999);

      let total = 0;
      for (const item of recentTrendActivities) {
        if (item.time < dayStart || item.time > dayEnd) {
          continue;
        }
        const notes = item.notes?.toLowerCase() ?? '';
        const match = notes.match(/(\d+(?:\.\d+)?)\s*(l|litre|liter|liters|litres)/i);
        if (match) {
          total += Number(match[1]);
        }
      }

      return {
        day: dayStart.toISOString().split('T')[0],
        liters: Number(total.toFixed(2)),
      };
    });

    res.json({
      stats: {
        totalAnimals,
        pregnant,
        sick,
        upcomingTasks,
      },
      aiInsights,
      alerts,
      recentActivity,
      trends: {
        activity: activityTrend,
        milk: milkTrend,
      },
      animalSnapshot,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dashboard data', details: error });
  }
};
