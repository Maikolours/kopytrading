const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkSpecificBot() {
    const targetId = 'cmn9hfaxg000lvhbcqidlvvfm';
    console.log(`🔍 Checking logs for bot: ${targetId}`);
    
    try {
        const logs = await prisma.requestLog.findMany({
            where: {
                body: { contains: targetId }
            },
            orderBy: { createdAt: 'desc' },
            take: 10
        });

        console.log(`Found ${logs.length} logs for this bot.`);
        logs.forEach(l => {
            console.log(`[${l.createdAt.toISOString()}] ${l.method} ${l.path} - Error: ${l.error ? 'YES' : 'No'}`);
            console.log(`   Body: ${l.body}`);
            if (l.error) console.log(`   Error: ${l.error}`);
        });

        const purchase = await prisma.purchase.findUnique({
            where: { id: targetId },
            include: { activePositions: true }
        });
        console.log(`\nBot Status in DB:`);
        console.log(`Last Sync: ${purchase.lastSync}`);
        console.log(`Active Positions: ${purchase.activePositions.length}`);

    } catch (e) {
        console.error("❌ Error:", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

checkSpecificBot();
