const { PrismaClient } = require('./node_modules/@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- LATEST SYNC LOGS (Last 5 mins) ---');
  const fiveMinsAgo = new Date(Date.now() - 5 * 60 * 1000);
  const logs = await prisma.requestLog.findMany({
    where: { 
      path: '/api/sync-positions',
      createdAt: { gte: fiveMinsAgo }
    },
    orderBy: { createdAt: 'desc' },
    take: 10
  });
  
  if (logs.length === 0) {
    console.log('NO LOGS FOUND IN THE LAST 5 MINUTES. The bot is NOT reaching the server.');
  } else {
    logs.forEach(l => {
        console.log(`[${l.createdAt.toISOString()}] Error: ${l.error} | Body: ${l.body?.substring(0, 100)}`);
    });
  }
  
  // Also check if any purchase exists with that specific ID just to be 100% sure
  const targetId = 'CMMV3XVGP000UVHMCRAIAY5L4-BTCCENT';
  const p = await prisma.purchase.findUnique({ where: { id: targetId } });
  console.log(`\nVerification of ID [${targetId}]: ${p ? 'FOUND' : 'NOT FOUND'}`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
