import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import path from 'path';
import { config } from '../../config/env';

const prisma = new PrismaClient();
const s3ClientConfig: ConstructorParameters<typeof S3Client>[0] = {
  region: config.AWS_REGION,
};

if (config.AWS_ACCESS_KEY_ID && config.AWS_SECRET_ACCESS_KEY) {
  s3ClientConfig.credentials = {
    accessKeyId: config.AWS_ACCESS_KEY_ID,
    secretAccessKey: config.AWS_SECRET_ACCESS_KEY,
  };
}

const s3Client = new S3Client(s3ClientConfig);

export const getAnimals = async (req: Request, res: Response) => {
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

    const animals = await prisma.animal.findMany({
      where: {
        farm: {
          userId,
        },
        ...(selectedFarmId ? { farmId: selectedFarmId } : {}),
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    res.json({ success: true, data: animals });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to fetch animals', details: error });
  }
};

export const addAnimal = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const farmId = req.body?.farmId as string | undefined;
    if (!farmId) {
      return res.status(400).json({ success: false, error: 'farmId is required' });
    }

    const farm = await prisma.farm.findFirst({
      where: {
        id: farmId,
        userId,
      },
      select: { id: true },
    });

    if (!farm) {
      return res.status(403).json({ success: false, error: 'You cannot add animals to this farm' });
    }

    const name = req.body?.name?.toString().trim();
    const type = req.body?.type?.toString().trim().toUpperCase();
    const gender = req.body?.gender?.toString().trim().toUpperCase();
    const age = Number(req.body?.age);
    const weight = Number(req.body?.weight);

    const allowedTypes = new Set([
      'DOG',
      'CAT',
      'CATTLE',
      'CHICKEN',
      'GOAT',
      'SHEEP',
      'PIG',
      'RABBIT',
      'FISH',
      'HORSE',
    ]);
    const allowedGenders = new Set(['MALE', 'FEMALE']);

    if (!name) {
      return res.status(400).json({ success: false, error: 'Animal name is required' });
    }

    if (!type || !allowedTypes.has(type)) {
      return res.status(400).json({ success: false, error: 'Invalid animal type' });
    }

    if (!gender || !allowedGenders.has(gender)) {
      return res.status(400).json({ success: false, error: 'Invalid animal gender' });
    }

    if (!Number.isFinite(age) || age < 0) {
      return res.status(400).json({ success: false, error: 'Invalid animal age' });
    }

    if (!Number.isFinite(weight) || weight < 0) {
      return res.status(400).json({ success: false, error: 'Invalid animal weight' });
    }

    const animal = await prisma.animal.create({
      data: {
        farmId: farm.id,
        name,
        type: type as any,
        gender: gender as any,
        age,
        weight,
        photoUrl: req.body?.photoUrl?.toString().trim() || null,
        videoUrl: req.body?.videoUrl?.toString().trim() || null,
        notes: req.body?.notes?.toString().trim() || null,
      },
    });
    res.status(201).json({ success: true, data: animal });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to add animal', details: error });
  }
};

