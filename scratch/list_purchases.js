const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const purchases = await prisma.purchase.findMany({
    include: { botProduct: true }
  });
  console.log("=== Purchases ===");
  for (const p of purchases) {
    console.log(`Product: ${p.botProduct.name}`);
    console.log(`  License ID: ${p.id}`);
    console.log(`  UserId: ${p.userId}`);
    console.log(`  ProductKey: ${p.botProduct.productKey}`);
    console.log(`  LastSync: ${p.lastSync}`);
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
