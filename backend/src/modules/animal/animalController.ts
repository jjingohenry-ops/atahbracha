import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import path from 'path';
import { config } from '../../config/env';
import { addDays, getGestationReference } from './gestationLibrary';
import { limitedText, optionalLimitedText, parseHttpUrl, productionError } from '../../utils/input';

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

type StructuredField = {
  key: string;
  maxLength: number;
};

const PEDIGREE_FIELDS: StructuredField[] = [
  { key: 'relation', maxLength: 40 },
  { key: 'name', maxLength: 120 },
  { key: 'tagNumber', maxLength: 64 },
  { key: 'breed', maxLength: 120 },
  { key: 'notes', maxLength: 300 },
];

const MEDICAL_HISTORY_FIELDS: StructuredField[] = [
  { key: 'date', maxLength: 32 },
  { key: 'condition', maxLength: 120 },
  { key: 'treatment', maxLength: 160 },
  { key: 'veterinarian', maxLength: 120 },
  { key: 'notes', maxLength: 300 },
];

const MAX_STRUCTURED_ROWS = 100;

const truthy = (value: unknown): boolean => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') {
    return ['true', '1', 'yes', 'y'].includes(value.trim().toLowerCase());
  }
  if (typeof value === 'number') return value === 1;
  return false;
};

