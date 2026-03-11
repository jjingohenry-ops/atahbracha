import { Request, Response } from 'express';
import { PrismaClient, GestationStatus } from '@prisma/client';

const prisma = new PrismaClient();

export const getDashboardStats = async (req: Request, res: Response) => {
  try {
    // Total animals
    const totalAnimals = await prisma.animal.count();

    // Pregnant animals (gestation in progress or pending)
    const pregnant = await prisma.gestation.count({
      where: {
        OR: [
          { status: GestationStatus.PENDING },
          { status: GestationStatus.IN_PROGRESS },
        ],
      },
    });

    // Sick animals (animals with at least one treatment in the last 30 days)
    const sick = await prisma.animal.count({
      where: {
        treatments: {
          some: {
            date: {
              gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
            },
          },
        },
      },
    });

    // Upcoming tasks (treatments or gestations due in next 7 days)
    const now = new Date();
    const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const upcomingTasks = await prisma.treatment.count({
      where: {
        date: {
          gte: now,
          lte: nextWeek,
        },
      },
    });

    // AI Insights (placeholder)
    const aiInsights = {
      message: "Your herd's milk production is projected to increase by 5% next week based on current feeding patterns."
    };

    // Urgent alerts (recent caution notes, treatments, gestations)
    const alerts = [
      // Treatments pending
      {
        type: 'Treatments',
        count: await prisma.treatment.count({
          where: { date: { gte: now } },
        }),
        label: 'pending tasks',
      },
      // Feeding (next feeding in 2h, placeholder)
      {
        type: 'Feeding',
        next: '2h (Main Barn)',
      },
      // Breeding cycles (gestations due today)
      {
        type: 'Breeding Cycles',
        count: await prisma.gestation.count({
          where: {
            expectedDate: {
              gte: new Date(now.setHours(0,0,0,0)),
              lte: new Date(now.setHours(23,59,59,999)),
            },
          },
        }),
        label: 'due today',
      },
      // Vaccinations (scheduled for Friday, placeholder)
      {
        type: 'Vaccinations',
        count: 12,
        label: 'scheduled for Fri',
      },
    ];

    // Recent activity (last 2 daily activities)
    const recentActivity = await prisma.dailyActivity.findMany({
      orderBy: { time: 'desc' },
      take: 2,
      include: { animal: true },
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
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dashboard data', details: error });
  }
};
