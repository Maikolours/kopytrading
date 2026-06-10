const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchase = await prisma.purchase.findUnique({
    where: { id: "cmn9hfal4000fvhbcr34kst5x" },
    include: { botProduct: true }
  });
  console.log("=== DEMO PURCHASE ===");
  if (!purchase) {
      console.log("Not found");
      return;
  }
  console.log("ID:", purchase.id);
  console.log("Balance:", purchase.balance);
  console.log("Equity:", purchase.equity);
  console.log("Last Sync:", purchase.lastSync);
  console.log("Bot Product:", purchase.botProduct.name);
}

main().catch(console.error).finally(() => prisma.$disconnect());
