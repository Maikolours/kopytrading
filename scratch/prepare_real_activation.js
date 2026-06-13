const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchaseId = 'cmn9hfapj000hvhbca86faz0c'; // The REAL gold license key!
  const account = '27625151';

  // Get the settings data from the demo license for this account to copy it over
  const demoSetting = await prisma.botSettings.findUnique({
    where: {
      purchaseId_account: {
        purchaseId: 'cmn9hfal4000fvhbcr34kst5x',
        account: account
      }
    }
  });

  let defaultSettingsStr = "";
  if (demoSetting) {
    const data = JSON.parse(demoSetting.settings);
    data.armed = true;
    data.status = 'ONLINE';
    defaultSettingsStr = JSON.stringify(data);
  } else {
    defaultSettingsStr = JSON.stringify({
      net_cycle: 5,
      hedge_trigger: 3,
      lote_manual: 0.01,
      lote_rescate: 0.01,
      max_dd: 20,
      trailling_stop: 1.2,
      limit_dist: 500,
      timeframe: "M15",
      lkb: 4,
      colchon: 1000,
      armed: true,
      status: "ONLINE"
    });
  }

  const upserted = await prisma.botSettings.upsert({
    where: {
      purchaseId_account: {
        purchaseId,
        account
      }
    },
    update: {
      settings: defaultSettingsStr
    },
    create: {
      purchaseId,
      account,
      settings: defaultSettingsStr
    }
  });

  console.log("Successfully prepared and activated Real License settings in DB!");
}

main().catch(console.error).finally(() => prisma.$disconnect());
