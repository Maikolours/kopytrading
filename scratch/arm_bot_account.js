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
  data.armed = true;
  data.status = 'ONLINE';

  const updated = await prisma.botSettings.update({
    where: {
      id: setting.id
    },
    data: {
      settings: JSON.stringify(data)
    }
  });

  console.log("Bot status successfully updated in database!");
  console.log("New settings: armed =", data.armed, ", status =", data.status);
}

main().catch(console.error).finally(() => prisma.$disconnect());
