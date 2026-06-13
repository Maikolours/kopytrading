const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const setting = await prisma.botSettings.findUnique({
    where: {
      purchaseId_account: {
        purchaseId: 'cmn9hfal4000fvhbcr34kst5x',
        account: '27625151'
      }
    }
  });

  if (!setting) {
    console.log("No setting found for account 27625151");
    return;
  }

  console.log("=== DB Settings for account 27625151 ===");
  const data = JSON.parse(setting.settings);
  console.log(JSON.stringify(data, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
