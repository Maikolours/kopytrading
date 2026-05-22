const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function updateBots() {
    // Actualizar nombres y strategyType correctos
    const updates = [
        {
            id: 'cmn9hf8yc0000vhbcq9hbxk0j',
            name: 'MAIKO PRO GOLD DEMO',
            strategyType: 'Scalping · M15'
        },
        {
            id: 'cmn9hf9440001vhbclffx9no6',
            name: 'MAIKO PRO GOLD',
            strategyType: 'Scalping · M15'
        },
        {
            id: 'cmn9hf9800002vhbc5rky6dx8',
            name: 'MAIKO PRO CENT',
            strategyType: 'Scalping · Cent'
        },
        {
            id: 'cmn9hf9bm0003vhbckaamkqal',
            name: 'MAIKO PRO BTC',
            strategyType: 'Breakout · H4'
        }
    ];

    for (const update of updates) {
        await p.botProduct.update({
            where: { id: update.id },
            data: {
                name: update.name,
                strategyType: update.strategyType
            }
        });
        console.log(`✅ Updated: ${update.id} → ${update.name}`);
    }

    // Verificar resultado
    const bots = await p.botProduct.findMany({
        select: { id: true, name: true, status: true, price: true, strategyType: true }
    });
    console.log('\n📋 Estado actual:');
    console.log(JSON.stringify(bots, null, 2));
}

updateBots().catch(console.error).finally(() => p.$disconnect());
