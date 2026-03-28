const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkAllSyncLogs() {
    console.log("🔍 Checking all recent /api/sync-positions logs...");
    
    try {
        const logs = await prisma.requestLog.findMany({
            where: {
                path: { contains: "sync-positions" }
            },
            orderBy: { createdAt: 'desc' },
            take: 20
        });

        if (logs.length === 0) {
            console.log("❌ No sync logs found at all.");
        } else {
            console.log(`Found ${logs.length} sync logs.`);
            logs.forEach(l => {
                console.log(`[${l.createdAt.toISOString()}] Error: ${l.error ? 'YES' : 'No'}`);
                if (l.body) {
                    try {
                        const body = JSON.parse(l.body.substring(0, 500));
                        console.log(` - ID: ${body.purchaseId}`);
                    } catch (e) {
                        console.log(` - Body (raw): ${l.body.substring(0, 100)}...`);
                    }
                }
                console.log('---');
            });
        }
    } catch (e) {
        console.error("❌ Error:", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

checkAllSyncLogs();
