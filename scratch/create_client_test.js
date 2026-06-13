const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const email = 'cliente@kopytrading.com';
  const rawPassword = 'Prueba1234!';
  const hashed = await bcrypt.hash(rawPassword, 10);
  
  console.log("Creating/updating test client user...");
  
  try {
    // 1. Create or update user
    const user = await prisma.user.upsert({
      where: { email },
      update: { password: hashed, name: 'Cliente Prueba' },
      create: { 
        email, 
        password: hashed, 
        name: 'Cliente Prueba',
        role: 'USER'
      }
    });
    
    console.log(`User created: ${user.email} (ID: ${user.id})`);
    
    // 2. Add MAIKO PRO GOLD DEMO purchase
    const demoProduct = await prisma.botProduct.findFirst({
      where: { name: 'MAIKO PRO GOLD DEMO' }
    });
    
    if (demoProduct) {
      const demoPurchase = await prisma.purchase.upsert({
        where: { id: 'test_client_purchase_demo' },
        update: { expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) },
        create: {
          id: 'test_client_purchase_demo',
          userId: user.id,
          botProductId: demoProduct.id,
          amount: 0.0,
          status: 'COMPLETED',
          productKey: 'DEMO-GOLD-TEST',
          expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        }
      });
      console.log(`Demo purchase created/updated: ${demoPurchase.id}`);
    } else {
      console.error("Demo product not found in database.");
    }
    
    // 3. Add MAIKO PRO GOLD (Real) purchase
    const realProduct = await prisma.botProduct.findFirst({
      where: { name: 'MAIKO PRO GOLD' }
    });
    
    if (realProduct) {
      const realPurchase = await prisma.purchase.upsert({
        where: { id: 'test_client_purchase_real' },
        update: { expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) },
        create: {
          id: 'test_client_purchase_real',
          userId: user.id,
          botProductId: realProduct.id,
          amount: 0.0,
          status: 'COMPLETED',
          productKey: 'REAL-GOLD-TEST',
          expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        }
      });
      console.log(`Real purchase created/updated: ${realPurchase.id}`);
    } else {
      console.error("Real product not found in database.");
    }
    
    console.log("--------------------------------------------------");
    console.log("TEST CLIENT ACCOUNT DETAILS:");
    console.log(`Email: ${email}`);
    console.log(`Password: ${rawPassword}`);
    console.log("--------------------------------------------------");
    
  } catch (error) {
    console.error("Error creating test client:", error);
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
