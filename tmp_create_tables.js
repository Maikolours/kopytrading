
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    console.log("Creating LivePosition table...")
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS LivePosition (
        id VARCHAR(191) PRIMARY KEY,
        purchaseId VARCHAR(191) NOT NULL,
        ticket VARCHAR(191) NOT NULL,
        type VARCHAR(191) NOT NULL,
        symbol VARCHAR(191) NOT NULL,
        lots DOUBLE NOT NULL,
        openPrice DOUBLE NOT NULL,
        tp DOUBLE NOT NULL,
        sl DOUBLE NOT NULL,
        profit DOUBLE NOT NULL,
        account VARCHAR(191) NOT NULL DEFAULT 'unknown',
        updatedAt DATETIME(3) NOT NULL,
        FOREIGN KEY (purchaseId) REFERENCES Purchase(id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    `
    console.log("Creating TradeHistory table...")
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS TradeHistory (
        id VARCHAR(191) PRIMARY KEY,
        purchaseId VARCHAR(191) NOT NULL,
        ticket VARCHAR(191) NOT NULL,
        type VARCHAR(191) NOT NULL,
        symbol VARCHAR(191) NOT NULL,
        lots DOUBLE NOT NULL,
        openPrice DOUBLE NOT NULL,
        closePrice DOUBLE NOT NULL,
        profit DOUBLE NOT NULL,
        account VARCHAR(191) NOT NULL DEFAULT 'unknown',
        closedAt DATETIME(3) NOT NULL,
        FOREIGN KEY (purchaseId) REFERENCES Purchase(id) ON DELETE CASCADE ON UPDATE CASCADE
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
