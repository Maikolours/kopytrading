
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    const columns = await prisma.$queryRaw`SHOW COLUMNS FROM Purchase`
    console.log(JSON.stringify(columns, null, 2))
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
