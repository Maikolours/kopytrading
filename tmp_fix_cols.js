
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    console.log("Adding lastSync...")
    await prisma.$executeRaw`ALTER TABLE Purchase ADD COLUMN lastSync DATETIME(3) NULL`
    console.log("Adding updatedAt...")
    await prisma.$executeRaw`ALTER TABLE Purchase ADD COLUMN updatedAt DATETIME(3) NULL`
    console.log("Success!")
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
