const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: { instrument: "EURUSD" }
  });

  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: { instrument: "USDJPY" }
  });

  console.log("Instruments updated successfully");
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
