const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
    console.log('--- Starting Simplified Bot Seed ---');

    // 1. Limpiar datos antiguos
    await prisma.botProduct.deleteMany({});

    const bots = [
        {
            name: 'Elite Sniper',
            description: '⚡ **PRÓXIMO LANZAMIENTO**\n\n₿ El algoritmo más avanzado para Bitcoin. Basado en el motor TITAN de ejecución institucional para una precisión absoluta en el mercado cripto.',
            instrument: 'BTCUSD',
            strategyType: 'Sniper v11.2',
            riskLevel: 'Medium',
            price: 299.00,
            version: '11.2.6',
            timeframes: 'H1 (Recomendado), M15',
            minCapital: 2000,
            isActive: true,
            status: 'UPCOMING',
        },
        {
            name: 'Oro',
            description: '🛠️ **PRÓXIMO LANZAMIENTO**\n\n🛡️ **Calibrando la versión de alta precisión para el Oro.** Estamos optimizando la gestión de riesgo y los filtros de liquidez institucional.',
            instrument: 'XAUUSD',
            strategyType: 'Scalping Institucional',
            riskLevel: 'Medium',
            price: 249.00,
            version: '1.0',
            timeframes: 'M15',
            minCapital: 1000,
            isActive: true,
            status: 'UPCOMING',
        },
        {
            name: 'Euro',
            description: '🎯 **PRÓXIMO LANZAMIENTO**\n\n📈 Optimizando el Scalper Europeo para adaptarlo a las nuevas condiciones de volatilidad bancaria. Precisión quirúrgica en el par EURUSD.',
            instrument: 'EURUSD',
            strategyType: 'Precision Flow',
            riskLevel: 'Low',
            price: 179.00,
            version: '1.0',
            timeframes: 'H1, M15',
            minCapital: 500,
            isActive: true,
            status: 'UPCOMING',
        },
        {
            name: 'Yen',
            description: '🥷 **PRÓXIMO LANZAMIENTO**\n\n🌙 Diseñado específicamente para capturar movimientos explosivos en la sesión asiática con filtros de volatilidad mejorados.',
            instrument: 'USDJPY',
            strategyType: 'Ninja Ghost',
            riskLevel: 'Medium',
            price: 149.00,
            version: '1.0',
            timeframes: 'M30, H1',
            minCapital: 500,
            isActive: true,
            status: 'UPCOMING',
        }
    ];

    for (const bot of bots) {
        await prisma.botProduct.create({ data: bot });
    }

    console.log('--- Seed Complete: 4 bots created ---');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
