import { Router } from 'express';
import { authenticateFirebaseToken } from '../../config/firebaseAdmin';
import {
  createPrescription,
  getAnimalPrescriptions,
  getPrescriptionDrugs,
  markDoseGiven,
  syncPrescriptionOperations,
  updatePrescription,
} from './prescriptionController';

const router = Router();

router.use(authenticateFirebaseToken);

router.get('/drugs', getPrescriptionDrugs);
router.get('/animal/:animalId', getAnimalPrescriptions);
router.post('/', createPrescription);
router.patch('/:prescriptionId', updatePrescription);
router.post('/:prescriptionId/items/:itemId/mark-given', markDoseGiven);
router.post('/sync', syncPrescriptionOperations);

export { router as prescriptionRoutes };
