const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const purchaseId = "cmqb9gq130002l704pwj1vxgu";
  const purchase = await prisma.purchase.findUnique({
    where: { id: purchaseId },
    include: { 
      user: true,
      botProduct: true
    }
  });

  if (!purchase) {
    console.log("Purchase not found!");
    return;
  }

  console.log("=== Client Purchase ===");
  console.log(`User: ${purchase.user.email} (Name: ${purchase.user.name})`);
  console.log(`Product: ${purchase.botProduct.name}`);
  console.log(`Last Sync: ${purchase.lastSync}`);
  console.log(`Balance: ${purchase.balance}`);
  console.log(`Equity: ${purchase.equity}`);
  console.log(`Last Status: ${purchase.lastStatus}`);

  const settings = await prisma.botSettings.findMany({
    where: { purchaseId: purchaseId }
  });

  console.log("=== Settings ===");
  for (const s of settings) {
    console.log(`Account: ${s.account}`);
    console.log(`Settings: ${s.settings}`);
  }

  const livePositions = await prisma.livePosition.findMany({
    where: { purchaseId: purchaseId }
  });

  console.log("=== Live Positions ===");
  if (livePositions.length === 0) {
    console.log("No live positions registered in DB!");
  } else {
    for (const pos of livePositions) {
      console.log(`  Ticket: ${pos.ticket}, Type: ${pos.type}, Symbol: ${pos.symbol}, Lots: ${pos.lots}, OpenPrice: ${pos.openPrice}, Profit: ${pos.profit}`);
    }
  }

  const session = await prisma.licenseSession.findUnique({
    where: { purchaseId: purchaseId }
  });

  console.log("=== Active Session ===");
  if (session) {
    console.log(`  Account: ${session.account}, LastActivity: ${session.lastActivity}, IsActive: ${session.isActive}`);
  } else {
    console.log("  No active session found.");
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
