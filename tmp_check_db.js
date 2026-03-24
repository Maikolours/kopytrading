const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Updating definitive BotProducts...');
  
  // Gold Universal
  await prisma.botProduct.update({
    where: { id: 'gold-pro-universal' },
    data: { 
      ex5FilePath: '/uploads/KOPYTRADE_XAUUSD_Evolution_Universal_v5_95.mq5',
      version: '5.95'
    }
  });

  // BTC Universal (updating the main Storm Rider record)
  await prisma.botProduct.update({
    where: { id: 'cmmv3xtsb0003vhmcdkf1dml3' },
    data: { 
      ex5FilePath: '/uploads/KOPYTRADE_BTCUSD_Evolution_Universal_v7_50.mq5',
      version: '7.50'
    }
  });

  console.log('Update complete.');
}

main().catch(console.error).finally(() => prisma.$disconnect());
