const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fix() {
    console.log("--- Iniciando Corrección de Base de Datos ---");

    // 1. Actualizar el producto Sniper
    const sniper = await prisma.botProduct.findFirst({
        where: { name: { contains: 'Sniper' } }
    });
    if (sniper) {
        await prisma.botProduct.update({
            where: { id: sniper.id },
            data: { productKey: 'SNIPER_V12' }
        });
        console.log(`✅ Producto '${sniper.name}' actualizado con Key: SNIPER_V12`);
    }

    // 2. Actualizar el producto Oro
    const oro = await prisma.botProduct.findFirst({
        where: { name: { contains: 'Oro' } }
    });
    if (oro) {
        await prisma.botProduct.update({
            where: { id: oro.id },
            data: { productKey: 'XAU-MG' }
        });
        console.log(`✅ Producto '${oro.name}' actualizado con Key: XAU-MG`);
    }

    console.log("--- Corrección Finalizada ---");
}

fix()
    .catch(e => console.error(e))
    .finally(() => prisma.$disconnect());
