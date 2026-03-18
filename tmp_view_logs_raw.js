
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    const logs = await prisma.$queryRaw`SELECT * FROM RequestLog ORDER BY createdAt DESC LIMIT 20`
    console.log("Logs count:", logs.length)
    console.log(JSON.stringify(logs, null, 2))
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
