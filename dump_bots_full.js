const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const prisma = new PrismaClient();

async function main() {
    const bots = await prisma.botProduct.findMany();
    fs.writeFileSync('bots_dump.json', JSON.stringify(bots, null, 2));
    console.log('Bots dumped to bots_dump.json');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