const normalizeStructuredRecords = (
  value: unknown,
  fields: StructuredField[],
  label: string,
): Array<Record<string, string>> | null => {
  if (value === undefined || value === null) {
    return null;
  }

  if (!Array.isArray(value)) {
    throw new Error(`${label} must be an array`);
  }

  if (value.length > MAX_STRUCTURED_ROWS) {
    throw new Error(`${label} supports up to ${MAX_STRUCTURED_ROWS} rows`);
  }

  const allowedKeys = new Set(fields.map((field) => field.key));

  return value
    .map((row, index) => {
      if (row === null || typeof row !== 'object' || Array.isArray(row)) {
        throw new Error(`${label} row ${index + 1} must be an object`);
      }

      const rawRow = row as Record<string, unknown>;
      const normalizedRow: Record<string, string> = {};

      for (const key of Object.keys(rawRow)) {
        if (!allowedKeys.has(key)) {
          throw new Error(`${label} row ${index + 1} contains unsupported field "${key}"`);
        }
      }

      for (const field of fields) {
        const rawValue = rawRow[field.key];
        if (rawValue === undefined || rawValue === null) {
          continue;
        }

        const textValue = rawValue.toString().trim();
        if (!textValue) {
          continue;
        }

        if (textValue.length > field.maxLength) {
          throw new Error(
            `${label} row ${index + 1} field "${field.key}" exceeds ${field.maxLength} characters`,
          );
        }

        normalizedRow[field.key] = textValue;
      }

      return normalizedRow;
    })
    .filter((row) => Object.keys(row).length > 0);
};

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
      include: {
        gestations: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
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

    const name = limitedText(req.body?.name, 120);
    const type = req.body?.type?.toString().trim().toUpperCase();
    const gender = req.body?.gender?.toString().trim().toUpperCase();
    const age = Number(req.body?.age);
    const weight = Number(req.body?.weight);
    const tagNumber = limitedText(req.body?.tagNumber, 64);
    const breed = limitedText(req.body?.breed, 120);
    const photoUrl = parseHttpUrl(req.body?.photoUrl);
    const videoUrl = parseHttpUrl(req.body?.videoUrl);
    const notes = optionalLimitedText(req.body?.notes, 3000);
    const isPregnant = truthy(req.body?.isPregnant);
    let pedigreeRecords: Array<Record<string, string>> | null;
    let medicalHistoryRecords: Array<Record<string, string>> | null;

    try {
      pedigreeRecords = normalizeStructuredRecords(
        req.body?.pedigreeRecords,
        PEDIGREE_FIELDS,
        'Pedigree records',
      );
      medicalHistoryRecords = normalizeStructuredRecords(
        req.body?.medicalHistoryRecords,
        MEDICAL_HISTORY_FIELDS,
        'Medical history records',
      );
    } catch (validationError) {
      const message = validationError instanceof Error ? validationError.message : 'Invalid structured records';
      return res.status(400).json({ success: false, error: message });
    }

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

    if (tagNumber.length > 64) {
      return res.status(400).json({ success: false, error: 'Tag number must be 64 characters or less' });
    }

    if (breed.length > 120) {
      return res.status(400).json({ success: false, error: 'Breed must be 120 characters or less' });
    }

    const animal = await prisma.$transaction(async (tx) => {
      const createdAnimal = await tx.animal.create({
        data: {
          farmId: farm.id,
          name,
          type: type as any,
          gender: gender as any,
          age,
          weight,
          tagNumber: tagNumber.length > 0 ? tagNumber : null,
          breed: breed.length > 0 ? breed : null,
          ...(pedigreeRecords !== null && pedigreeRecords.length > 0
            ? { pedigreeRecords }
            : {}),
          ...(medicalHistoryRecords !== null && medicalHistoryRecords.length > 0
            ? { medicalHistoryRecords }
            : {}),
          photoUrl,
          videoUrl,
          notes,
        },
      });

      if (isPregnant && gender === 'FEMALE') {
        const reference = getGestationReference(type, breed);
        const startDate = new Date();
        const expectedDate = addDays(startDate, reference.gestationDays);

        await tx.gestation.create({
          data: {
            animalId: createdAnimal.id,
            startDate,
            expectedDate,
            status: 'IN_PROGRESS' as any,
            notes: `Auto-created from animal registration using ${reference.gestationDays}-day ${type.toLowerCase()} pregnancy reference.`,
          },
        });

        const reminderDates = new Set<string>();
        for (const offset of reference.checkupOffsetsBeforeDue) {
          const reminderDate = addDays(expectedDate, -offset);
          if (reminderDate > startDate) {
            reminderDates.add(reminderDate.toISOString());
          }
        }
        reminderDates.add(expectedDate.toISOString());

        for (const isoDate of reminderDates) {
          const reminderDate = new Date(isoDate);
          const isDueDate = reminderDate.toDateString() === expectedDate.toDateString();
          await tx.reminder.create({
            data: {
              userId,
              farmId: farm.id,
              title: isDueDate
                ? `${createdAnimal.name} expected delivery`
                : `${createdAnimal.name} pregnancy check`,
              date: reminderDate,
              time: '09:00',
              notes: isDueDate
                ? `Expected delivery based on ${reference.gestationDays}-day ${type.toLowerCase()} pregnancy reference.`
                : `Auto reminder before expected delivery on ${expectedDate.toISOString().split('T')[0]}.`,
            },
          });
        }
      }

      return createdAnimal;
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
      const name = limitedText(req.body.name, 120);
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
      data.photoUrl = parseHttpUrl(req.body.photoUrl);
    }

    if (req.body?.videoUrl !== undefined) {
      data.videoUrl = parseHttpUrl(req.body.videoUrl);
    }

    if (req.body?.notes !== undefined) {
      data.notes = optionalLimitedText(req.body.notes, 3000);
    }

    if (req.body?.tagNumber !== undefined) {
      if (req.body.tagNumber === null) {
        data.tagNumber = null;
      } else {
        const tagNumber = limitedText(req.body.tagNumber, 64);
        if (tagNumber.length > 64) {
          return res.status(400).json({ success: false, error: 'Tag number must be 64 characters or less' });
        }
        data.tagNumber = tagNumber && tagNumber.length > 0 ? tagNumber : null;
      }
    }

    if (req.body?.breed !== undefined) {
      if (req.body.breed === null) {
        data.breed = null;
      } else {
        const breed = limitedText(req.body.breed, 120);
        if (breed.length > 120) {
          return res.status(400).json({ success: false, error: 'Breed must be 120 characters or less' });
        }
        data.breed = breed && breed.length > 0 ? breed : null;
      }
    }

    if (req.body?.pedigreeRecords !== undefined) {
      try {
        const normalizedPedigree = normalizeStructuredRecords(
          req.body.pedigreeRecords,
          PEDIGREE_FIELDS,
          'Pedigree records',
        );
        data.pedigreeRecords =
          normalizedPedigree !== null && normalizedPedigree.length > 0 ? normalizedPedigree : null;
      } catch (validationError) {
        const message = validationError instanceof Error ? validationError.message : 'Invalid pedigree records';
        return res.status(400).json({ success: false, error: message });
      }
    }

    if (req.body?.medicalHistoryRecords !== undefined) {
      try {
        const normalizedMedicalHistory = normalizeStructuredRecords(
          req.body.medicalHistoryRecords,
          MEDICAL_HISTORY_FIELDS,
          'Medical history records',
        );
        data.medicalHistoryRecords =
          normalizedMedicalHistory !== null && normalizedMedicalHistory.length > 0
            ? normalizedMedicalHistory
            : null;
      } catch (validationError) {
        const message = validationError instanceof Error ? validationError.message : 'Invalid medical history records';
        return res.status(400).json({ success: false, error: message });
      }
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

    const extensionByMime: Record<string, string> = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/webp': '.webp',
    };
    const extension = extensionByMime[file.mimetype];
    if (!extension) {
      return res.status(400).json({ success: false, error: 'Unsupported photo type' });
    }

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
    return res.status(500).json(productionError(error, 'Failed to upload animal photo'));
  }
};
