const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Desconectando el bot GOLD DEMO en la base de datos...");

  const demoBotId = "cmn9hf8yc0000vhbcq9hbxk0j";
  const updatedBot = await prisma.botProduct.update({
    where: { id: demoBotId },
    data: {
      status: "UPCOMING"
    }
  });

  console.log(`✅ ¡Bot Demo desconectado con éxito!`);
  console.log(`Nombre: ${updatedBot.name}`);
  console.log(`Nuevo Estado: ${updatedBot.status}`);
}

main()
  .catch(e => {
    console.error("Error desconectando el bot demo:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
