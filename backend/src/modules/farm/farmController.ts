import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getFarmsByUser = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'User not authenticated' });
    }
    const farms = await prisma.farm.findMany({ where: { userId } });
    res.json({ success: true, data: farms });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to fetch farms', details: error });
  }
};
