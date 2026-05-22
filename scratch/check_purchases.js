const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- ALL PURCHASES WITH BOTS ---');
    const purchases = await prisma.purchase.findMany({
        include: {
            botProduct: true,
            activePositions: true
        }
    });
    
    purchases.forEach(p => {
        console.log(`\nPurchase ID: ${p.id}`);
        console.log(`Bot Product Name: ${p.botProduct?.name} (${p.botProduct?.instrument})`);
        console.log(`User ID: ${p.userId}`);
        console.log(`Last Status: ${p.lastStatus} | Balance: ${p.balance} | Equity: ${p.equity}`);
        console.log(`Active Positions: ${p.activePositions?.length || 0} positions`);
        if (p.activePositions && p.activePositions.length > 0) {
            p.activePositions.forEach(pos => {
                console.log(`  - Account: ${pos.account} | symbol: ${pos.symbol} | volume: ${pos.volume} | isCent: ${pos.isCent} | isReal: ${pos.isReal}`);
            });
        }
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
