const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchases = await prisma.purchase.findMany({
    include: {
      licenseSessions: true,
      botSettings: true
    }
  });
  
  purchases.forEach(p => {
    console.log(`Purchase ID: ${p.id}, Balance: ${p.balance}, Equity: ${p.equity}`);
    p.licenseSessions.forEach(s => console.log(`  LicenseSession Account: ${s.account}`));
    p.botSettings.forEach(s => console.log(`  BotSettings Account: ${s.account}`));
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
