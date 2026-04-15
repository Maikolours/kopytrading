import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()
async function main() {
  const products = await prisma.botProduct.findMany()
  console.log(JSON.stringify(products, null, 2))
}
main()
