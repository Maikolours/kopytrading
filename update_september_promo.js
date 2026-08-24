const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Actualizando productos para Lanzamiento el 1 de Septiembre (M15)...");

  // 1. Bot Gold Real -> Estado UPCOMING (Lanzamiento 1 Septiembre), M15, 100€ (Tachado 200€)
  const goldReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      name: "MAIKO SNIPER PRO GOLD (REAL) 🏆",
      price: 100.00,
      originalPrice: 200.00,
      status: "UPCOMING",
      isActive: true,
      timeframes: "M15",
      description: "Nuestra versión estrella oficial para operar con dinero real en MetaTrader 5 (XAUUSD en M15). Algoritmo de alta frecuencia con gestión de riesgo institucional. ¡Promoción de lanzamiento disponible a partir del 1 de Septiembre! Solo 100€ (50% de descuento sobre el precio regular de 200€) para las primeras 50 licencias."
    }
  });
  console.log(`✅ Gold Real actualizado: ${goldReal.name} | Estado: ${goldReal.status} | TF: ${goldReal.timeframes}`);

  // 2. Bot Cent Real -> Estado UPCOMING (Lanzamiento 1 Septiembre), M15, 100€ (Tachado 200€)
  const centReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      name: "MAIKO SNIPER PRO GOLD CENT ⚡",
      price: 100.00,
      originalPrice: 200.00,
      status: "UPCOMING",
      isActive: true,
      timeframes: "M15",
      description: "Diseñado especialmente para cuentas Micro / CENT en MetaTrader 5 (XAUUSD en M15). Ideal para operar con bajo capital inicial (desde $50) manteniendo una gestión de riesgo súper conservadora. Disponible para adquisición a partir del 1 de Septiembre por solo 100€ (Antes 200€)."
    }
  });
  console.log(`✅ Cent Real actualizado: ${centReal.name} | Estado: ${centReal.status} | TF: ${centReal.timeframes}`);

  // 3. Bot Demo -> Estado ACTIVE, M15
  const goldDemo = await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: {
      timeframes: "M15",
      description: "Prueba nuestro bot estrella MAIKO SNIPER PRO GOLD durante 30 días en tu cuenta demo de MetaTrader 5 en gráfico de M15. Esta versión de prueba es 100% idéntica al algoritmo real en funcionalidad y precisión."
    }
  });
  console.log(`✅ Gold Demo actualizado: ${goldDemo.name} | Estado: ${goldDemo.status} | TF: ${goldDemo.timeframes}`);

  console.log("🎉 ¡Base de datos de productos actualizada exitosamente!");
}

main()
  .catch(e => {
    console.error("Error actualizando productos:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
