const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const activePurchases = await prisma.purchase.findMany({
    where: {
      lastSync: { gte: new Date(Date.now() - 60 * 60 * 1000) } // Last 1 hour
    },
    include: { 
        botProduct: true,
        user: true
    }
  });

  console.log('--- ACTIVE SYNCS IN THE LAST HOUR ---');
  activePurchases.forEach(p => {
    console.log(`Bot: ${p.botProduct.name}`);
    console.log(`User: ${p.user.email}`);
    console.log(`ID: ${p.id}`);
    console.log(`LastSync: ${p.lastSync}`);
    console.log('---------------------------');
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
