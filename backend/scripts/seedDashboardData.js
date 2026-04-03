const { PrismaClient, AnimalType, Gender, GestationStatus } = require('@prisma/client');

const prisma = new PrismaClient();
const SEED_MARKER = '[seed-dashboard]';
const DAY_MS = 24 * 60 * 60 * 1000;

function startOfDay(date) {
  const next = new Date(date);
  next.setHours(0, 0, 0, 0);
  return next;
}

function atTime(date, hour, minute = 0) {
  const next = new Date(date);
  next.setHours(hour, minute, 0, 0);
  return next;
}

async function ensureAnimalsForFarm(farm) {
  const existing = await prisma.animal.findMany({
    where: { farmId: farm.id },
    orderBy: { createdAt: 'asc' },
  });

  const targetCount = 3;
  if (existing.length >= targetCount) {
    return existing;
  }

  const animalTemplates = [
    { name: 'Bella', type: AnimalType.CATTLE, gender: Gender.FEMALE, weight: 430 },
    { name: 'Nala', type: AnimalType.GOAT, gender: Gender.FEMALE, weight: 62 },
    { name: 'Duke', type: AnimalType.SHEEP, gender: Gender.MALE, weight: 85 },
  ];

  const missing = targetCount - existing.length;
  for (let i = 0; i < missing; i += 1) {
    const template = animalTemplates[(existing.length + i) % animalTemplates.length];
    await prisma.animal.create({
      data: {
        farmId: farm.id,
        name: `${template.name}-${(existing.length + i + 1).toString()}`,
        type: template.type,
        age: 2 + i,
        weight: template.weight,
        gender: template.gender,
        notes: `${SEED_MARKER} demo animal`,
      },
    });
  }

  return prisma.animal.findMany({
    where: { farmId: farm.id },
    orderBy: { createdAt: 'asc' },
  });
}

async function clearPreviousSeedData(farmId) {
  await prisma.reminder.deleteMany({
    where: {
      farmId,
      notes: { contains: SEED_MARKER },
    },
  });

  await prisma.dailyActivity.deleteMany({
    where: {
      animal: { farmId },
      notes: { contains: SEED_MARKER },
    },
  });

  await prisma.feedingLog.deleteMany({
    where: {
      animal: { farmId },
      notes: { contains: SEED_MARKER },
    },
  });

  await prisma.treatment.deleteMany({
    where: {
      animal: { farmId },
      notes: { contains: SEED_MARKER },
    },
  });

  await prisma.gestation.deleteMany({
    where: {
      animal: { farmId },
      notes: { contains: SEED_MARKER },
    },
  });
}

