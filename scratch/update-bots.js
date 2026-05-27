const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Fetching bots...');
    const bots = await prisma.botProduct.findMany();
    
    for (const bot of bots) {
        let newName = bot.name;
        let newStatus = 'UPCOMING'; // default for all non-demo

        // Logic based on instrument or old name
        if (bot.id === 'cmn9hf8yc0000vhbcq9hbxk0j' || bot.name.includes('DEMO')) {
            newName = 'MAIKO PRO GOLD DEMO';
            newStatus = 'ACTIVE';
        } else if (bot.id === 'cmn9hf9440001vhbclffx9no6' || (bot.instrument === 'XAUUSD' && !bot.name.includes('CENT') && !bot.name.includes('DEMO'))) {
            newName = 'MAIKO PRO GOLD';
        } else if (bot.name.includes('CENT')) {
            newName = 'MAIKO PRO CENT';
        } else if (bot.instrument === 'BTCUSD') {
            newName = 'MAIKO PRO BTC';
        } else if (bot.instrument === 'EURUSD') {
            newName = 'MAIKO EURO PRECISION FLOW';
        } else if (bot.instrument === 'USDJPY') {
            newName = 'MAIKO YEN NINJA GHOST';
        } else {
            newName = 'MAIKO ' + bot.name;
        }

        console.log(`Updating ${bot.id} (${bot.name}) -> ${newName} [${newStatus}]`);
        await prisma.botProduct.update({
            where: { id: bot.id },
            data: { 
                name: newName,
                status: newStatus
            }
        });
    }

    // Insert EURUSD and USDJPY if they don't exist
    const hasEur = bots.some(b => b.instrument === 'EURUSD');
    if (!hasEur) {
        await prisma.botProduct.create({
            data: {
                productKey: 'MAIKO_EUR',
                name: 'MAIKO EURO PRECISION FLOW',
                description: 'Algoritmo para el par más líquido del mundo. Operativa en H1 para flujos de precisión.',
                instrument: 'EURUSD',
                strategyType: 'Precision Flow',
                riskLevel: 'Low',
                price: 199.00,
                version: '1.0.0',
                status: 'UPCOMING',
                isActive: true
            }
        });
        console.log('Created MAIKO EURO PRECISION FLOW');
    }

    const hasJpy = bots.some(b => b.instrument === 'USDJPY');
    if (!hasJpy) {
        await prisma.botProduct.create({
            data: {
                productKey: 'MAIKO_JPY',
                name: 'MAIKO YEN NINJA GHOST',
                description: 'Especializado en la sesión asiática para capturar rebotes y rangos dinámicos en M30.',
                instrument: 'USDJPY',
                strategyType: 'Ninja Ghost',
                riskLevel: 'Medium',
                price: 199.00,
                version: '1.0.0',
                status: 'UPCOMING',
                isActive: true
            }
        });
        console.log('Created MAIKO YEN NINJA GHOST');
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
