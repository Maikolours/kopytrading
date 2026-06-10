const { PrismaClient } = require('@prisma/client');

const dbUrl = "mysql://u471920480_kopytrading:Dogi007759@193.203.168.60:3306/u471920480_kopytrading";
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: dbUrl
    }
  }
});

async function main() {
  console.log('--- ALL PURCHASES STATUS (VERCEL DB) ---');
  const purchases = await prisma.purchase.findMany({
    include: { 
        botProduct: true,
        user: true
    }
  });

  purchases.forEach(p => {
    console.log(`Bot: ${p.botProduct.name}`);
    console.log(`User: ${p.user.email}`);
    console.log(`ID: ${p.id}`);
    console.log(`LastSync: ${p.lastSync}`);
    console.log(`Telemetry (from DB): Balance=${p.balance}, Equity=${p.equity}, Status=${p.status}`);
    console.log('---------------------------');
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
