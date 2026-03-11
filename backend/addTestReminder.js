const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function addTestReminder() {
  try {
    console.log('Connecting to database...');
    
    // Check if there are any animals
    const animals = await prisma.animal.findMany({ take: 1 });
    
    if (animals.length === 0) {
      console.log('No animals found. Creating test farm, user, and animal...');
      
      // Create test user
      const user = await prisma.user.create({
        data: {
          email: `test-${Date.now()}@test.com`,
          password: 'hashedPassword123',
          firstName: 'Test',
          lastName: 'User',
          phone: '1234567890',
        },
      });
      console.log('✅ Created test user:', user.id);
      
      // Create test farm
      const farm = await prisma.farm.create({
        data: {
          userId: user.id,
          name: 'Test Farm',
          location: 'Test Location',
        },
      });
      console.log('✅ Created test farm:', farm.id);
      
      // Create test animal
      const animal = await prisma.animal.create({
        data: {
          farmId: farm.id,
          name: 'Test Cow',
          type: 'COW',
          age: 3,
          weight: 500,
          gender: 'FEMALE',
        },
      });
      console.log('✅ Created test animal:', animal.id);
      
      // Add test reminder
      const reminder = await prisma.treatment.create({
        data: {
          animalId: animal.id,
          drugName: 'Penicillin',
          dosage: '500mg',
          date: new Date(),
          notes: 'Test reminder for daily injection',
        },
      });
      console.log('✅ Added test reminder:', reminder);
    } else {
      console.log('Found existing animal:', animals[0].id);
      
      // Add reminder to existing animal
      const reminder = await prisma.treatment.create({
        data: {
          animalId: animals[0].id,
          drugName: 'Vaccine Booster',
          dosage: '10ml',
          date: new Date(),
          notes: 'Test reminder added at ' + new Date().toISOString(),
        },
      });
      console.log('✅ Added test reminder to existing animal:', reminder);
    }
    
    // Verify by fetching today's reminders
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const todaysReminders = await prisma.treatment.findMany({
      where: {
        date: {
          gte: today,
          lt: tomorrow,
        },
      },
      include: { animal: true },
    });
    
    console.log('\n📋 Reminders for today:');
    console.log(JSON.stringify(todaysReminders, null, 2));
    console.log('\n✅ Success! Now refresh your app at http://localhost:8080');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

addTestReminder();
