const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const ids = [
    'cmn9hfal4000fvhbcr34kst5x', // GOLD DEMO
    'cmn9hfapj000hvhbca86faz0c', // GOLD
    'cmn9hfatl000jvhbci6l3ephi', // GOLD CENT
    'cmn9hfaxg000lvhbcqidlvvfm'  // BTC
  ];

  console.log('=== BOT SETTINGS ===');
  for (const id of ids) {
    const settings = await prisma.botSettings.findMany({
      where: { purchaseId: id }
    });
    console.log(`\nLicense: ${id}`);
    if (settings.length === 0) {
      console.log('  No settings found.');
    } else {
      settings.forEach(s => {
        console.log(`  Account: ${s.account}`);
        console.log(`  Updated: ${s.updatedAt}`);
        console.log(`  Settings content: ${s.settings.substring(0, 200)}...`);
      });
    }
  }

  console.log('\n=== RECENT SYNCED POSITIONS ===');
  for (const id of ids) {
    const positions = await prisma.position.findMany({
      where: { purchaseId: id }
    });
    console.log(`License: ${id} | Total positions: ${positions.length}`);
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
