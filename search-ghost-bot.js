const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const bots = await prisma.botProduct.findMany({
      where: { name: { contains: 'Euro Precision' } },
      include: { 
          purchases: {
              where: {
                  lastSync: { gte: new Date(Date.now() - 5 * 60 * 1000) } // Last 5 mins
              },
              include: { user: true }
          }
      }
  });

  console.log('--- EURO PRECISION FLOW GHOST SYNC ---');
  bots.forEach(b => {
    console.log(`Bot ID: ${b.id}, Name: ${b.name}`);
    b.purchases.forEach(p => {
        console.log(`  - User: ${p.user.email}`);
        console.log(`    Purchase ID: ${p.id}`);
        console.log(`    LastSync: ${p.lastSync}`);
    });
  });

  // También revisar logs de errores/peticiones recientes para ese bot
  const logs = await prisma.requestLog.findMany({
      where: { body: { contains: 'Euro Precision' } },
      take: 5,
      orderBy: { createdAt: 'desc' }
  });
  console.log('\n--- RECENT REQUEST LOGS ---');
  logs.forEach(l => {
      console.log(`Log: ${l.createdAt}`);
      console.log(`Body: ${l.body}`);
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
