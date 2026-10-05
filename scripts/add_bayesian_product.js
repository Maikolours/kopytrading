const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- Añadiendo Bot MAIKO BAYESIAN STRATEGY PRO a la Base de Datos ---');

  const bayesianData = {
    productKey: 'BAYESIAN-PRO',
    name: 'MAIKO BAYESIAN STRATEGY PRO 🧠',
    description: 'Algoritmo de Inferencia Bayesiana + RSI + Capas Adaptativas. Entrada quirúrgica de alta probabilidad con cálculo estadístico en tiempo real para XAUUSD y Forex mayores.',
    instrument: 'XAUUSD / Forex',
    strategyType: 'Inferencia Bayesiana + RSI',
    riskLevel: 'MEDIUM',
    price: 199.00,
    originalPrice: 299.00,
    version: 'v1.1',
    isActive: true,
    timeframes: 'M5, M15',
    minCapital: 300.0
  };

  const existing = await prisma.botProduct.findUnique({
    where: { productKey: 'BAYESIAN-PRO' }
  });

  let product = existing;
  if (existing) {
    product = await prisma.botProduct.update({
      where: { id: existing.id },
      data: bayesianData
    });
    console.log('✅ Bot BAYESIAN-PRO actualizado en la Base de Datos.');
  } else {
    product = await prisma.botProduct.create({ data: bayesianData });
    console.log(`✨ Bot BAYESIAN-PRO creado con ID: ${product.id}`);
  }

  // Asignar también una compra a todos los usuarios para que aparezca directamente en sus paneles
  const users = await prisma.user.findMany();

  for (const user of users) {
    const existingPurchase = await prisma.purchase.findFirst({
      where: {
        userId: user.id,
        botProductId: product.id
      }
    });

    if (!existingPurchase) {
      const purchase = await prisma.purchase.create({
        data: {
          userId: user.id,
          botProductId: product.id,
          productKey: 'BAYESIAN-PRO',
          amount: 199.00,
          status: 'COMPLETED'
        }
      });

      // Crear sesión de licencia vinculada a la cuenta 1028690
      await prisma.licenseSession.create({
        data: {
          purchaseId: purchase.id,
          account: '1028690',
          isActive: true
        }
      });

      console.log(`✅ Licencia BAYESIAN asignada con éxito al usuario ${user.email}`);
    }
  }

  console.log('--- Proceso Completado ---');
}

main()
  .catch(e => {
    console.error('Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
