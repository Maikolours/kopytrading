const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchaseId = 'cmn9hfal4000fvhbcr34kst5x';
  const account = '27625151';

  const setting = await prisma.botSettings.findUnique({
    where: {
      purchaseId_account: {
        purchaseId,
        account
      }
    }
  });

  if (!setting) {
    console.log("No setting found for account 27625151");
    return;
  }

  const data = JSON.parse(setting.settings);
  data.forceArmed = true; // Use forceArmed to override the incoming telemetry payload!

  const updated = await prisma.botSettings.update({
    where: {
      id: setting.id
    },
    data: {
      settings: JSON.stringify(data)
    }
  });

  console.log("Successfully set forceArmed = true in DB for account 27625151!");
}

main().catch(console.error).finally(() => prisma.$disconnect());
