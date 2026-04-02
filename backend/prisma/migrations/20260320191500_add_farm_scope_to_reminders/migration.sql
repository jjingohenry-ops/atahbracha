-- Add nullable farmId ownership column for reminders
ALTER TABLE IF EXISTS "reminders"
ADD COLUMN IF NOT EXISTS "farmId" TEXT;

-- Add index for farm-scoped reminder queries
CREATE INDEX IF NOT EXISTS "reminders_farmId_idx" ON "reminders"("farmId");

-- Add FK to farms table for ownership integrity
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reminders_farmId_fkey'
  ) THEN
    ALTER TABLE "reminders"
    ADD CONSTRAINT "reminders_farmId_fkey"
    FOREIGN KEY ("farmId") REFERENCES "farms"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
