const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const bots = await prisma.botProduct.findMany();
  for (const bot of bots) {
    if (bot.name.includes("V5.54")) {
      const newName = bot.name.replace(" (V5.54)", " (UNIVERSAL)");
      await prisma.botProduct.update({
        where: { id: bot.id },
        data: { name: newName }
      });
      console.log(`Updated ${bot.name} to ${newName}`);
    } else if (bot.name.includes("VOLUMEN")) {
       const newName = bot.name.replace(" (V1.2)", " (UNIVERSAL)");
       await prisma.botProduct.update({
         where: { id: bot.id },
         data: { name: newName }
       });
       console.log(`Updated ${bot.name} to ${newName}`);
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
