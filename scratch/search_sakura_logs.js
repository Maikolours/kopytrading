const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- LATEST LOGS CONTAINING SAKURA OR CMN9H ---');
    const logs = await prisma.requestLog.findMany({
        where: {
            OR: [
                { body: { contains: 'viajaconsakura' } },
                { error: { contains: 'SAKURA' } },
                { body: { contains: 'cmn9h' } }
            ]
        },
        orderBy: { createdAt: 'desc' },
        take: 15
    });
    
    logs.forEach(l => {
        console.log(`[${l.createdAt.toISOString()}] Path: ${l.path} | Error: ${l.error}`);
        console.log(`Body: ${l.body?.substring(0, 300)}`);
        console.log('----------------------------------------------------');
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
