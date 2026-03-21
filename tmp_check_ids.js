const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const ids = ["cmmv3xvgp000uvhmcraiay5l4", "cmmv3xvbo000svhmcng8knzhy"];
  
  for (const id of ids) {
    const p = await prisma.purchase.findUnique({
      where: { id: id },
      include: { botProduct: true }
    });
    
    if (p) {
      console.log(`=== ID: ${id} ===`);
      console.log(`Bot: ${p.botProduct.name}`);
      console.log(`Sync: ${p.lastSync}`);
      console.log(`Status: ${p.status}`);
      console.log("---");
    } else {
      console.log(`ID ${id} NOT FOUND`);
    }
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
