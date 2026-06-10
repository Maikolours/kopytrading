const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Actualizando metadatos y rutas de bots en la base de datos...");

  // 1. Bot Gold Demo (cmn9hf8yc0000vhbcq9hbxk0j)
  await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: {
      ex5FilePath: "/uploads/KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.ex5",
      pdfFilePath: "/uploads/Manual_Maiko_Pro_Gold.pdf",
      strategyType: "Scalping · M5",
      timeframes: "M5 (Optimizado)",
      description: "Prueba nuestro bot estrella MAIKO PRO GOLD durante 30 días en tu cuenta demo. Algoritmo de alta frecuencia (M5) con entradas tipo Sniper y gestión dinámica de drawdown (Grid)."
    }
  });
  console.log("✅ Demo Oro actualizado en base de datos.");

  // 2. Bot Gold Real (cmn9hf9440001vhbclffx9no6)
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      ex5FilePath: "/uploads/KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.ex5",
      pdfFilePath: "/uploads/Manual_Maiko_Pro_Gold.pdf",
      strategyType: "Scalping · M5",
      timeframes: "M5 (Optimizado)",
      description: "El algoritmo insignia para Oro. Diseñado para M5 con entradas hiperprecisas tipo Sniper y recuperación mediante grid y martingala dinámica. Ideal para scalping agresivo en XAUUSD."
    }
  });
  console.log("✅ Real Oro actualizado en base de datos.");

  // 3. Bot Cent (cmn9hf9800002vhbc5rky6dx8)
  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      ex5FilePath: "/uploads/KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.ex5",
      pdfFilePath: "/uploads/Manual_Maiko_Pro_Cent.pdf",
      strategyType: "Scalping · M5",
      timeframes: "M5 (Optimizado)",
      description: "La agresividad y precisión del Sniper Gold adaptada a cuentas CENT. Ejecuta en M5 usando los mismos algoritmos de recuperación pero reduciendo la exposición del capital drásticamente."
    }
  });
  console.log("✅ Cent Oro actualizado en base de datos.");

  // 4. Bot BTC (cmn9hf9bm0003vhbckaamkqal)
  await prisma.botProduct.update({
    where: { id: "cmn9hf9bm0003vhbckaamkqal" },
    data: {
      pdfFilePath: "/uploads/Manual_Maiko_Pro_BTC.pdf"
    }
  });
  console.log("✅ BTC actualizado en base de datos.");

  console.log("🎉 ¡Todos los metadatos y rutas de bots han sido sincronizados!");
}

main()
  .catch(e => {
    console.error("Error al actualizar la base de datos:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
