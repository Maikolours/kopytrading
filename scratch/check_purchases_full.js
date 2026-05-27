const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== LISTANDO TODAS LAS COMPRAS ===");
    const purchases = await prisma.purchase.findMany({
        include: {
            botProduct: true,
            user: true
        }
    });

    purchases.forEach(p => {
        console.log(`ID: ${p.id} | Email: ${p.user.email} | Bot: ${p.botProduct.name} | Balance: ${p.balance}`);
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
