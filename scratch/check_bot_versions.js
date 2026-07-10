const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const bots = await prisma.botProduct.findMany();
  console.log("BOTS IN DATABASE:");
  bots.forEach(b => {
    console.log(`- ID: ${b.id}`);
    console.log(`  Name: ${b.name}`);
    console.log(`  Version: ${b.version}`);
    console.log(`  EX5 Path: ${b.ex5FilePath}`);
    console.log(`  PDF Path: ${b.pdfFilePath}`);
    console.log(`  -----------------------------`);
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
