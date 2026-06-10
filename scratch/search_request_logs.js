const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("--- REQUEST LOG GENERAL STATS ---");

    const totalLogs = await prisma.requestLog.count();
    console.log(`Total RequestLog count in DB: ${totalLogs}`);

    if (totalLogs === 0) return;

    const firstLog = await prisma.requestLog.findFirst({
        orderBy: { createdAt: 'asc' }
    });
    const lastLog = await prisma.requestLog.findFirst({
        orderBy: { createdAt: 'desc' }
    });

    console.log(`First log date: ${firstLog.createdAt.toISOString()}`);
    console.log(`Last log date: ${lastLog.createdAt.toISOString()}`);

    // Let's sample the last 5 logs
    console.log("\nLast 5 logs:");
    const last5 = await prisma.requestLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 5
    });
    for (const log of last5) {
        console.log(`[${log.createdAt.toISOString()}] Method: ${log.method} | Path: ${log.path}`);
        console.log(`Body:`, log.body ? log.body.substring(0, 200) : "null");
    }

    // Let's do a search across all RequestLogs for the word "CASCADA" or "SOS" in their body
    console.log("\nSearching all logs in database for 'CASCADA' or 'SOS' in the body column...");
    
    // SQLite query using findMany and filtering in JS to be safe and simple
    const allLogs = await prisma.requestLog.findMany({
        where: {
            body: {
                not: null
            }
        }
    });

    console.log(`Analyzing ${allLogs.length} logs with non-null bodies...`);
    let matches = 0;
    for (const log of allLogs) {
        const bodyStr = log.body.toUpperCase();
        if (bodyStr.includes("CASCADA") || bodyStr.includes("SOS")) {
            console.log(`Match #${++matches}: [${log.createdAt.toISOString()}] Path: ${log.path}`);
            console.log(`Body: ${log.body}`);
            if (matches >= 20) {
                console.log("Reached limit of displayed matches.");
                break;
            }
        }
    }
    console.log(`Total matching logs: ${matches}`);
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
