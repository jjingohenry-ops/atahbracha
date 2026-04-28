import { Router } from 'express';
import multer from 'multer';
import { getAnimals, addAnimal, updateAnimal, uploadAnimalPhoto } from './animalController';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';
import { config } from '../../config/env';
import { createRateLimiter } from '../../middlewares/rateLimit';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: config.MAX_FILE_SIZE, files: 1 },
  fileFilter: (_req, file, callback) => {
    const allowed = new Set(['image/jpeg', 'image/png', 'image/webp']);
    callback(null, allowed.has(file.mimetype));
  },
});

router.use(authenticateFirebaseToken);

router.get('/', getAnimals);
router.post('/', addAnimal);
router.put('/:id', updateAnimal);
router.post('/upload-photo', createRateLimiter({
  windowMs: config.API_RATE_LIMIT_WINDOW_MS,
  max: config.UPLOAD_RATE_LIMIT_MAX,
  keyPrefix: 'upload',
}), upload.single('photo'), uploadAnimalPhoto);

export { router as animalRoutes };
