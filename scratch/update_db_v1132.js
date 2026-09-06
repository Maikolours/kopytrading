
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'MAIKO PRO GOLD DEMO' } },
        data: { ex5FilePath: '/uploads/bots/MAIKO_PRO_GOLD_DEMO.ex5', version: '11.32' }
    });
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'MAIKO PRO GOLD REAL' } },
        data: { ex5FilePath: '/uploads/bots/MAIKO_PRO_GOLD.ex5', version: '11.32' }
    });
    console.log('DATABASE UPDATED SUCCESSFULLY!');
}
main().catch(console.error).finally(() => prisma.$disconnect());
