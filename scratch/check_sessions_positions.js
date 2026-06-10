const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== SESSIONS ===");
  const sessions = await prisma.licenseSession.findMany({
    orderBy: { lastActivity: 'desc' }
  });
  sessions.forEach(s => {
    console.log(`Purchase ID: ${s.purchaseId}, Account: ${s.account}, Last Activity: ${s.lastActivity}, Is Active: ${s.isActive}`);
  });

  console.log("\n=== RECENT LIVE POSITIONS ===");
  const livePos = await prisma.livePosition.findMany({
    orderBy: { updatedAt: 'desc' },
    take: 20
  });
  livePos.forEach(p => {
    console.log(`Purchase ID: ${p.purchaseId}, Ticket: ${p.ticket}, Type: ${p.type}, Symbol: ${p.symbol}, Lots: ${p.lots}, Profit: ${p.profit}, Account: ${p.account}, Updated: ${p.updatedAt}`);
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
