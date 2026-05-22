const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const userId = 'cmmb2z6ml000dvhhoj1s9zmnf';
    console.log(`--- DETAIL OF PURCHASES FOR USER ${userId} ---`);
    
    const purchases = await prisma.purchase.findMany({
        where: { userId: userId },
        include: {
            botProduct: true,
            activePositions: true,
            pastTrades: { take: 5 }
        }
    });

    purchases.forEach(p => {
        console.log(`\nPurchase ID: ${p.id}`);
        console.log(`Bot Product Name: ${p.botProduct?.name}`);
        console.log(`Instrument in DB: ${p.botProduct?.instrument}`);
        console.log(`Status in DB: ${p.status}`);
        console.log(`Last Sync: ${p.lastSync}`);
        console.log(`Balance: ${p.balance} | Equity: ${p.equity}`);
        console.log(`Last Status: ${p.lastStatus}`);
        console.log(`Active Positions synced: ${p.activePositions?.length || 0}`);
        console.log(`Past Trades in history: ${p.pastTrades?.length || 0}`);
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
