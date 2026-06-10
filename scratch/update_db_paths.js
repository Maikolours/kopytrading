const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  await prisma.botProduct.updateMany({
    where: { ex5FilePath: '/uploads/KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.ex5' },
    data: { ex5FilePath: '/uploads/Maiko_Sniper_PRO_GOLD_CLIENT.ex5' }
  });
  console.log("Updated DB paths.");
}
main().finally(() => prisma.$disconnect());
