const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== ALL BOT SETTINGS RECORDS ===");
  const settings = await prisma.botSettings.findMany({
    include: {
      purchase: {
        include: {
          botProduct: true,
          user: true
        }
      }
    }
  });

  settings.forEach(s => {
    let parsedSettings = {};
    try {
      parsedSettings = typeof s.settings === 'string' ? JSON.parse(s.settings) : s.settings;
    } catch(e) {}
    console.log(`Purchase ID: ${s.purchaseId} (${s.purchase.botProduct.name})`);
    console.log(`User: ${s.purchase.user.email}`);
    console.log(`Account: ${s.account}`);
    console.log(`Updated: ${s.updatedAt}`);
    console.log(`Balance in settings: ${parsedSettings.balance}, Equity: ${parsedSettings.equity}, Status: ${parsedSettings.status}`);
    console.log("---------------------------------------");
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
