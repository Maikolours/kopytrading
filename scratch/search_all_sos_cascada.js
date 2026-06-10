const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("--- SEARCHING ALL SOS AND CASCADA LOGS IN DB ---");

    const allLogs = await prisma.requestLog.findMany({
        where: {
            body: {
                not: null
            }
        },
        orderBy: {
            createdAt: 'asc'
        }
    });

    console.log(`Checking ${allLogs.length} logs...`);

    const matches = [];
    for (const log of allLogs) {
        const bodyStr = log.body.toUpperCase();
        if (bodyStr.includes("CASCADA") || bodyStr.includes("SOS")) {
            matches.push({
                date: log.createdAt.toISOString(),
                path: log.path,
                body: log.body
            });
        }
    }

    console.log(`Total matching logs in database: ${matches.length}`);

    // Group matches by calendar day
    const grouped = {};
    for (const match of matches) {
        const day = match.date.substring(0, 10);
        if (!grouped[day]) grouped[day] = [];
        grouped[day].push(match);
    }

    console.log("\nMatches grouped by day:");
    for (const day of Object.keys(grouped).sort()) {
        console.log(`- Day: ${day} | Count: ${grouped[day].length}`);
        
        // Print 3 samples per day
        console.log("  Samples:");
        const samples = grouped[day].slice(0, 3);
        for (const sample of samples) {
            console.log(`    [${sample.date}] Path: ${sample.path}`);
            console.log(`    Body (truncated): ${sample.body.substring(0, 300)}`);
        }
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
