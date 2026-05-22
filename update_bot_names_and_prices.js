const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Actualizando nombres y precios de los bots para cumplir la solicitud del usuario...");

  // 1. Bot Gold Demo: Precio 1.00, Nombre con "PROBAR GRATIS"
  const goldDemo = await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: {
      name: "MAIKO SNIPER PRO GOLD (PROBAR GRATIS) (DEMO) 🏆",
      price: 1.00,
      originalPrice: 1.00,
      description: "Prueba nuestro bot estrella MAIKO SNIPER PRO GOLD durante 30 días en tu cuenta demo de MetaTrader 5. Esta versión de prueba es 100% idéntica al algoritmo real en funcionalidad y precisión. Licencia válida por 30 días por solo 1.00 EUR para validación segura de PayPal."
    }
  });
  console.log(`Actualizado Gold Demo: ${goldDemo.name}, Precio: ${goldDemo.price} EUR`);

  // 2. Bot Gold Real: Nombre con "PROBAR GRATIS"
  const goldReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: {
      name: "MAIKO SNIPER PRO GOLD (PROBAR GRATIS) 🏆"
    }
  });
  console.log(`Actualizado Gold Real: ${goldReal.name}`);

  // 3. Bot BTC Real: Nombre con "PROBAR GRATIS"
  const btcReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9bm0003vhbckaamkqal" },
    data: {
      name: "MAIKO SNIPER PRO BTC (PROBAR GRATIS) ₿"
    }
  });
  console.log(`Actualizado BTC Real: ${btcReal.name}`);

  // 4. Bot Cent: Asegurar nombre correcto sin probar gratis
  const centReal = await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: {
      name: "MAIKO SNIPER PRO GOLD CENT ⚡"
    }
  });
  console.log(`Actualizado Cent: ${centReal.name}`);

  console.log("✅ ¡Nombres y precios actualizados con éxito!");
}

main()
  .catch(e => {
    console.error("Error actualizando bots:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
