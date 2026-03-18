
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    const logs = await prisma.$queryRaw`SELECT * FROM RequestLog ORDER BY createdAt DESC LIMIT 10`
    console.log("Recent Logs:", JSON.stringify(logs, null, 2))
    
    const commands = await prisma.remoteCommand.findMany({
      orderBy: { createdAt: 'desc' },
      take: 5
    })
    console.log("Recent Commands:", JSON.stringify(commands, null, 2))
    
    const purchases = await prisma.purchase.findMany({
        select: { id: true, lastSync: true }
    })
    console.log("Purchases Sync Status:", JSON.stringify(purchases, null, 2))
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
