const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const logs = await prisma.requestLog.findMany({
    where: {
      body: { contains: "27625151" }
    },
    orderBy: { createdAt: "desc" },
    take: 30
  });
  console.log("=== Recent Logs for 27625151 ===");
  for (const l of logs) {
    console.log(`[${l.createdAt.toISOString()}] Path: ${l.path}`);
    console.log(`  Body: ${l.body.substring(0, 300)}`);
    console.log(`  Error/Info: ${l.error}`);
    console.log("------------------------");
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
