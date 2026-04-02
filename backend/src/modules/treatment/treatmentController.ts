import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

console.log('🔍 Treatment controller module loaded');

export const getReminders = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const requestedFarmId = req.query.farmId?.toString();
    let selectedFarmId: string | undefined;
    if (requestedFarmId) {
      const farm = await prisma.farm.findFirst({
        where: { id: requestedFarmId, userId },
        select: { id: true },
      });
      if (!farm) {
        return res.status(403).json({ success: false, error: 'Selected farm is not owned by this account' });
      }
      selectedFarmId = farm.id;
    }

    const { date } = req.query; // expecting yyyy-mm-dd
    const whereClause: any = { userId };
    if (selectedFarmId) {
      whereClause.farmId = selectedFarmId;
    }
    if (date && typeof date === 'string') {
      const parsed = new Date(date);
      const start = new Date(new Date(parsed).setHours(0, 0, 0, 0));
      const end = new Date(new Date(parsed).setHours(23, 59, 59, 999));
      whereClause.date = { gte: start, lte: end };
    }
    const reminders = await (prisma as any).reminder.findMany({
      where: whereClause,
      orderBy: { date: 'asc' },
    });
    res.json({ success: true, data: reminders });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to fetch reminders', details: error });
  }
};

export const addReminder = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const { title, date, time, dosage, notes, farmId } = req.body;

    if (!farmId || typeof farmId !== 'string') {
      return res.status(400).json({ success: false, error: 'farmId is required' });
    }

    const farm = await prisma.farm.findFirst({
      where: { id: farmId, userId },
      select: { id: true },
    });

    if (!farm) {
      return res.status(403).json({ success: false, error: 'You cannot add reminders to this farm' });
    }

    const reminder = await (prisma as any).reminder.create({
      data: {
        userId,
        farmId,
        title: title || 'Untitled',
        date: new Date(date),
        time: time || null,
        dosage: dosage || null,
        notes: notes || null,
      },
    });
    res.status(201).json({ success: true, data: reminder });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to add reminder', details: error });
  }
};

export const completeReminder = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const reminderId = req.params.id;
    if (!reminderId) {
      return res.status(400).json({ success: false, error: 'Reminder id is required' });
    }

    const reminder = await (prisma as any).reminder.findFirst({
      where: {
        id: reminderId,
        userId,
      },
      select: {
        id: true,
      },
    });

    if (!reminder) {
      return res.status(404).json({ success: false, error: 'Reminder not found' });
    }

    await (prisma as any).reminder.delete({
      where: { id: reminderId },
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to complete reminder', details: error });
  }
};
