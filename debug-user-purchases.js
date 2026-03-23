const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userEmail = 'raquelpanerosanz@gmail.com'; // De los logs anteriores parece ser este usuario
  const user = await prisma.user.findUnique({ where: { email: userEmail } });
  
  if (!user) {
    console.log('Usuario no encontrado');
    return;
  }

  console.log('--- USER INFO ---');
  console.log('ID:', user.id);
  console.log('Email:', user.email);

  const purchases = await prisma.purchase.findMany({
    where: { userId: user.id },
    include: { botProduct: true }
  });

  console.log('\n--- PURCHASES ---');
  purchases.forEach(p => {
    console.log(`- Bot: ${p.botProduct.name}`);
    console.log(`  ID Compro: ${p.id}`);
    console.log(`  BotProductID: ${p.botProductId}`);
    console.log(`  LastSync: ${p.lastSync}`);
    console.log(`  Status: ${p.status}`);
    console.log('------------------');
  });

  // Buscar específicamente por el bot que menciona el usuario
  const precisionFlow = await prisma.botProduct.findFirst({
      where: { name: { contains: 'Euro Precision' } }
  });
  if (precisionFlow) {
      console.log('\n--- EURO PRECISION FLOW INFO ---');
      console.log('ID:', precisionFlow.id);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
