const { PrismaClient } = require('./node_modules/@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- STARTING EMERGENCY BRANDING DIFFERENTIATION ---');
  
  const updates = [
    { id: 'btc-ultra-usd', name: 'BTC EVOLUTION v8.3.0 TITAN SHIELD (USD)' },
    { id: 'btc-ultra-cent', name: 'BTC EVOLUTION v8.3.0 TITAN SHIELD (CENT)' },
    { id: 'cmmv3xtsb0003vhmcdkf1dml3', name: 'BTC EVOLUTION (LEGACY STORM RIDER)' },
    { id: 'cmmv3xtfx0000vhmcszbww0fb', name: 'EVOLUTION (LEGACY AMETRALLADORA)' },
    { id: 'gold-pro-universal', name: 'EVOLUTION v8.3.0 TITAN SHIELD' }
  ];

  for (const update of updates) {
    const res = await prisma.botProduct.update({
      where: { id: update.id },
      data: { name: update.name }
    });
    console.log(`Updated ID: ${update.id} -> ${res.name}`);
  }

  console.log('--- DIFFERENTIATION COMPLETE ---');
}

main().catch(console.error).finally(() => prisma.$disconnect());
