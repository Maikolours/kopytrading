const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const settings = await prisma.botSettings.findMany({
    where: {
      account: '1028690'
    },
    include: {
      purchase: {
        include: {
          botProduct: true
        }
      }
    }
  });
  console.log(JSON.stringify(settings, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
