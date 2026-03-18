
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    console.log("Creating RequestLog table...")
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS RequestLog (
        id VARCHAR(191) PRIMARY KEY,
        path VARCHAR(191) NOT NULL,
        method VARCHAR(191) NOT NULL,
        body TEXT,
        error TEXT,
        createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      )
    `
    console.log("Success!")
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
