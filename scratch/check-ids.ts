import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()
async function main() {
  const products = await prisma.botProduct.findMany({
      select: { id: true, name: true, instrument: true }
  })
  console.log('--- PRODUCTS IN DB ---')
  products.forEach(p => {
      console.log(`Name: ${p.name} | ID: ${p.id} | Instrument: ${p.instrument}`)
  })
}
main()
