
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  const purchaseId = 'cmmv3xvgp000uvhmcraiay5l4';
  
  try {
    const updated = await prisma.purchase.update({
      where: { id: purchaseId },
      data: { lastSync: new Date() }
    });
    
    console.log("Updated Purchase:", {
        id: updated.id,
        lastSync: updated.lastSync
    });

  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
