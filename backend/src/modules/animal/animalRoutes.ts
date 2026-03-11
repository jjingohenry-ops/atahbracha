import { Router } from 'express';
import { getAnimals, addAnimal } from './animalController';

const router = Router();

router.get('/', getAnimals);
router.post('/', addAnimal);

export { router as animalRoutes };