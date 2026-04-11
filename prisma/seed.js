const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
    console.log('--- Reseteando y Sincronizando Productos (MODO SEGURO) ---');
    
    // 1. Definir productos básicos
    const sniperData = {
        productKey: 'SNIPER_V12',
        name: 'Elite Sniper',
        description: '⚡ **EDICIÓN ESPECIAL v13.18.2**\n\n₿ El algoritmo más avanzado para Bitcoin con control táctico de tendencia y ejecución Sniper.',
        instrument: 'BTCUSD',
        strategyType: 'Sniper v13',
        riskLevel: 'Medium',
        price: 299.00,
        version: '13.18.2',
        status: 'ACTIVE'
    };

    const oroData = {
        productKey: 'XAU-MG',
        name: 'Oro',
        description: '🔱 **AMETRALLADORA v2.2.0**\n\n🛡️ Scalping institucional de alta frecuencia para XAUUSD con gestión de riesgo blindada.',
        instrument: 'XAUUSD',
        strategyType: 'Ametralladora Scalping',
        riskLevel: 'Medium',
        price: 249.00,
        version: '2.2.0',
        status: 'ACTIVE'
    };

    // Actualizar Sniper
    const sniper = await prisma.botProduct.findFirst({ where: { name: { contains: 'Sniper' } } });
    if(sniper) {
        await prisma.botProduct.update({ where: { id: sniper.id }, data: sniperData });
        console.log('✅ Sniper actualizado.');
    } else {
        await prisma.botProduct.create({ data: sniperData });
        console.log('✨ Sniper creado.');
    }

    // Actualizar Oro
    const oro = await prisma.botProduct.findFirst({ where: { name: { contains: 'Oro' } } });
    if(oro) {
        await prisma.botProduct.update({ where: { id: oro.id }, data: oroData });
        console.log('✅ Oro actualizado.');
    } else {
        await prisma.botProduct.create({ data: oroData });
        console.log('✨ Oro creado.');
    }

    console.log('--- Sincronización Completada ---');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