export const updateAnimal = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const routeAnimalId = req.params.id;
    const animalId = Array.isArray(routeAnimalId) ? routeAnimalId[0] : routeAnimalId;
    if (!animalId) {
      return res.status(400).json({ success: false, error: 'Animal id is required' });
    }

    const existingAnimal = await prisma.animal.findFirst({
      where: {
        id: animalId,
        farm: {
          userId,
        },
      },
      select: {
        id: true,
        farmId: true,
      },
    });

    if (!existingAnimal) {
      return res.status(404).json({ success: false, error: 'Animal not found' });
    }

    const data: Record<string, unknown> = {};

    if (req.body?.name !== undefined) {
      const name = req.body.name?.toString().trim();
      if (!name) {
        return res.status(400).json({ success: false, error: 'Animal name is required' });
      }
      data.name = name;
    }

    if (req.body?.type !== undefined) {
      const type = req.body.type?.toString().trim().toUpperCase();
      const allowedTypes = new Set([
        'DOG',
        'CAT',
        'CATTLE',
        'CHICKEN',
        'GOAT',
        'SHEEP',
        'PIG',
        'RABBIT',
        'FISH',
        'HORSE',
      ]);
      if (!type || !allowedTypes.has(type)) {
        return res.status(400).json({ success: false, error: 'Invalid animal type' });
      }
      data.type = type;
    }

    if (req.body?.gender !== undefined) {
      const gender = req.body.gender?.toString().trim().toUpperCase();
      const allowedGenders = new Set(['MALE', 'FEMALE']);
      if (!gender || !allowedGenders.has(gender)) {
        return res.status(400).json({ success: false, error: 'Invalid animal gender' });
      }
      data.gender = gender;
    }

    if (req.body?.age !== undefined) {
      const age = Number(req.body.age);
      if (!Number.isFinite(age) || age < 0) {
        return res.status(400).json({ success: false, error: 'Invalid animal age' });
      }
      data.age = age;
    }

    if (req.body?.weight !== undefined) {
      const weight = Number(req.body.weight);
      if (!Number.isFinite(weight) || weight < 0) {
        return res.status(400).json({ success: false, error: 'Invalid animal weight' });
      }
      data.weight = weight;
    }

    if (req.body?.photoUrl !== undefined) {
      const photoUrl = req.body.photoUrl?.toString().trim();
      data.photoUrl = photoUrl && photoUrl.length > 0 ? photoUrl : null;
    }

    if (req.body?.videoUrl !== undefined) {
      const videoUrl = req.body.videoUrl?.toString().trim();
      data.videoUrl = videoUrl && videoUrl.length > 0 ? videoUrl : null;
    }

    if (req.body?.notes !== undefined) {
      const notes = req.body.notes?.toString().trim();
      data.notes = notes && notes.length > 0 ? notes : null;
    }

    if (Object.keys(data).length === 0) {
      return res.status(400).json({ success: false, error: 'No fields provided to update' });
    }

    const animal = await prisma.animal.update({
      where: { id: existingAnimal.id },
      data: data as any,
    });

    return res.status(200).json({ success: true, data: animal });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to update animal', details: error });
  }
};

export const uploadAnimalPhoto = async (req: Request, res: Response) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ success: false, error: 'Photo file is required' });
    }

    const extension = file.originalname.includes('.')
      ? file.originalname.substring(file.originalname.lastIndexOf('.'))
      : '.jpg';
    const objectKey = `animals/photos/${Date.now()}_${randomUUID()}${extension}`;

    // Prefer S3 in configured environments; fallback to local uploads for local development.
    let photoUrl: string;

    if (config.AWS_S3_BUCKET) {
      try {
        await s3Client.send(
          new PutObjectCommand({
            Bucket: config.AWS_S3_BUCKET,
            Key: objectKey,
            Body: file.buffer,
            ContentType: file.mimetype,
          }),
        );

        const cloudfrontBase = config.AWS_CLOUDFRONT_URL?.replace(/\/$/, '');
        photoUrl = cloudfrontBase
          ? `${cloudfrontBase}/${objectKey}`
          : `https://${config.AWS_S3_BUCKET}.s3.${config.AWS_REGION}.amazonaws.com/${objectKey}`;
      } catch (s3Error) {
        console.warn('S3 upload failed, falling back to local storage:', s3Error);
        const uploadRoot = path.resolve(process.cwd(), config.UPLOAD_DIR);
        const relativeFilePath = path.join('animals', 'photos', `${Date.now()}_${randomUUID()}${extension}`);
        const absoluteFilePath = path.join(uploadRoot, relativeFilePath);

        await fs.mkdir(path.dirname(absoluteFilePath), { recursive: true });
        await fs.writeFile(absoluteFilePath, file.buffer);

        photoUrl = `http://localhost:${config.PORT}/uploads/${relativeFilePath.replace(/\\/g, '/')}`;
      }
    } else {
      const uploadRoot = path.resolve(process.cwd(), config.UPLOAD_DIR);
      const relativeFilePath = path.join('animals', 'photos', `${Date.now()}_${randomUUID()}${extension}`);
      const absoluteFilePath = path.join(uploadRoot, relativeFilePath);

      await fs.mkdir(path.dirname(absoluteFilePath), { recursive: true });
      await fs.writeFile(absoluteFilePath, file.buffer);

      photoUrl = `http://localhost:${config.PORT}/uploads/${relativeFilePath.replace(/\\/g, '/')}`;
    }

    return res.status(201).json({
      success: true,
      data: {
        key: objectKey,
        photoUrl,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Failed to upload animal photo', details: error });
  }
};
