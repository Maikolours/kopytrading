const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function updateBots() {
    const updates = [
        {
            id: 'cmn9hf8yc0000vhbcq9hbxk0j', // GOLD DEMO
            description: 'Prueba nuestro bot estrella MAIKO PRO GOLD durante 30 días en tu cuenta demo. Algoritmo de alta frecuencia (M1) con entradas tipo Sniper y gestión dinámica de drawdown (Grid).',
            strategyType: 'Sniper Grid · M1',
            timeframes: 'M1 (Optimizado), M5'
        },
        {
            id: 'cmn9hf9440001vhbclffx9no6', // GOLD REAL
            description: 'El algoritmo insignia para Oro. Diseñado para M1 con entradas hiperprecisas tipo Sniper y recuperación mediante grid y martingala dinámica. Ideal para scalping agresivo en XAUUSD.',
            strategyType: 'Sniper Grid · M1',
            timeframes: 'M1 (Optimizado), M5'
        },
        {
            id: 'cmn9hf9800002vhbc5rky6dx8', // CENT
            description: 'La agresividad y precisión del Sniper Gold adaptada a cuentas CENT. Ejecuta en M1 usando los mismos algoritmos de recuperación pero reduciendo la exposición del capital drásticamente.',
            strategyType: 'Sniper Grid · M1',
            timeframes: 'M1 (Optimizado), M5'
        },
        {
            id: 'cmn9hf9bm0003vhbckaamkqal', // BTC
            description: 'Ejecución institucional adaptada al Bitcoin (BTCUSD) en temporalidad M1. Captura micropulsos del precio los fines de semana con entradas Sniper y promediado inteligente del precio.',
            strategyType: 'Sniper Grid · M1',
            timeframes: 'M1 (Optimizado)'
        }
    ];

    for (const update of updates) {
        await p.botProduct.update({
            where: { id: update.id },
            data: {
                description: update.description,
                strategyType: update.strategyType,
                timeframes: update.timeframes
            }
        });
        console.log(`✅ Updated: ${update.id}`);
    }

    const bots = await p.botProduct.findMany({
        select: { name: true, description: true, strategyType: true, timeframes: true }
    });
    console.log('\n📋 Nuevo Estado:');
    console.log(JSON.stringify(bots, null, 2));
}

updateBots().catch(console.error).finally(() => p.$disconnect());
