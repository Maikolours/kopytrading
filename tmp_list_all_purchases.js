const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = "cmmrxrks00000vhmc7izw11z9";
  const purchases = await prisma.purchase.findMany({
    where: { userId: userId },
    include: { botProduct: true }
  });

  console.log(`=== PURCHASES FOR ${userId} ===`);
  purchases.forEach(p => {
    console.log(`ID: ${p.id} | Bot: ${p.botProduct.name} | Sync: ${p.lastSync}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
