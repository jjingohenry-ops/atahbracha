-- Add nullable userId ownership column for reminders
ALTER TABLE IF EXISTS "reminders"
ADD COLUMN IF NOT EXISTS "userId" TEXT;

-- Add index for account-scoped reminder queries
CREATE INDEX IF NOT EXISTS "reminders_userId_idx" ON "reminders"("userId");

-- Add FK to users table for ownership integrity
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reminders_userId_fkey'
  ) THEN
    ALTER TABLE "reminders"
    ADD CONSTRAINT "reminders_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
