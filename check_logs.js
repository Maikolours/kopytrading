const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
async function main() {
    const logs = await p.requestLog.findMany({ orderBy: { createdAt: 'desc' }, take: 5 });
    console.log(JSON.stringify(logs, null, 2));
}
main().catch(console.error).finally(() => p.$disconnect());
