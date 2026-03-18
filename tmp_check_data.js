
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  try {
    const positions = await prisma.livePosition.findMany({
      take: 10
    })
    console.log("Positions count:", positions.length)
    console.log(JSON.stringify(positions, null, 2))
    
    const history = await prisma.tradeHistory.findMany({
      take: 10
    })
    console.log("History count:", history.length)
    
    const commands = await prisma.remoteCommand.findMany({
      take: 10
    })
    console.log("Commands count:", commands.length)
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
