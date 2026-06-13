const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Actualizando rutas de descarga de los bots en la base de datos a la versión v11.30...");

  // 1. MAIKO PRO GOLD DEMO
  await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: {
      ex5FilePath: "/uploads/bots/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.ex5",
      version: "11.30"
    }
  });
  console.log("✅ Ruta de Demo Gold actualizada en la DB.");

  // 2. MAIKO PRO GOLD (Real)
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      ex5FilePath: "/uploads/bots/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.ex5",
      version: "11.30"
    }
  });
  console.log("✅ Ruta de Real Gold actualizada en la DB.");

  // 3. MAIKO PRO CENT
  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      ex5FilePath: "/uploads/bots/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.ex5",
      version: "11.30"
    }
  });
  console.log("✅ Ruta de Cent Gold actualizada en la DB.");

  console.log("🎉 ¡Rutas y versiones de bots actualizadas con éxito en la base de datos!");
}

main()
  .catch(e => {
    console.error("Error actualizando rutas en la DB:", e);
  })
  .finally(() => prisma.$disconnect());
