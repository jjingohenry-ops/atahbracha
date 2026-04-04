import { Request, Response } from 'express';
import { insuranceService } from './insuranceService';

export const insuranceController = {
  async getProviders(req: Request, res: Response): Promise<void> {
    try {
      const country = req.query.country?.toString();
      const animalType = req.query.animal_type?.toString();

      const providers = await insuranceService.getProviders({
        country,
        animalType,
      });

      res.status(200).json({
        success: true,
        data: providers,
      });
    } catch (error) {
      console.error('Error fetching insurance providers:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch insurance providers',
      });
    }
  },
};
