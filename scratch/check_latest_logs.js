const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const logs = await prisma.requestLog.findMany({
    orderBy: { createdAt: 'desc' },
    take: 20
  });
  console.log("=== LATEST REQUEST LOGS ===");
  logs.forEach(l => {
    console.log(`[${l.createdAt}] IP: ${l.ip} | Route: ${l.route} | Error: ${l.error || 'None'}`);
    if (l.body) {
        try {
            const bodyObj = JSON.parse(l.body);
            console.log(`   Body: account=${bodyObj.account}, botName=${bodyObj.botName}, id=${bodyObj.purchaseId}, balance=${bodyObj.balance}`);
        } catch(e) {
            console.log(`   Body: ${l.body.substring(0, 100)}`);
        }
    }
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
