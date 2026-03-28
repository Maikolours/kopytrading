const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkRecentRequests() {
    console.log("🔍 Checking all recent requests today...");
    
    try {
        const today = new Date();
        today.setHours(0,0,0,0);

        const logs = await prisma.requestLog.findMany({
            where: {
                createdAt: { gte: today }
            },
            orderBy: { createdAt: 'desc' },
            take: 50
        });

        console.log(`Found ${logs.length} requests today.`);
        logs.forEach(l => {
            console.log(`[${l.createdAt.toISOString()}] ${l.method} ${l.path} - Error: ${l.error ? 'YES' : 'No'}`);
            if (l.error) console.log(`   Error: ${l.error.substring(0, 100)}`);
        });
    } catch (e) {
        console.error("❌ Error:", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

checkRecentRequests();
