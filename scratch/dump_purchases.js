const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== LISTANDO COMPRAS DE SAKURA ===");
    const purchases = await prisma.purchase.findMany({
        where: {
            user: {
                email: { contains: "viajaconsakura" }
            }
        },
        include: {
            botProduct: true
        }
    });

    purchases.forEach(p => {
        console.log(`\nPurchase ID: ${p.id}`);
        console.log(`Bot Product: ${p.botProduct.name} [ID: ${p.botProduct.id}]`);
        console.log(`Licencia / ProductKey: ${p.productKey || p.botProduct.productKey}`);
        console.log(`Balance: ${p.balance}`);
        console.log(`Equity: ${p.equity}`);
        console.log(`Last Sync: ${p.lastSync}`);
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
