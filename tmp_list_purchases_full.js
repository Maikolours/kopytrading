const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = "cmmb2z6ml000dvhhoj1s9zmnf"; // viajaconsakura
  const purchases = await prisma.purchase.findMany({
    where: { userId: userId },
    include: { botProduct: true }
  });

  console.log(`=== TOTAL PURCHASES: ${purchases.length} ===`);
  for (const p of purchases) {
    console.log(`ID: ${p.id} | Bot: ${p.botProduct.name} | Status: ${p.status} | Sync: ${p.lastSync}`);
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
