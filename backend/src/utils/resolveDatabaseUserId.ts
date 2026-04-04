import { Request } from 'express';
import { PrismaClient } from '@prisma/client';

export const resolveDatabaseUserId = async (
  req: Request,
  prisma: PrismaClient,
): Promise<string | null> => {
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
