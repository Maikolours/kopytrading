const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = "cmmb2z6ml000dvhhoj1s9zmnf"; // viajaconsakura
  const purchases = await prisma.purchase.findMany({
    where: { userId: userId },
    include: { botProduct: true }
  });

  console.log("CURRENT_TIME:", new Date().toISOString());
  purchases.forEach(p => {
    console.log(`${p.botProduct.name} | ID: ${p.id} | LAST_SYNC: ${p.lastSync ? p.lastSync.toISOString() : "NEVER"}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
