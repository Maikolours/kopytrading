const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("Actualizando precios de los bots...");

    // Ametralladora
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'Ametralladora' } },
        data: { price: 67 }
    });

    // Yen Ninja
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'Yen' } },
        data: { price: 77 }
    });

    // BTC Storm Rider
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'BTC' } },
        data: { price: 87 }
    });

    // Gold Sentinel Pro
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'Gold' } },
        data: { price: 97 }
    });

    console.log("✅ ¡Precios actualizados en la base de datos!");
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
