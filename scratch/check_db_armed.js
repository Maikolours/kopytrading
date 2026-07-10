const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const settings = await prisma.botSettings.findMany();
  console.log("=== Bot Settings ===");
  for (const s of settings) {
    console.log(`ID: ${s.id}, PurchaseId: ${s.purchaseId}, Account: ${s.account}`);
    try {
      const parsed = JSON.parse(s.settings);
      console.log(`  Armed: ${parsed.armed}, ForceArmed: ${parsed.forceArmed}, Status: ${parsed.status}`);
    } catch(e) {
      console.log(`  Raw: ${s.settings}`);
    }
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
