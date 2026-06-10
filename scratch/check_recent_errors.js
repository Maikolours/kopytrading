const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const logs = await prisma.requestLog.findMany({
    where: { 
      createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      error: { not: null }
    },
    orderBy: { createdAt: 'desc' },
    take: 10
  });
  console.log("=== RECENT ERRORS ===");
  logs.forEach(l => {
    console.log(`[${l.createdAt}] ${l.error}`);
    // console.log(`Body: ${l.body.substring(0, 100)}`);
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
