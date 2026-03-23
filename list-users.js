const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
      include: { 
          purchases: {
              include: { botProduct: true }
          }
      }
  });

  console.log('--- USERS AND THEIR BOTS ---');
  users.forEach(u => {
    console.log(`User: ${u.name} (${u.email}) ID: ${u.id}`);
    u.purchases.forEach(p => {
        console.log(`  - ${p.botProduct.name} (ID: ${p.id}, LastSync: ${p.lastSync})`);
    });
    console.log('---------------------------');
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
