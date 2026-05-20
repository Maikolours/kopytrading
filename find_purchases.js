const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  // Buscar todos los usuarios con 'raquel' o el ID conocido de sakura
  const users = await prisma.user.findMany({ 
    where: { 
      OR: [
        { email: { contains: 'raquel' } },
        { email: { contains: 'sakura' } },
        { id: 'cmmb2z6ml000dvhhoj1s9zmnf' }
      ]
    } 
  });
  console.log('USERS:', JSON.stringify(users.map(u => ({ id: u.id, email: u.email, name: u.name })), null, 2));
  
  for (const user of users) {
    const purchases = await prisma.purchase.findMany({ 
      where: { userId: user.id },
      include: { botProduct: { select: { name: true, instrument: true, productKey: true } } }
    });
    console.log(`\nPURCHASES for ${user.email}:`);
    purchases.forEach(p => {
      console.log(`  ID: ${p.id} | Bot: ${p.botProduct.name} | Instrument: ${p.botProduct.instrument} | Status: ${p.status}`);
    });
  }
}
main().catch(console.error).finally(() => prisma.$disconnect());
