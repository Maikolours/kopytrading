import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()
async function main() {
  const products = await prisma.botProduct.findMany({
      include: {
          _count: {
              select: { purchases: true }
          },
          purchases: {
              orderBy: { lastSync: 'desc' },
              take: 1,
              select: { lastSync: true }
          }
      }
  })
  console.log('--- PRODUCT USAGE ---')
  products.forEach(p => {
      console.log(`ID: ${p.id} | Name: ${p.name} | Purchases: ${p._count.purchases} | Last Sync: ${p.purchases[0]?.lastSync || 'Never'}`)
  })
}
main()
