const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.botProduct.findMany().then(r => console.log(JSON.stringify(r.map(b=>({id:b.id, name:b.name, status:b.status, isActive:b.isActive})), null, 2))).finally(() => p.$disconnect());
