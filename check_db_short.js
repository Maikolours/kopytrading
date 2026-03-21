const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: { id: true, email: true, name: true }
  });
  console.log("USERS:", users);
  
  const purchases = await prisma.purchase.findMany({
    include: { botProduct: { select: { name: true } } }
  });
  console.log("PURCHASES:", purchases.map(p => ({ id: p.id, userId: p.userId, bot: p.botProduct.name, status: p.status })));
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
