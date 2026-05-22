const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.botProduct.findMany({
  select: { id: true, name: true, status: true, price: true, isActive: true, instrument: true, strategyType: true }
}).then(r => {
  console.log(JSON.stringify(r, null, 2));
}).catch(e => console.error(e)).finally(() => p.$disconnect());
