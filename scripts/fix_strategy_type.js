const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function fixStrategyTypes() {
    // Todos los bots trabajan en M1
    const ids = [
        'cmn9hf8yc0000vhbcq9hbxk0j',  // MAIKO PRO GOLD DEMO
        'cmn9hf9440001vhbclffx9no6',   // MAIKO PRO GOLD
        'cmn9hf9800002vhbc5rky6dx8',   // MAIKO PRO CENT
        'cmn9hf9bm0003vhbckaamkqal',   // MAIKO PRO BTC
    ];

    for (const id of ids) {
        await p.botProduct.update({
            where: { id },
            data: { strategyType: 'Scalping · M1' }
        });
        console.log(`✅ Updated strategyType → M1: ${id}`);
    }

    const bots = await p.botProduct.findMany({
        select: { id: true, name: true, strategyType: true }
    });
    console.log('\n📋 Resultado:');
    bots.forEach(b => console.log(`  ${b.name}: ${b.strategyType}`));
}

fixStrategyTypes().catch(console.error).finally(() => p.$disconnect());
