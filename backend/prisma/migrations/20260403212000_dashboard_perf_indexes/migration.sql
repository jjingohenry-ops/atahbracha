-- Dashboard and reminders performance indexes
CREATE INDEX IF NOT EXISTS feeding_logs_animal_id_time_idx ON "feeding_logs" ("animalId", "time");
CREATE INDEX IF NOT EXISTS gestations_animal_id_expected_date_idx ON "gestations" ("animalId", "expectedDate");
CREATE INDEX IF NOT EXISTS treatments_animal_id_date_idx ON "treatments" ("animalId", "date");
CREATE INDEX IF NOT EXISTS reminders_user_id_date_idx ON "reminders" ("userId", "date");
CREATE INDEX IF NOT EXISTS reminders_farm_id_date_idx ON "reminders" ("farmId", "date");
CREATE INDEX IF NOT EXISTS daily_activities_animal_id_time_idx ON "daily_activities" ("animalId", "time");
