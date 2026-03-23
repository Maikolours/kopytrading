const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userEmail = 'viajaconsakura@gmail.com';
  const user = await prisma.user.findUnique({
    where: { email: userEmail },
    include: { 
        purchases: {
            include: { botProduct: true }
        }
    }
  });

  if (!user) {
    console.log('Usuario no encontrado');
    return;
  }

  console.log(`--- PRODUCTOS DE ${userEmail} ---`);
  user.purchases.forEach(p => {
    console.log(`- ${p.botProduct.name} (Status: ${p.status}, Compra ID: ${p.id})`);
  });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
