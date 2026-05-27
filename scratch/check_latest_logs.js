const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- LATEST LOGS ---');
    const logs = await prisma.requestLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 15
    });
    
    logs.forEach(l => {
        console.log(`[${l.createdAt.toISOString()}] Path: ${l.path} | Method: ${l.method}`);
        console.log(`Error: ${l.error}`);
        console.log(`Body: ${l.body?.substring(0, 300)}`);
        console.log('----------------------------------------------------');
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
