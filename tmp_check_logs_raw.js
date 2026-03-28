const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkAllLogs() {
    console.log("🔍 Checking last 50 logs...");
    
    try {
        const logs = await prisma.requestLog.findMany({
            orderBy: { createdAt: 'desc' },
            take: 50
        });

        console.log(`Found ${logs.length} logs.`);
        logs.forEach(l => {
            console.log(`[${l.createdAt.toISOString()}] ${l.method} ${l.path} - Error: ${l.error ? 'YES' : 'No'}`);
            if (l.body) console.log(`   Body: ${l.body.substring(0, 100)}...`);
            if (l.error) console.log(`   Error: ${l.error.substring(0, 100)}`);
        });
    } catch (e) {
        console.error("❌ Error:", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

checkAllLogs();
