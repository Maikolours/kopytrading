const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  await prisma.botProduct.updateMany({
    where: {
      OR: [
        { id: 'cmn9hf8yc0000vhbcq9hbxk0j' },
        { id: 'cmquperki0000vhfopdx8d5f0' }
      ]
    },
    data: { status: 'UPCOMING' }
  });
  console.log('Bots Demo actualizados a Próximamente (UPCOMING)');
}

main().finally(() => prisma.$disconnect());
