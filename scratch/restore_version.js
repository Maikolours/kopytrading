const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Restaurando versiones oficiales a 11.30 en base de datos...");
  
  // Demo Gold a 11.30
  await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: { version: "11.30" }
  });
  console.log("Demo Gold set back to 11.30");

  // Real Gold a 11.30
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: { version: "11.30" }
  });
  console.log("Real Gold set back to 11.30");

  // Cent a 11.30
  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: { version: "11.30" }
  });
  console.log("Cent set back to 11.30");

  console.log("✅ Restauración completada. Ahora las versiones son 11.30.");
}

main().catch(console.error).finally(() => prisma.$disconnect());
