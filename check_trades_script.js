const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const trades = await prisma.tradeHistory.findMany({
    where: {
      account: '1028690'
    }
  });
  console.log(trades);
}

main().catch(console.error).finally(() => prisma.$disconnect());
