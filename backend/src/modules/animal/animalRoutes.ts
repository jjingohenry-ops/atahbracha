import { Router } from 'express';
import multer from 'multer';
import { getAnimals, addAnimal, updateAnimal, uploadAnimalPhoto } from './animalController';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.use(authenticateFirebaseToken);

router.get('/', getAnimals);
router.post('/', addAnimal);
router.put('/:id', updateAnimal);
router.post('/upload-photo', upload.single('photo'), uploadAnimalPhoto);

export { router as animalRoutes };