async function seedFarmDashboardData(farm) {
  const animals = await ensureAnimalsForFarm(farm);
  if (animals.length === 0) {
    return {
      reminders: 0,
      activities: 0,
      milkEntries: 0,
      feedingLogs: 0,
      treatments: 0,
      gestations: 0,
    };
  }

  await clearPreviousSeedData(farm.id);

  const today = startOfDay(new Date());

  let reminders = 0;
  let activities = 0;
  let milkEntries = 0;
  let feedingLogs = 0;
  let treatments = 0;
  let gestations = 0;

  const reminderPlans = [
    { title: 'Vaccination follow-up', dayOffset: 0, hour: 9, minute: 0 },
    { title: 'Nutrition check', dayOffset: 0, hour: 12, minute: 0 },
    { title: 'Evening barn walkthrough', dayOffset: 0, hour: 17, minute: 30 },
    { title: 'Water system inspection', dayOffset: 1, hour: 8, minute: 30 },
    { title: 'Feed stock reorder', dayOffset: 1, hour: 15, minute: 0 },
    { title: 'Animal weight check', dayOffset: 2, hour: 10, minute: 15 },
    { title: 'Deworming reminder', dayOffset: 3, hour: 9, minute: 45 },
    { title: 'Vet call prep', dayOffset: 4, hour: 14, minute: 0 },
  ];

  for (let i = 0; i < reminderPlans.length; i += 1) {
    const plan = reminderPlans[i];
    const reminderDate = new Date(today.getTime() + plan.dayOffset * DAY_MS);
    await prisma.reminder.create({
      data: {
        userId: farm.userId,
        farmId: farm.id,
        title: plan.title,
        date: atTime(reminderDate, plan.hour, plan.minute),
        notes: `${SEED_MARKER} ${plan.title}`,
      },
    });
    reminders += 1;
  }

  for (let dayOffset = -6; dayOffset <= 0; dayOffset += 1) {
    const dayBase = new Date(today.getTime() + dayOffset * DAY_MS);
    const animal = animals[Math.abs(dayOffset) % animals.length];
    const liters = Number((6.5 + Math.random() * 5.5).toFixed(1));

    await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity: 'Milking Session',
        time: atTime(dayBase, 7, 30),
        notes: `${SEED_MARKER} Collected ${liters} liters during morning milking`,
      },
    });
    activities += 1;
    milkEntries += 1;

    await prisma.dailyActivity.create({
      data: {
        animalId: animal.id,
        activity: 'Field Activity',
        time: atTime(dayBase, 16, 15),
        notes: `${SEED_MARKER} Grazing and movement check completed`,
      },
    });
    activities += 1;
  }

  await prisma.feedingLog.create({
    data: {
      animalId: animals[0].id,
      time: new Date(Date.now() + 2 * 60 * 60 * 1000),
      quantity: 5.0,
      foodType: 'Silage Mix',
      notes: `${SEED_MARKER} upcoming feeding window`,
    },
  });
  feedingLogs += 1;

  await prisma.feedingLog.create({
    data: {
      animalId: animals[Math.min(1, animals.length - 1)].id,
      time: new Date(Date.now() + DAY_MS),
      quantity: 3.2,
      foodType: 'Protein Feed',
      notes: `${SEED_MARKER} next day feeding`,
    },
  });
  feedingLogs += 1;

  await prisma.treatment.create({
    data: {
      animalId: animals[0].id,
      drugName: 'Vaccination Booster',
      dosage: '8 ml',
      date: new Date(Date.now() + DAY_MS),
      notes: `${SEED_MARKER} vaccination follow-up`,
    },
  });
  treatments += 1;

  await prisma.treatment.create({
    data: {
      animalId: animals[Math.min(1, animals.length - 1)].id,
      drugName: 'Dewormer',
      dosage: '12 ml',
      date: new Date(Date.now() + 3 * DAY_MS),
      notes: `${SEED_MARKER} deworming schedule`,
    },
  });
  treatments += 1;

  await prisma.gestation.create({
    data: {
      animalId: animals[0].id,
      startDate: new Date(Date.now() - 140 * DAY_MS),
      expectedDate: atTime(today, 18, 0),
      status: GestationStatus.IN_PROGRESS,
      notes: `${SEED_MARKER} expected today`,
    },
  });
  gestations += 1;

  return { reminders, activities, milkEntries, feedingLogs, treatments, gestations };
}

async function ensureAtLeastOneFarm() {
  const farms = await prisma.farm.findMany({
    select: { id: true, name: true, userId: true },
    orderBy: { createdAt: 'asc' },
  });

  if (farms.length > 0) {
    return farms;
  }

  const user = await prisma.user.create({
    data: {
      email: `seed-${Date.now()}@atahbracah.local`,
      password: 'seed-password',
      firstName: 'Seed',
      lastName: 'User',
    },
  });

  const farm = await prisma.farm.create({
    data: {
      userId: user.id,
      name: 'Seed Demo Farm',
      location: 'Demo Location',
    },
  });

  return [{ id: farm.id, name: farm.name, userId: farm.userId }];
}

async function main() {
  console.log('Seeding dashboard-ready data...');

  const farms = await ensureAtLeastOneFarm();
  console.log(`Found ${farms.length} farm(s) to seed.`);

  for (const farm of farms) {
    const result = await seedFarmDashboardData(farm);
    console.log(`\nFarm: ${farm.name} (${farm.id})`);
    console.log(`- Reminders: ${result.reminders}`);
    console.log(`- Activities: ${result.activities}`);
    console.log(`- Milk entries: ${result.milkEntries}`);
    console.log(`- Feeding logs: ${result.feedingLogs}`);
    console.log(`- Treatments: ${result.treatments}`);
    console.log(`- Gestations: ${result.gestations}`);
  }

  console.log('\nDone. Refresh dashboard to see alerts and graphs.');
}

main()
  .catch((error) => {
    console.error('Seeding failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
