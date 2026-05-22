const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- SYSTEM POSITIONS ACTIVE ---');
    const positions = await prisma.livePosition.findMany({
        orderBy: { updatedAt: 'desc' }
    });
    positions.forEach(pos => {
        console.log(`\nPosition ID: ${pos.id}`);
        console.log(`Purchase ID: ${pos.purchaseId}`);
        console.log(`Account: ${pos.account} | symbol: ${pos.symbol} | volume: ${pos.volume} | isCent: ${pos.isCent}`);
        console.log(`Updated At: ${pos.updatedAt}`);
    });

    console.log('\n--- LATEST REQUEST LOGS FROM BOT SYNC ---');
    const logs = await prisma.requestLog.findMany({
        where: { path: '/api/sync-positions' },
        orderBy: { createdAt: 'desc' },
        take: 10
    });
    logs.forEach(l => {
        console.log(`[${l.createdAt.toISOString()}] Purchase ID/Body: ${l.body}`);
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
