
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  const purchaseId = 'cmmv3xvgp000uvhmcraiay5l4';
  
  try {
    const purchase = await prisma.purchase.findUnique({
      where: { id: purchaseId },
      include: {
         activePositions: true
      }
    });
    
    console.log("Purchase Sync Info:", {
        id: purchase?.id,
        lastSync: purchase?.lastSync,
        positionsCount: purchase?.activePositions.length
    });

    const recentLogs = await prisma.syncLog.findMany({
      where: { purchaseId },
      orderBy: { createdAt: 'desc' },
      take: 5
    });
    
    console.log("Recent Sync Logs:", JSON.stringify(recentLogs, null, 2));

  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
