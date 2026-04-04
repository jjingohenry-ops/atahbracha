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

CREATE TABLE IF NOT EXISTS insurance_provider_animal_types (
  id TEXT PRIMARY KEY,
  provider_id TEXT NOT NULL,
  animal_type TEXT NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT insurance_provider_animal_types_provider_id_fkey
    FOREIGN KEY (provider_id) REFERENCES insurance_providers(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS insurance_provider_animal_types_provider_id_animal_type_key
  ON insurance_provider_animal_types(provider_id, animal_type);

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

CREATE UNIQUE INDEX IF NOT EXISTS insurance_coverage_info_provider_id_animal_type_key
  ON insurance_coverage_info(provider_id, animal_type);
