const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const settings = await prisma.botSettings.findMany({
    where: {
      purchaseId: { in: ['cmn9hfal4000fvhbcr34kst5x', 'cmn9hfapj000hvhbca86faz0c', 'cmn9hfatl000jvhbci6l3ephi', 'cmn9hfaxg000lvhbcqidlvvfm'] }
    }
  });

  settings.forEach(s => {
    console.log(`\nSetting ID: ${s.id}`);
    console.log(`  Purchase ID: ${s.purchaseId}`);
    console.log(`  Account: ${s.account}`);
    try {
      const parsed = JSON.parse(s.settings);
      console.log(`  Balance: ${parsed.balance}`);
      console.log(`  Equity: ${parsed.equity}`);
      console.log(`  PnL Today: ${parsed.pnl_today}`);
      console.log(`  Version: ${parsed.version}`);
    } catch (e) {
      console.log(`  Error parsing JSON: ${s.settings.substring(0, 100)}`);
    }
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
