const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = "cmmb2z6ml000dvhhoj1s9zmnf"; // viajaconsakura
  const purchases = await prisma.purchase.findMany({
    where: { userId: userId },
    include: { botProduct: true }
  });

  console.log(`=== PURCHASES FOR viajaconsakura (${userId}) ===`);
  purchases.forEach(p => {
    console.log(`ID: ${p.id}`);
    console.log(`Bot: ${p.botProduct.name}`);
    console.log(`Status: ${p.status}`);
    console.log(`Sync: ${p.lastSync}`);
    console.log("---");
  });
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
