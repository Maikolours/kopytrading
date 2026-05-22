const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- UPDATING BOT PRODUCTS IN DATABASE ---');
    
    // 1. ELITE GOLD MAIKO SNIPER -> MAIKO SNIPER PRO GOLD (DEMO)
    const bot1 = await prisma.botProduct.update({
        where: { id: 'cmn9hf8yc0000vhbcq9hbxk0j' },
        data: {
            name: 'MAIKO SNIPER PRO GOLD (DEMO) 🏆',
            instrument: 'XAUUSD'
        }
    });
    console.log(`Updated bot 1: ${bot1.name} | ${bot1.instrument}`);

    // 2. MAIKO SNIPER PRO -> MAIKO SNIPER PRO GOLD
    const bot2 = await prisma.botProduct.update({
        where: { id: 'cmn9hf9440001vhbclffx9no6' },
        data: {
            name: 'MAIKO SNIPER PRO GOLD 🏆',
            instrument: 'XAUUSD'
        }
    });
    console.log(`Updated bot 2: ${bot2.name} | ${bot2.instrument}`);

    // 3. MAIKO SNIPER PRO CENT -> MAIKO SNIPER PRO GOLD CENT
    const bot3 = await prisma.botProduct.update({
        where: { id: 'cmn9hf9800002vhbc5rky6dx8' },
        data: {
            name: 'MAIKO SNIPER PRO GOLD CENT ⚡',
            instrument: 'XAUUSD'
        }
    });
    console.log(`Updated bot 3: ${bot3.name} | ${bot3.instrument}`);

    // 4. MAIKO BTC WEEKEND -> MAIKO SNIPER PRO BTC
    const bot4 = await prisma.botProduct.update({
        where: { id: 'cmn9hf9bm0003vhbckaamkqal' },
        data: {
            name: 'MAIKO SNIPER PRO BTC ₿',
            instrument: 'BTCUSD'
        }
    });
    console.log(`Updated bot 4: ${bot4.name} | ${bot4.instrument}`);

    console.log('\nAll bot names and instruments updated successfully.');
}

main().catch(console.error).finally(() => prisma.$disconnect());
