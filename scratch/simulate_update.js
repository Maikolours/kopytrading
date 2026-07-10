const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Simulando una nueva actualización en base de datos...");
  
  // Actualizar Demo Gold a 11.40
  await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: { version: "11.40" }
  });
  console.log("Demo Gold set to 11.40");

  // Actualizar Real Gold a 11.40
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: { version: "11.40" }
  });
  console.log("Real Gold set to 11.40");

  // Actualizar Cent a 11.40
  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: { version: "11.40" }
  });
  console.log("Cent set to 11.40");

  console.log("✅ Simulación completada. Ahora las versiones en base de datos son 11.40.");
}

main().catch(console.error).finally(() => prisma.$disconnect());
