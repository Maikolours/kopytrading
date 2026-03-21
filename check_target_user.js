const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.findUnique({
    where: { id: 'cmmb2z74y000mvhhoa8qm2o0v' },
    select: { email: true, name: true }
  });
  console.log("TARGET USER:", user);
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
