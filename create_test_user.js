const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const email = 'test@kopytrading.com';
  const hashed = await bcrypt.hash('123456', 10);
  
  console.log("CREATING TEST USER:", email);
  try {
    const user = await prisma.user.upsert({
      where: { email },
      update: { password: hashed },
      create: { 
        email, 
        password: hashed, 
        name: 'Test User',
        role: 'USER'
      }
    });
    console.log("TEST USER CREATED:", user.email);
  } catch (e) {
    console.error("ERROR CREATING TEST USER:", e);
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
