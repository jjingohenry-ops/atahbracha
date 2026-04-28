CREATE TABLE IF NOT EXISTS "prescription_drugs" (
  "id" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "category" TEXT NOT NULL,
  "defaultDosage" TEXT NOT NULL,
  "defaultFrequencyPerDay" INTEGER NOT NULL DEFAULT 1,
  "defaultDurationDays" INTEGER NOT NULL DEFAULT 1,
  "defaultWithdrawalPeriodDays" INTEGER,
  "supportedSpecies" JSONB,
  "notes" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "prescription_drugs_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "prescription_drugs_name_key" ON "prescription_drugs"("name");

INSERT INTO "prescription_drugs" (
  "id",
  "name",
  "category",
  "defaultDosage",
  "defaultFrequencyPerDay",
  "defaultDurationDays",
  "defaultWithdrawalPeriodDays",
  "supportedSpecies",
  "notes"
) VALUES
  ('drug_oxytetracycline', 'Oxytetracycline', 'Antibiotic', '10 mg/kg or label dose', 1, 3, 28, '["CATTLE","GOAT","SHEEP","PIG"]', 'Medically important antimicrobial; use under veterinary direction.'),
  ('drug_penicillin_g', 'Penicillin G', 'Antibiotic', 'label dose by weight', 1, 5, 14, '["CATTLE","SHEEP","PIG","GOAT"]', 'Prescription antibiotic; confirm species label and withdrawal period.'),
  ('drug_ceftiofur', 'Ceftiofur', 'Antibiotic', 'label dose by species', 1, 3, 4, '["CATTLE","PIG","HORSE"]', 'Prescription cephalosporin; follow label restrictions.'),
  ('drug_florfenicol', 'Florfenicol', 'Antibiotic', 'label dose by species', 1, 2, 28, '["CATTLE","PIG","FISH"]', 'Prescription antibiotic; withdrawal differs by product and route.'),
  ('drug_tylosin', 'Tylosin', 'Antibiotic', 'label dose by species', 1, 3, 21, '["CATTLE","PIG","CHICKEN"]', 'Use veterinary label guidance.'),
  ('drug_sulfadimethoxine', 'Sulfadimethoxine', 'Antibiotic', 'label dose by weight', 1, 5, 10, '["CATTLE","CHICKEN"]', 'Confirm approved species and product label.'),
  ('drug_albendazole', 'Albendazole', 'Dewormer', '7.5-10 mg/kg oral', 1, 1, 14, '["CATTLE","GOAT","SHEEP"]', 'Avoid use in early pregnancy unless advised by a veterinarian.'),
  ('drug_fenbendazole', 'Fenbendazole', 'Dewormer', '5-10 mg/kg oral', 1, 1, 6, '["CATTLE","GOAT","SHEEP","PIG","HORSE","DOG","CAT"]', 'Withdrawal varies by species, product, and dose.'),
  ('drug_ivermectin', 'Ivermectin', 'Dewormer', '0.2 mg/kg oral or injectable', 1, 1, 21, '["CATTLE","SHEEP","PIG","HORSE"]', 'Avoid extralabel use in lactating dairy animals unless directed by a veterinarian.'),
  ('drug_doramectin', 'Doramectin', 'Dewormer', '0.2 mg/kg injectable', 1, 1, 35, '["CATTLE","PIG"]', 'Follow product route and withdrawal label.'),
  ('drug_moxidectin', 'Moxidectin', 'Dewormer', '0.2 mg/kg', 1, 1, 21, '["CATTLE","SHEEP","GOAT","HORSE"]', 'Use label-specific withdrawal periods.'),
  ('drug_eprinomectin', 'Eprinomectin', 'Dewormer', '0.5 mg/kg pour-on or label dose', 1, 1, 0, '["CATTLE"]', 'Withdrawal depends on product and route.'),
  ('drug_levamisole', 'Levamisole', 'Dewormer', 'label dose by weight', 1, 1, 7, '["CATTLE","SHEEP","GOAT","PIG"]', 'Narrow safety margin; dose carefully by accurate weight.'),
  ('drug_oxfendazole', 'Oxfendazole', 'Dewormer', '4.5-5 mg/kg oral', 1, 1, 14, '["CATTLE","SHEEP","GOAT","HORSE"]', 'Withdrawal varies by species and product.'),
  ('drug_flunixin', 'Flunixin meglumine', 'Anti-inflammatory', 'label dose by species', 1, 3, 4, '["CATTLE","HORSE","PIG"]', 'Prescription NSAID; follow route restrictions.'),
  ('drug_meloxicam', 'Meloxicam', 'Anti-inflammatory', 'label/vet-directed dose', 1, 3, 0, '["CATTLE","PIG","DOG","CAT"]', 'Withdrawal must be set by label or veterinarian.'),
  ('drug_calcium', 'Calcium borogluconate', 'Supportive care', 'label dose slow IV/SQ', 1, 1, 0, '["CATTLE","GOAT","SHEEP"]', 'For milk fever/hypocalcemia; IV use requires care.'),
  ('drug_vitamin_b', 'Vitamin B Complex', 'Vitamin', '5 ml or label dose', 1, 3, 0, '["CATTLE","GOAT","SHEEP","PIG","HORSE","DOG","CAT"]', 'Supportive vitamin therapy.'),
  ('drug_iron_dextran', 'Iron dextran', 'Supplement', 'label dose', 1, 1, 0, '["PIG"]', 'Commonly used for piglets; follow label.'),
  ('drug_cloprostenol', 'Cloprostenol', 'Reproductive', 'label dose', 1, 1, 0, '["CATTLE","HORSE","PIG"]', 'Reproductive hormone; use only under veterinary direction.')
ON CONFLICT ("name") DO UPDATE SET
  "category" = EXCLUDED."category",
  "defaultDosage" = EXCLUDED."defaultDosage",
  "defaultFrequencyPerDay" = EXCLUDED."defaultFrequencyPerDay",
  "defaultDurationDays" = EXCLUDED."defaultDurationDays",
  "defaultWithdrawalPeriodDays" = EXCLUDED."defaultWithdrawalPeriodDays",
  "supportedSpecies" = EXCLUDED."supportedSpecies",
  "notes" = EXCLUDED."notes",
  "updatedAt" = CURRENT_TIMESTAMP;
