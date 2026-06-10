const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const positions = await prisma.livePosition.findMany({
    where: {
      account: '1028690'
    }
  });
  console.log("Live positions:", positions);
}

main().catch(console.error).finally(() => prisma.$disconnect());
