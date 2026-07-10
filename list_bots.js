const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
    let products = await prisma.botProduct.findMany();
    products.forEach(p => console.log(`- ${p.name} (ID: ${p.id})`));
}
main().catch(e => console.error(e)).finally(() => prisma.$disconnect());
