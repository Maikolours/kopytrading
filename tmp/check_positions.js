
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const positions = await prisma.livePosition.findMany({
    take: 5
  });
  console.log("Positions in DB:", positions.length);
  if(positions.length > 0) console.log(JSON.stringify(positions[0], null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
