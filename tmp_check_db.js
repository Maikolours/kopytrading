const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Final check of ALL BotProducts...');
  const products = await prisma.botProduct.findMany();
  
  for (const p of products) {
    const name = p.name.toUpperCase();
    let updated = false;
    let data = {};

    if (name.includes('UNIVERSAL') || name.includes('EVOLUTION')) {
       if (name.includes('BTC')) {
          data = { ex5FilePath: '/uploads/KOPYTRADE_BTCUSD_Evolution_Universal_v7_50.mq5', version: '7.50' };
          updated = true;
       } else if (name.includes('ORO') || name.includes('GOLD') || name.includes('XAUUSD') || name.includes('AMETRALLADORA')) {
          data = { ex5FilePath: '/uploads/KOPYTRADE_XAUUSD_Evolution_Universal_v5_95.mq5', version: '5.95' };
          updated = true;
       }
    }

    if (updated) {
      await prisma.botProduct.update({ where: { id: p.id }, data });
      console.log(`UPDATED: ${p.name} -> ${data.version}`);
    } else {
      console.log(`SKIPPED: ${p.name}`);
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
