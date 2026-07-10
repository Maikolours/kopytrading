const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("Searching for viajaconsakura user...");
    const user = await prisma.user.findFirst({
        where: {
            email: {
                contains: "viajaconsakura"
            }
        }
    });

    if (!user) {
        console.log("User not found!");
        return;
    }

    console.log(`User found: ${user.name} (${user.email}), ID: ${user.id}`);

    const purchases = await prisma.purchase.findMany({
        where: {
            userId: user.id
        },
        include: {
            botProduct: true,
            botSettings: true
        }
    });

    console.log(`Purchases count: ${purchases.length}`);
    purchases.forEach(p => {
        console.log(`\nPurchase ID: ${p.id}, Status: ${p.status}`);
        console.log(`Bot: ${p.botProduct.name}`);
        console.log(`Settings count: ${p.botSettings.length}`);
        p.botSettings.forEach(s => {
            console.log(`  - Account: ${s.account}`);
            console.log(`    Settings: ${s.settings}`);
        });
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
