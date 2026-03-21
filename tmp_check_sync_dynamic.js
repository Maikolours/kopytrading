const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' }
  });

  console.log("=== RECENT USERS ===");
  users.forEach(u => console.log(`${u.id} | ${u.email} | ${u.name}`));

  if (users.length > 0) {
    const targetId = users[0].id; // El más reciente
    const purchases = await prisma.purchase.findMany({
      where: { userId: targetId },
      include: { botProduct: true }
    });

    console.log(`\n=== PURCHASES FOR ${users[0].email} (${targetId}) ===`);
    purchases.forEach(p => {
      console.log(`Bot: ${p.botProduct.name}`);
      console.log(`ID: ${p.id}`);
      console.log(`Sync: ${p.lastSync}`);
      console.log("---");
    });
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
