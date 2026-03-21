const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = "cmmb2z6ml000dvhhoj1s9zmnf"; // viajaconsakura
  const purchases = await prisma.purchase.findMany({
    where: { userId: userId },
    include: { botProduct: true }
  });

  console.log(JSON.stringify(purchases, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
