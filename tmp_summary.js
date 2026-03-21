const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = "cmmb2z6ml000dvhhoj1s9zmnf"; // viajaconsakura
  const purchases = await prisma.purchase.findMany({
    where: { userId: userId },
    include: { botProduct: true },
    orderBy: { botProductId: 'asc' }
  });

  console.log("=== COMPRAS VIAJACONSAKURA ===");
  purchases.forEach(p => {
    console.log(`BOT: ${p.botProduct.name.padEnd(30)} | ID: ${p.id} | TYPE: ${p.status.padEnd(8)} | SYNC: ${p.lastSync ? p.lastSync.toISOString() : "NEVER"}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
