const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== COMPRAS / LICENCIAS REGISTRADAS ===");
  const purchases = await prisma.purchase.findMany({
    include: {
      botProduct: true,
      user: {
        select: {
          email: true
        }
      }
    }
  });

  purchases.forEach(p => {
    console.log(`- ID: ${p.id}`);
    console.log(`  Usuario: ${p.user?.email}`);
    console.log(`  Bot: ${p.botProduct?.name}`);
    console.log(`  Cuenta MT5: ${p.mt5Account}`);
    console.log(`  Balance: $${p.balance}`);
    console.log(`  Equidad: $${p.equity}`);
    console.log(`  PNL Hoy: $${p.pnlToday}`);
    console.log(`  Último Sync: ${p.lastSync}`);
    console.log(`  Status: ${p.lastStatus}`);
    console.log("---------------------------------------");
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
