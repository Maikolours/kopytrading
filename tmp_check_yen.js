const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const p = await prisma.purchase.findUnique({
    where: { id: "cmmv3xvbo000svhmcmg8kmzhy" },
    include: { botProduct: true }
  });

  if (p) {
    console.log(`${p.botProduct.name} | LAST_SYNC: ${p.lastSync}`);
  } else {
    console.log("YEN NOT FOUND");
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
