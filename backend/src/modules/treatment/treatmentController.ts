import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

console.log('🔍 Treatment controller module loaded');

export const getReminders = async (req: Request, res: Response) => {
  try {
    const { date } = req.query; // expecting yyyy-mm-dd
    const whereClause: any = {};
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
    const { title, date, time, dosage, notes } = req.body;
    const reminder = await (prisma as any).reminder.create({
      data: {
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
