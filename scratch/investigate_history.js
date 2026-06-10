const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("--- INVESTIGATING BOT HISTORY FROM DATABASE ---");

    // 1. Check all RequestLogs from May 16th to May 21st, 2026
    const startDate = new Date("2026-05-16T00:00:00Z");
    const endDate = new Date("2026-05-21T23:59:59Z");

    console.log("\nSearching RequestLogs...");
    const logs = await prisma.requestLog.findMany({
        where: {
            createdAt: {
                gte: startDate,
                lte: endDate
            }
        },
        orderBy: {
            createdAt: 'asc'
        }
    });
    console.log(`Found ${logs.length} RequestLogs between May 16 and May 21.`);
    
    // Group logs by paths and sample body/query if any
    const pathSummary = {};
    for (const log of logs) {
        if (!pathSummary[log.path]) pathSummary[log.path] = 0;
        pathSummary[log.path]++;
    }
    console.log("Paths accessed:", pathSummary);

    // 2. Check BotSettings active or updated around those dates
    console.log("\nChecking BotSettings...");
    const settings = await prisma.botSettings.findMany({
        include: {
            purchase: {
                include: {
                    botProduct: true,
                    user: true
                }
            }
        }
    });

    console.log(`Found ${settings.length} BotSettings entries:`);
    for (const s of settings) {
        console.log(`- Account: ${s.account}, Bot: ${s.purchase.botProduct.name}, UpdatedAt: ${s.updatedAt}`);
        try {
            const parsed = JSON.parse(s.settings);
            console.log(`  Settings keys:`, Object.keys(parsed));
        } catch (e) {
            console.log(`  Raw settings (first 100 chars):`, s.settings.substring(0, 100));
        }
    }

    // 3. Check Purchases and their history
    console.log("\nChecking Purchases...");
    const purchases = await prisma.purchase.findMany({
        include: {
            botProduct: true,
            user: true
        }
    });
    for (const p of purchases) {
        console.log(`- Purchase ID: ${p.id}, User: ${p.user.email}, Bot: ${p.botProduct.name}, Key: ${p.productKey || p.botProduct.productKey}, Status: ${p.status}`);
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
