const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const purchases = await prisma.purchase.findMany({
    include: { 
        botProduct: true,
        user: true
    }
  });

  console.log('--- ALL PURCHASES STATUS ---');
  purchases.forEach(p => {
    console.log(`Bot: ${p.botProduct.name}`);
    console.log(`User: ${p.user.email}`);
    console.log(`ID: ${p.id}`);
    console.log(`LastSync: ${p.lastSync}`);
    console.log(`Telemetry (from DB): Balance=${p.balance}, Equity=${p.equity}, Status=${p.status}, PNLTod=${p.pnlToday}`);
    console.log('---------------------------');
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
