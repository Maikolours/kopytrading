const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: { id: true, email: true, name: true }
  });

  console.log("=== ALL USERS ===");
  users.forEach(u => console.log(`${u.id} | ${u.email} | ${u.name}`));
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
