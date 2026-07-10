const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const logs = await prisma.requestLog.findMany({
    where: {
      body: { contains: "27625151" }
    },
    orderBy: { createdAt: "desc" },
    take: 5
  });
  console.log("=== Logs for 27625151 ===");
  for (const l of logs) {
    console.log(`Time: ${l.createdAt}`);
    console.log(`Path: ${l.path}`);
    console.log(`Body: ${l.body}`);
    console.log(`Error/Info: ${l.error}`);
    console.log("------------------------");
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
