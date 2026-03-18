
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    const purchases = await prisma.purchase.findMany({
      select: {
        id: true,
        lastSync: true,
        updatedAt: true
      }
    })
    console.log(JSON.stringify(purchases, null, 2))
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
