-- Structured prescriptions module
CREATE TABLE "prescriptions" (
  "id" TEXT NOT NULL,
  "animalId" TEXT NOT NULL,
  "diagnosis" TEXT NOT NULL,
  "vetName" TEXT,
  "notes" TEXT,
  "status" TEXT NOT NULL DEFAULT 'ACTIVE',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "lastSyncAt" TIMESTAMP(3),
  CONSTRAINT "prescriptions_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "prescription_items" (
  "id" TEXT NOT NULL,
  "prescriptionId" TEXT NOT NULL,
  "drugName" TEXT NOT NULL,
  "dosage" TEXT NOT NULL,
  "frequencyPerDay" INTEGER NOT NULL,
  "durationDays" INTEGER NOT NULL,
  "withdrawalPeriodDays" INTEGER,
  "startDate" TIMESTAMP(3) NOT NULL,
  "totalDoses" INTEGER NOT NULL,
  "completedDoses" INTEGER NOT NULL DEFAULT 0,
  "nextDoseAt" TIMESTAMP(3),
  "status" TEXT NOT NULL DEFAULT 'ACTIVE',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "prescription_items_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "treatment_logs" (
  "id" TEXT NOT NULL,
  "prescriptionId" TEXT NOT NULL,
  "itemId" TEXT NOT NULL,
  "givenAt" TIMESTAMP(3) NOT NULL,
  "scheduledFor" TIMESTAMP(3),
  "givenBy" TEXT,
  "notes" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "syncedFromOffline" BOOLEAN NOT NULL DEFAULT false,
  CONSTRAINT "treatment_logs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "prescriptions_animalId_createdAt_idx" ON "prescriptions"("animalId", "createdAt");
CREATE INDEX "prescription_items_prescriptionId_idx" ON "prescription_items"("prescriptionId");
CREATE INDEX "prescription_items_status_nextDoseAt_idx" ON "prescription_items"("status", "nextDoseAt");
CREATE INDEX "treatment_logs_itemId_givenAt_idx" ON "treatment_logs"("itemId", "givenAt");
CREATE INDEX "treatment_logs_prescriptionId_givenAt_idx" ON "treatment_logs"("prescriptionId", "givenAt");

ALTER TABLE "prescriptions"
  ADD CONSTRAINT "prescriptions_animalId_fkey"
  FOREIGN KEY ("animalId") REFERENCES "animals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "prescription_items"
  ADD CONSTRAINT "prescription_items_prescriptionId_fkey"
  FOREIGN KEY ("prescriptionId") REFERENCES "prescriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "treatment_logs"
  ADD CONSTRAINT "treatment_logs_prescriptionId_fkey"
  FOREIGN KEY ("prescriptionId") REFERENCES "prescriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "treatment_logs"
  ADD CONSTRAINT "treatment_logs_itemId_fkey"
  FOREIGN KEY ("itemId") REFERENCES "prescription_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;
