import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()
async function main() {
  const products = await prisma.botProduct.findMany({
      select: { id: true, name: true, instrument: true, isActive: true, status: true }
  })
  console.log('--- PRODUCTS STATUS ---')
  products.forEach(p => {
      console.log(`ID: ${p.id} | Name: ${p.name} | Active: ${p.isActive} | Status: ${p.status}`)
  })
}
main()
