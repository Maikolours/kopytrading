const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  console.log("=== Fetching all Trade History grouped by account ===");

  const summary = await prisma.tradeHistory.groupBy({
    by: ['account', 'purchaseId'],
    _sum: {
      profit: true
    },
    _count: {
      id: true
    },
    _min: {
      closedAt: true
    },
    _max: {
      closedAt: true
    }
  });

  for (const item of summary) {
    // Get purchase details
    const purchase = await prisma.purchase.findUnique({
      where: { id: item.purchaseId },
      include: { botProduct: true }
    });

    console.log(`\nAccount: ${item.account}`);
    console.log(`Bot Product: ${purchase ? purchase.botProduct.name : 'Unknown'}`);
    console.log(`Total Trades: ${item._count.id}`);
    console.log(`Total PnL Sum: ${item._sum.profit ? item._sum.profit.toFixed(2) : '0.00'}`);
    console.log(`First Trade: ${item._min.closedAt}`);
    console.log(`Last Trade: ${item._max.closedAt}`);
    
    // Active positions count and sum
    const activeSum = await prisma.livePosition.aggregate({
      where: { account: item.account, purchaseId: item.purchaseId },
      _sum: { profit: true },
      _count: { id: true }
    });
    console.log(`Active Positions: ${activeSum._count.id} (Floating PnL: ${activeSum._sum.profit ? activeSum._sum.profit.toFixed(2) : '0.00'})`);
    
    // Balance and equity in purchase
    console.log(`Purchase Balance: ${purchase.balance}`);
    console.log(`Purchase Equity: ${purchase.equity}`);
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
