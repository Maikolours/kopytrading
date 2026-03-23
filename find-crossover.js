const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const euroPurchaseId = 'cmmv3xv7g000qvhmclun1c7zi';
  
  console.log('--- BUSCANDO CRUCE DE DATOS (DATA CROSSOVER) ---');
  
  // Buscar logs del bot de EURO que contengan "BTCUSD"
  const logs = await prisma.requestLog.findMany({
    where: { 
        body: { 
            contains: euroPurchaseId,
            // contains: 'BTCUSD' // Prisma no soporta múltiples contains así de fácil en string, usaremos filter
        }
    },
    take: 20,
    orderBy: { createdAt: 'desc' }
  });

  const crossedLogs = logs.filter(l => l.body.includes('BTCUSD'));

  if (crossedLogs.length === 0) {
      console.log('No se encontraron logs del bot de EURO que contengan BTCUSD.');
  } else {
      console.log(`¡ENCONTRADO! Hay ${crossedLogs.length} peticiones donde el ID de EURO se está usando para enviar datos de BTC.`);
      crossedLogs.forEach((l, i) => {
          console.log(`\n--- LOG CRUZADO #${i+1} (${l.createdAt}) ---`);
          // Mostrar un trozo del body
          console.log(l.body.substring(0, 500));
      });
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
