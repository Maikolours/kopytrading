const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("Actualizando precios de los bots...");

    // La Ametralladora Evolution PRO (XAUUSD)
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'Ametralladora' } },
        data: { 
            price: 224, 
            originalPrice: 299,
            version: '5.84',
            status: 'UPCOMING'
        }
    });

    // Yen Ninja
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'Yen' } },
        data: { 
            price: 149, 
            originalPrice: 199,
            version: '2.0',
            status: 'MAINTENANCE'
        }
    });

    // BTC Storm Rider
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'BTC' } },
        data: { 
            price: 224, 
            originalPrice: 299,
            version: '7.11',
            status: 'UPCOMING'
        }
    });

    // Euro Precision Flow
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'Euro' } },
        data: { 
            price: 149, 
            originalPrice: 199,
            version: '2.0',
            status: 'MAINTENANCE'
        }
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
