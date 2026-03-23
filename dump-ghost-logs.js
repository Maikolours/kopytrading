const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const euroPurchaseId = 'cmmv3xv7g000qvhmclun1c7zi';
  
  console.log('--- BUSCANDO PRUEBAS FÍSICAS DE LA CONEXIÓN ---');
  
  // Buscar los logs más recientes con el cuerpo completo
  const logs = await prisma.requestLog.findMany({
    where: { 
        body: { contains: euroPurchaseId },
        error: null 
    },
    take: 3,
    orderBy: { createdAt: 'desc' }
  });

  if (logs.length === 0) {
      console.log('No hay logs recientes con ese ID.');
      return;
  }

  logs.forEach((l, i) => {
      console.log(`\n--- LOG #${i+1} (${l.createdAt}) ---`);
      try {
          const body = JSON.parse(l.body);
          console.log(JSON.stringify(body, null, 2));
      } catch(e) {
          console.log('Cuerpo (Raw):', l.body);
      }
  });

  // Mirar si hay posiciones actuales
  const positions = await prisma.livePosition.findMany({
      where: { purchaseId: euroPurchaseId }
  });
  console.log('\n--- POSICIONES ACTUALES EN EL BOT DE EURO ---');
  if (positions.length === 0) console.log('Sin operaciones abiertas actualmente.');
  positions.forEach(p => {
      console.log(`Symbol: ${p.symbol}, Tipo: ${p.type}, Lotes: ${p.lots}, Ticket: ${p.ticket}`);
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
