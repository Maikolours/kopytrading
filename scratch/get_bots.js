const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const bots = await prisma.botProduct.findMany({
        select: { id: true, name: true, instrument: true, isActive: true }
    });
    console.log(JSON.stringify(bots, null, 2));
    await prisma.$disconnect();
}

main();
