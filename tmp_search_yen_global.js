const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchases = await prisma.purchase.findMany({
    where: {
      botProduct: {
        name: { contains: "Yen" }
      }
    },
    include: { 
      botProduct: true,
      user: true
    }
  });

  console.log(`=== YEN PURCHASES FOUND: ${purchases.length} ===`);
  purchases.forEach(p => {
    console.log(`ID: ${p.id} | User: ${p.user.email} | Bot: ${p.botProduct.name} | Sync: ${p.lastSync}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
