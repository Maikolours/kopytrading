const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Actualizando productos en base de datos para la promoción de Lanzamiento de Septiembre (-50%)...");

  // 1. Bot Gold Real (MAIKO PRO GOLD REAL) -> Habilitar compra, Precio 100€ (Tachado 200€)
  const goldReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      name: "MAIKO SNIPER PRO GOLD (REAL) 🏆",
      price: 100.00,
      originalPrice: 200.00,
      status: "ACTIVE",
      isActive: true,
      description: "Nuestra versión estrella oficial para operar con dinero real en MetaTrader 5 (XAUUSD). Algoritmo de alta frecuencia con gestión de riesgo institucional. ¡Promoción especial de lanzamiento en Septiembre! Solo 100€ (50% de descuento sobre el precio regular de 200€) para los primeros compradores."
    }
  });
  console.log(`✅ Gold Real actualizado: ${goldReal.name} | Precio: ${goldReal.price}€ (Original: ${goldReal.originalPrice}€) | Estado: ${goldReal.status}`);

  // 2. Bot Cent Real (MAIKO SNIPER PRO GOLD CENT) -> Habilitar compra, Precio 100€ (Tachado 200€)
  const centReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      name: "MAIKO SNIPER PRO GOLD CENT ⚡",
      price: 100.00,
      originalPrice: 200.00,
      status: "ACTIVE",
      isActive: true,
      description: "Diseñado especialmente para cuentas Micro / CENT en MetaTrader 5. Ideal para operar con bajo capital inicial (desde $50) manteniendo una gestión de riesgo súper conservadora. ¡Oferta de lanzamiento en Septiembre! Adquiérelo por solo 100€ (Antes 200€)."
    }
  });
  console.log(`✅ Cent Real actualizado: ${centReal.name} | Precio: ${centReal.price}€ (Original: ${centReal.originalPrice}€) | Estado: ${centReal.status}`);

  // 3. Asegurar rutas de descarga apuntando a los .ex5 compilados protegidos
  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      ex5FilePath: "/uploads/bots/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.ex5",
      pdfFilePath: "/uploads/Manual_Ametralladora.pdf"
    }
  });

  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      ex5FilePath: "/uploads/bots/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.ex5",
      pdfFilePath: "/uploads/Manual_Ametralladora.pdf"
    }
  });

  console.log("🎉 ¡Base de datos de productos actualizada con éxito!");
}

main()
  .catch(e => {
    console.error("Error actualizando productos:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
