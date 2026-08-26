const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Limpiando y actualizando productos en la base de datos...");

  // 1. Bot Gold Real -> MAIKO PRO GOLD REAL
  const goldReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      name: "MAIKO PRO GOLD REAL",
      price: 100.00,
      originalPrice: 200.00,
      status: "UPCOMING",
      isActive: true,
      timeframes: "M15",
      description: "Nuestra versión estrella oficial para operar con dinero real en MetaTrader 5 (XAUUSD en M15). Algoritmo de alta frecuencia con gestión de riesgo institucional. Disponible para adquisición a partir del 1 de Septiembre con un 50% de descuento (100€ en vez de 200€)."
    }
  });
  console.log(`✅ Gold Real: ${goldReal.name} | ${goldReal.price}€ (Original: ${goldReal.originalPrice}€) | Estado: ${goldReal.status}`);

  // 2. Bot Cent Real -> MAIKO PRO GOLD CENT
  const centReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      name: "MAIKO PRO GOLD CENT",
      price: 100.00,
      originalPrice: 200.00,
      status: "UPCOMING",
      isActive: true,
      timeframes: "M15",
      description: "Diseñado especialmente para cuentas Micro / CENT en MetaTrader 5 (XAUUSD en M15). Ideal para operar con bajo capital inicial (desde $50) manteniendo una gestión de riesgo conservadora. Disponible a partir del 1 de Septiembre por 100€ (Original 200€)."
    }
  });
  console.log(`✅ Cent Real: ${centReal.name} | ${centReal.price}€ (Original: ${centReal.originalPrice}€) | Estado: ${centReal.status}`);

  // 3. Bot Gold Demo -> MAIKO PRO GOLD DEMO
  const goldDemo = await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: {
      name: "MAIKO PRO GOLD DEMO",
      price: 1.00,
      originalPrice: 1.00,
      status: "ACTIVE",
      isActive: true,
      timeframes: "M15",
      description: "Prueba nuestro bot estrella MAIKO PRO GOLD durante 30 días por solo 1€ en tu cuenta demo de MetaTrader 5 en gráfico M15."
    }
  });
  console.log(`✅ Gold Demo: ${goldDemo.name} | ${goldDemo.price}€ | Estado: ${goldDemo.status}`);

  // 4. Limpiar precios e indicar 'MAINTENANCE' / 'En Desarrollo' para el resto de bots
  const remainingBots = [
    "cmn9hf9bm0003vhbckaamkqal", // BTC
    "cmpo1aunb0000vhdglhxmhh6i", // EURO
    "cmpo1aurf0001vhdgp94zvl4m", // YEN
    "cmquperki0000vhfopdx8d5f0", // UFVG DEMO
    "cmqv2rzh40000vhmsuthl9bwq", // UFVG
  ];

  for (const id of remainingBots) {
    try {
      await prisma.botProduct.update({
        where: { id },
        data: {
          price: 0,
          originalPrice: 0,
          status: "MAINTENANCE"
        }
      });
    } catch (e) {
      console.log(`Bot ${id} no requiere cambio o no existe.`);
    }
  }

  console.log("🎉 ¡Base de datos de productos actualizada con éxito!");
}

main()
  .catch(e => {
    console.error("Error actualizando base de datos:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
