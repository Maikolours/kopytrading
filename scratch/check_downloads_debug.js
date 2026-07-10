const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchases = await prisma.purchase.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' },
    include: { botProduct: true }
  });

  console.log("=== RECENT PURCHASES ===");
  purchases.forEach(p => {
    console.log(`Purchase ID: ${p.id}`);
    console.log(`User ID: ${p.userId}`);
    console.log(`Bot Product: ${p.botProduct.name}`);
    console.log(`ex5FilePath in DB: ${p.botProduct.ex5FilePath}`);
    console.log(`pdfFilePath in DB: ${p.botProduct.pdfFilePath}`);
    console.log("------------------------");
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
