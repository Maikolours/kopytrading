const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Actualizando rutas de descargas (archivos .ex5 y .pdf) de los bots en la base de datos...");

  // 1. Bot Gold Demo
  await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: {
      ex5FilePath: "/uploads/KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.ex5",
      pdfFilePath: "/uploads/Manual_Ametralladora.pdf"
    }
  });
  console.log("Demo Oro actualizado.");

  // 2. Bot Gold Real
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      ex5FilePath: "/uploads/KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.ex5",
      pdfFilePath: "/uploads/Manual_Ametralladora.pdf"
    }
  });
  console.log("Real Oro actualizado.");

  // 3. Bot Cent
  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      ex5FilePath: "/uploads/KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.ex5",
      pdfFilePath: "/uploads/Manual_Ametralladora.pdf"
    }
  });
  console.log("Cent Oro actualizado.");

  // 4. Bot BTC
  await prisma.botProduct.update({
    where: { id: "cmn9hf9bm0003vhbckaamkqal" },
    data: {
      ex5FilePath: "/uploads/BTCSTORM_RIDER_ULTRA_v7_11.ex5",
      pdfFilePath: "/uploads/Manual_BTCStormRider.pdf"
    }
  });
  console.log("BTC actualizado.");

  console.log("✅ ¡Rutas de archivos de los bots actualizadas con éxito!");
}

main()
  .catch(e => {
    console.error("Error actualizando rutas:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
