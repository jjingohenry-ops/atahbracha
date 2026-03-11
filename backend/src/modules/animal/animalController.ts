import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getAnimals = async (req: Request, res: Response) => {
  try {
    const animals = await prisma.animal.findMany();
    res.json({ success: true, data: animals });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to fetch animals', details: error });
  }
};

export const addAnimal = async (req: Request, res: Response) => {
  try {
    const animal = await prisma.animal.create({ data: req.body });
    res.status(201).json({ success: true, data: animal });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to add animal', details: error });
  }
};
