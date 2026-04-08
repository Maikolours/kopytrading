import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const p = await prisma.purchase.findUnique({
    where: { id: 'CMN9HFAXG000LVHBCQIDLVVFM' },
    include: { botProduct: true }
  });
  console.log(JSON.stringify(p, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
