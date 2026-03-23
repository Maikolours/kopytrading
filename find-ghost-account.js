const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const euroBotName = 'Euro Precision Flow';
  
  // Buscar la compra de ese bot que esté activa
  const purchase = await prisma.purchase.findFirst({
      where: { 
          botProduct: { name: { contains: euroBotName } },
          lastSync: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
      },
      include: { activePositions: true }
  });

  if (!purchase) {
      console.log('No se encontraron sincronizaciones recientes para el bot Euro Precision.');
      return;
  }

  console.log(`--- GHOST BOT FOUND ---`);
  console.log(`Bot: ${purchase.botProduct?.name || euroBotName}`);
  console.log(`Purchase ID: ${purchase.id}`);
  
  // Buscar en las posiciones actuales qué cuenta figura
  const accounts = [...new Set(purchase.activePositions.map(p => p.account))];
  console.log('Cuentas activas en LivePosition:', accounts.join(', ') || 'Ninguna (solo latido)');

  // Buscar en los Logs de peticiones por si no hay posiciones abiertas
  const logs = await prisma.requestLog.findMany({
    where: { body: { contains: purchase.id } },
    take: 10,
    orderBy: { createdAt: 'desc' }
  });

  logs.forEach(l => {
      try {
          const body = JSON.parse(l.body);
          if (body.account) console.log(`Cuenta detectada en Log (${l.createdAt}): ${body.account}`);
      } catch(e) {}
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
