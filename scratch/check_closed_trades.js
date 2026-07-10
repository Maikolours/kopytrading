const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const trades = await prisma.tradeHistory.findMany({
    where: {
      account: "27625151"
    },
    orderBy: { closedAt: "desc" }
  });
  console.log("=== Closed Trades for 27625151 ===");
  for (const t of trades) {
    console.log(`Time: ${t.closedAt}`);
    console.log(`Ticket: ${t.ticket}, Type: ${t.type}, Lots: ${t.lots}`);
    console.log(`  Open: ${t.openPrice}, Close: ${t.closePrice}, PnL: ${t.profit}`);
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
