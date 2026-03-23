const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const bots = await prisma.botProduct.findMany({
        select: { id: true, name: true, price: true, version: true, status: true }
    });
    console.log(JSON.stringify(bots, null, 2));
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
