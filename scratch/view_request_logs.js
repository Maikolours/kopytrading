const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== RECIENTES LOGS DE PETICIONES DE SAKURA ===");
  const logs = await prisma.requestLog.findMany({
    where: {
      OR: [
        { body: { contains: '27625151' } },
        { body: { contains: '11649344' } },
        { body: { contains: '1028690' } },
        { error: { contains: 'SAKURA' } }
      ]
    },
    orderBy: { createdAt: 'desc' },
    take: 15
  });

  logs.forEach(l => {
    console.log(`\nLog ID: ${l.id} | Creado: ${new Date(l.createdAt).toLocaleString('es-ES')}`);
    console.log(`  Path: ${l.path} | Method: ${l.method}`);
    console.log(`  Error/Info: ${l.error}`);
    console.log(`  Body preview: ${l.body ? l.body.substring(0, 500) : 'null'}`);
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
