-- Add structured pedigree and medical history storage for animals.
ALTER TABLE "animals"
ADD COLUMN "pedigreeRecords" JSONB,
ADD COLUMN "medicalHistoryRecords" JSONB;
