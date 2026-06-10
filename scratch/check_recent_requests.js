const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== ÚLTIMOS LOGS DE PETICIÓN EN GENERAL ===");
  
  const logs = await prisma.requestLog.findMany({
    orderBy: {
      createdAt: 'desc'
    },
    take: 30
  });

  logs.forEach(log => {
    console.log(`- Creado: ${log.createdAt}`);
    console.log(`  Path: ${log.path}`);
    console.log(`  Method: ${log.method}`);
    console.log(`  Error/Msg: ${log.error}`);
    console.log(`  Body preview: ${log.body?.substring(0, 300)}`);
    console.log("---------------------------------------");
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
