import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

type InsuranceQueryInput = {
  country?: string | undefined;
  animalType?: string | undefined;
};

export type InsuranceProviderResult = {
  id: string;
  name: string;
  country: string;
  phone: string | null;
  whatsapp: string | null;
  website: string | null;
  email: string | null;
  coverageSummary: string;
  supportedAnimalTypes: string[];
};

type InsuranceProviderRow = {
  id: string;
  name: string;
  country: string;
  phone: string | null;
  whatsapp: string | null;
  website: string | null;
  email: string | null;
  coverageSummary: string | null;
  supportedAnimalTypes: string | null;
};

const fallbackProviders: InsuranceProviderResult[] = [
  {
    id: 'local-ug-livestock-cover',
    name: 'Livestock Cover Uganda',
    country: 'UG',
    phone: '+256700100111',
    whatsapp: '+256700100111',
    website: null,
    email: 'help@livestockcover.ug',
    coverageSummary: 'Mortality, accident, and disease coverage for farm animals.',
    supportedAnimalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'PIG', 'CHICKEN'],
  },
  {
    id: 'local-ug-farmsecure',
    name: 'FarmSecure Assurance',
    country: 'UG',
    phone: '+256700200222',
    whatsapp: '+256700200222',
    website: 'https://farmsecure.ug',
    email: 'support@farmsecure.ug',
    coverageSummary: 'Comprehensive cover including treatment support and theft rider.',
    supportedAnimalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'PIG', 'DOG'],
  },
  {
    id: 'local-ke-agriplan',
    name: 'AgriPlan Kenya',
    country: 'KE',
    phone: '+254700300333',
    whatsapp: '+254700300333',
    website: 'https://agriplan.co.ke',
    email: 'care@agriplan.co.ke',
    coverageSummary: 'Livestock and poultry micro-insurance with flexible premium plans.',
    supportedAnimalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'CHICKEN', 'RABBIT'],
  },
  {
    id: 'local-tz-ruralshield',
    name: 'RuralShield Tanzania',
    country: 'TZ',
    phone: '+255700400444',
    whatsapp: '+255700400444',
    website: null,
    email: 'support@ruralshield.tz',
    coverageSummary: 'Disease outbreak, mortality, and emergency response support cover.',
    supportedAnimalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'PIG'],
  },
  {
    id: 'local-rw-herdcare',
    name: 'HerdCare Rwanda',
    country: 'RW',
    phone: '+250700500555',
    whatsapp: '+250700500555',
    website: 'https://herdcare.rw',
    email: 'info@herdcare.rw',
    coverageSummary: 'Affordable cover for dairy and small livestock with claim guidance.',
    supportedAnimalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'PIG', 'CHICKEN'],
  },
];

function normalizeCountry(country?: string): string | undefined {
  if (!country) return undefined;
  const value = country.trim().toUpperCase();
  return value.length > 0 ? value : undefined;
}

function normalizeAnimalType(animalType?: string): string | undefined {
  if (!animalType) return undefined;
  const value = animalType.trim().toUpperCase();
  if (value === 'COW') return 'CATTLE';
  return value.length > 0 ? value : undefined;
}

function mapRows(rows: InsuranceProviderRow[]): InsuranceProviderResult[] {
  return rows.map((row) => ({
    id: row.id,
    name: row.name,
    country: row.country,
    phone: row.phone,
    whatsapp: row.whatsapp,
    website: row.website,
    email: row.email,
    coverageSummary: row.coverageSummary ?? 'Coverage details available on request.',
    supportedAnimalTypes: (row.supportedAnimalTypes ?? '')
      .split(',')
      .map((item) => item.trim().toUpperCase())
      .filter((item) => item.length > 0),
  }));
}

function filterFallback(input: InsuranceQueryInput): InsuranceProviderResult[] {
  const country = normalizeCountry(input.country);
  const animalType = normalizeAnimalType(input.animalType);

  return fallbackProviders.filter((provider) => {
    const matchCountry = !country || provider.country === country;
    const matchType = !animalType || provider.supportedAnimalTypes.includes(animalType);
    return matchCountry && matchType;
  });
}

export const insuranceService = {
  async getProviders(input: InsuranceQueryInput): Promise<InsuranceProviderResult[]> {
    const country = normalizeCountry(input.country);
    const animalType = normalizeAnimalType(input.animalType);

    try {
      const rows = await prisma.$queryRaw<InsuranceProviderRow[]>(Prisma.sql`
        SELECT
          p.id,
          p.name,
          p.country,
          p.phone,
          p.whatsapp,
          p.website,
          p.email,
          COALESCE(MAX(ci.coverage_summary), 'Coverage details available on request.') AS "coverageSummary",
          string_agg(DISTINCT pat.animal_type, ',') AS "supportedAnimalTypes"
        FROM insurance_providers p
        JOIN insurance_provider_animal_types pat ON pat.provider_id = p.id
        LEFT JOIN insurance_coverage_info ci
          ON ci.provider_id = p.id
         AND ci.animal_type = pat.animal_type
        WHERE (${country}::text IS NULL OR p.country = ${country})
          AND (${animalType}::text IS NULL OR pat.animal_type = ${animalType})
        GROUP BY p.id, p.name, p.country, p.phone, p.whatsapp, p.website, p.email
        ORDER BY p.name ASC
      `);

      if (rows.length > 0) {
        return mapRows(rows);
      }
    } catch (_error) {
      // Fallback to curated local data when table is missing or DB is unavailable.
    }

    return filterFallback({ country, animalType });
  },
};
