import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { limitedText, optionalLimitedText, productionError } from '../../utils/input';

const prisma = new PrismaClient();

const resolveDatabaseUserId = async (req: Request): Promise<string | null> => {
  const authUser = (req as any).user;
  const firebaseUid = authUser?.uid || authUser?.userId;
  const email = authUser?.email?.toString().trim().toLowerCase();

  if (!firebaseUid) {
    return null;
  }

  const userById = await prisma.user.findUnique({
    where: { id: firebaseUid },
    select: { id: true },
  });
  if (userById) {
    return userById.id;
  }

  if (email) {
    const userByEmail = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (userByEmail) {
      return userByEmail.id;
    }
  }

  const displayName = authUser?.name?.toString().trim() ?? '';
  const names = displayName.length > 0 ? displayName.split(/\s+/) : [];
  const fallbackEmail = `firebase_${firebaseUid}@local.invalid`;
  const newUser = await prisma.user.create({
    data: {
      id: firebaseUid,
      email: email || fallbackEmail,
      password: 'firebase-auth-user',
      firstName: names[0] || 'Farmer',
      lastName: names.slice(1).join(' '),
    },
    select: { id: true },
  });

  return newUser.id;
};

export const getFarmsByUser = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'User not authenticated' });
    }
    const farms = await prisma.farm.findMany({ where: { userId } });
    res.json({ success: true, data: farms });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to fetch farms', details: error });
  }
};

export const createFarm = async (req: Request, res: Response) => {
  try {
    const userId = await resolveDatabaseUserId(req);
    if (!userId) {
      return res.status(401).json({ success: false, error: 'User not authenticated' });
    }

    const name = limitedText(req.body?.name, 120);
    const location = optionalLimitedText(req.body?.location, 180);
    const sizeValue = req.body?.size;
    const size = sizeValue != null ? Number(sizeValue) : null;

    if (!name) {
      return res.status(400).json({ success: false, error: 'Farm name is required' });
    }

    if (size != null && (!Number.isFinite(size) || size < 0 || size > 100000000)) {
      return res.status(400).json({ success: false, error: 'Farm size must be a number' });
    }

    const farm = await prisma.farm.create({
      data: {
        userId,
        name,
        location,
        size,
      },
    });

    return res.status(201).json({ success: true, data: farm });
  } catch (error) {
    console.error('createFarm error:', error);
    return res.status(500).json(productionError(error, 'Failed to create farm'));
  }
};
