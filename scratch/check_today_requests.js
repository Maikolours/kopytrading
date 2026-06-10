const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== LOGS DE PETICIÓN DEL DÍA DE HOY (9 de Junio de 2026) ===");
  
  const today = new Date();
  today.setHours(0,0,0,0);

  const logs = await prisma.requestLog.findMany({
    where: {
      createdAt: {
        gte: today
      }
    },
    orderBy: {
      createdAt: 'desc'
    },
    take: 100
  });

  console.log(`Encontrados ${logs.length} logs hoy.`);

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
