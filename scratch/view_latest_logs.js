const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== 30 ABSOLUTAMENTE ÚLTIMOS LOGS DE PETICIONES ===");
  const logs = await prisma.requestLog.findMany({
    orderBy: { createdAt: 'desc' },
    take: 30
  });

  logs.forEach(l => {
    console.log(`\nLog ID: ${l.id} | Creado: ${new Date(l.createdAt).toLocaleString('es-ES')}`);
    console.log(`  Path: ${l.path} | Method: ${l.method}`);
    console.log(`  Error/Info: ${l.error}`);
    console.log(`  Body preview: ${l.body ? l.body.substring(0, 500) : 'null'}`);
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
