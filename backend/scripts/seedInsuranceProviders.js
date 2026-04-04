const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const providers = [
  {
    id: 'prov_ug_livestock_cover',
    name: 'Livestock Cover Uganda',
    country: 'UG',
    phone: '+256700100111',
    whatsapp: '+256700100111',
    website: null,
    email: 'help@livestockcover.ug',
    animalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'PIG', 'CHICKEN'],
    coverageSummary: 'Mortality, accident, and disease coverage for farm animals.',
  },
  {
    id: 'prov_ug_farmsecure',
    name: 'FarmSecure Assurance',
    country: 'UG',
    phone: '+256700200222',
    whatsapp: '+256700200222',
    website: 'https://farmsecure.ug',
    email: 'support@farmsecure.ug',
    animalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'PIG', 'DOG'],
    coverageSummary: 'Comprehensive cover including treatment support and theft rider.',
  },
  {
    id: 'prov_ke_agriplan',
    name: 'AgriPlan Kenya',
    country: 'KE',
    phone: '+254700300333',
    whatsapp: '+254700300333',
    website: 'https://agriplan.co.ke',
    email: 'care@agriplan.co.ke',
    animalTypes: ['CATTLE', 'GOAT', 'SHEEP', 'CHICKEN', 'RABBIT'],
    coverageSummary: 'Livestock and poultry micro-insurance with flexible premium plans.',
  },
];

async function ensureTables() {
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS insurance_providers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      country TEXT NOT NULL,
      phone TEXT,
      whatsapp TEXT,
      website TEXT,
      email TEXT,
      created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS insurance_provider_animal_types (
      id TEXT PRIMARY KEY,
      provider_id TEXT NOT NULL,
      animal_type TEXT NOT NULL,
      created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT insurance_provider_animal_types_provider_id_fkey
        FOREIGN KEY (provider_id) REFERENCES insurance_providers(id) ON DELETE CASCADE
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE UNIQUE INDEX IF NOT EXISTS insurance_provider_animal_types_provider_id_animal_type_key
    ON insurance_provider_animal_types(provider_id, animal_type);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS insurance_coverage_info (
      id TEXT PRIMARY KEY,
      provider_id TEXT NOT NULL,
      animal_type TEXT NOT NULL,
      coverage_summary TEXT NOT NULL,
      created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT insurance_coverage_info_provider_id_fkey
        FOREIGN KEY (provider_id) REFERENCES insurance_providers(id) ON DELETE CASCADE
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE UNIQUE INDEX IF NOT EXISTS insurance_coverage_info_provider_id_animal_type_key
    ON insurance_coverage_info(provider_id, animal_type);
  `);
}

async function seed() {
  await ensureTables();

  for (const provider of providers) {
    await prisma.$executeRawUnsafe(
      `
      INSERT INTO insurance_providers (id, name, country, phone, whatsapp, website, email)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        country = EXCLUDED.country,
        phone = EXCLUDED.phone,
        whatsapp = EXCLUDED.whatsapp,
        website = EXCLUDED.website,
        email = EXCLUDED.email,
        updated_at = CURRENT_TIMESTAMP
      `,
      provider.id,
      provider.name,
      provider.country,
      provider.phone,
      provider.whatsapp,
      provider.website,
      provider.email
    );

    for (const animalType of provider.animalTypes) {
      const relationId = `${provider.id}_${animalType}`;
      const coverageId = `${provider.id}_${animalType}_coverage`;

      await prisma.$executeRawUnsafe(
        `
        INSERT INTO insurance_provider_animal_types (id, provider_id, animal_type)
        VALUES ($1, $2, $3)
        ON CONFLICT (provider_id, animal_type) DO NOTHING
        `,
        relationId,
        provider.id,
        animalType
      );

      await prisma.$executeRawUnsafe(
        `
        INSERT INTO insurance_coverage_info (id, provider_id, animal_type, coverage_summary)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (provider_id, animal_type) DO UPDATE SET
          coverage_summary = EXCLUDED.coverage_summary,
          updated_at = CURRENT_TIMESTAMP
        `,
        coverageId,
        provider.id,
        animalType,
        provider.coverageSummary
      );
    }
  }

  console.log('Insurance providers seeded successfully.');
}

seed()
  .catch((error) => {
    console.error('Insurance seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
