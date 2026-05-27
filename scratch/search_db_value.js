const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== BUSCANDO EL VALOR 29037.56 EN LA BASE DE DATOS ===");
    
    // 1. Buscar en Purchases
    const purchases = await prisma.purchase.findMany({
        where: {
            OR: [
                { balance: 29037.56 },
                { equity: 29037.56 }
            ]
        },
        include: { botProduct: true }
    });
    console.log(`\nEncontrado en Purchases (${purchases.length} registros):`);
    purchases.forEach(p => {
        console.log(`  - Purchase ID: ${p.id} | Bot Product: ${p.botProduct.name} | Balance: ${p.balance} | Equity: ${p.equity}`);
    });
    
    // 2. Buscar en LivePosition
    const positions = await prisma.livePosition.findMany({
        where: {
            OR: [
                { profit: 29037.56 }
            ]
        },
        include: { purchase: { include: { botProduct: true } } }
    });
    console.log(`\nEncontrado en LivePosition (${positions.length} registros):`);
    
    // 3. Buscar en BotSettings
    const settings = await prisma.botSettings.findMany();
    console.log(`\nEncontrado en BotSettings:`);
    settings.forEach(s => {
        if (s.settings.includes("29037.56")) {
            console.log(`  - Settings ID: ${s.id} | Account: ${s.account} | Purchase ID: ${s.purchaseId} | Settings sample: ${s.settings.substring(0, 150)}...`);
        }
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
