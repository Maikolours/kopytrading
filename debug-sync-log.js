const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== COMPRAS ACTIVAS CON TELEMETRÍA (ÚLTIMO SYNC ORDENADO POR FECHA) ===");
  const purchases = await prisma.purchase.findMany({
    where: {
      lastSync: { not: null }
    },
    orderBy: {
      lastSync: 'desc'
    },
    include: {
      botProduct: true,
      user: {
        select: { email: true }
      }
    }
  });

  purchases.forEach(p => {
    console.log(`- ID Licencia: ${p.id}`);
    console.log(`  Usuario: ${p.user?.email}`);
    console.log(`  Bot: ${p.botProduct?.name}`);
    console.log(`  Cuenta MT5 detectada: ${p.mt5Account}`);
    console.log(`  Balance actual en DB: $${p.balance}`);
    console.log(`  Equidad actual en DB: $${p.equity}`);
    console.log(`  Último Sync: ${p.lastSync}`);
    console.log(`  Status actual: ${p.lastStatus}`);
    console.log("---------------------------------------");
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
