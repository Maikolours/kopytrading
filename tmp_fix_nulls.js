
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    console.log("Updating NULL updatedAt values to NOW()...")
    await prisma.$executeRaw`UPDATE Purchase SET updatedAt = NOW() WHERE updatedAt IS NULL`
    
    console.log("Setting updatedAt to NOT NULL...")
    // Note: Syntax might vary slightly depending on MySQL version, but this is standard
    await prisma.$executeRaw`ALTER TABLE Purchase MODIFY updatedAt DATETIME(3) NOT NULL`
    
    console.log("Success!")
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
