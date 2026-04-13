const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
    console.log('--- Starting Bot Catalog Migration (JS) ---');

    // 1. Deactivate all bots first to have a clean slate
    await prisma.botProduct.updateMany({
        data: { isActive: false }
    });

    // 2. Define the 4 target bots
    const targetBots = [
        {
            name: 'Elite Sniper',
            instrument: 'BTCUSD',
            description: '⚡ **PRÓXIMO LANZAMIENTO**\n\n₿ El algoritmo más avanzado para Bitcoin. Basado en el motor TITAN de ejecución institucional para una precisión absoluta en el mercado cripto.',
            strategyType: 'Sniper v11.2',
            riskLevel: 'Medium',
            price: 299.00,
            status: 'UPCOMING',
            isActive: true,
        },
        {
            name: 'Oro',
            instrument: 'XAUUSD',
            description: '🛠️ **PRÓXIMO LANZAMIENTO**\n\n🛡️ **Calibrando la versión de alta precisión para el Oro.** Estamos optimizando la gestión de riesgo y los filtros de liquidez institucional.',
            strategyType: 'Scalping Institucional',
            riskLevel: 'Medium',
            price: 249.00,
            status: 'UPCOMING',
            isActive: true,
        },
        {
            name: 'Euro',
            instrument: 'EURUSD',
            description: '🎯 **PRÓXIMO LANZAMIENTO**\n\n📈 Optimizando el Scalper Europeo para adaptarlo a las nuevas condiciones de volatilidad bancaria. Precisión quirúrgica en el par EURUSD.',
            strategyType: 'Precision Flow',
            riskLevel: 'Low',
            price: 179.00,
            status: 'UPCOMING',
            isActive: true,
        },
        {
            name: 'Yen',
            instrument: 'USDJPY',
            description: '🥷 **PRÓXIMO LANZAMIENTO**\n\n🌙 Diseñado específicamente para capturar movimientos explosivos en la sesión asiática con filtros de volatilidad mejorados.',
            strategyType: 'Ninja Ghost',
            riskLevel: 'Medium',
            price: 149.00,
            status: 'UPCOMING',
            isActive: true,
        }
    ];

    // 3. Upsert bots based on instrument
    for (const data of targetBots) {
        const existing = await prisma.botProduct.findFirst({
            where: {
                OR: [
                    { instrument: data.instrument },
                    { name: data.name }
                ]
            }
        });

        if (existing) {
            console.log(`Updating existing bot: ${existing.name} -> ${data.name}`);
            await prisma.botProduct.update({
                where: { id: existing.id },
                data: data
            });
        } else {
            console.log(`Creating new bot: ${data.name}`);
            await prisma.botProduct.create({ data: data });
        }
    }

    console.log('--- Migration Complete! 4 Master Bots Active ---');
}

main()
    .catch((e) => {
        console.error('Migration failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
