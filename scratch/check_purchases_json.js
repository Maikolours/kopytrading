const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const user = await prisma.user.findUnique({
        where: { email: "viajaconsakura@gmail.com" }
    });
    
    const purchases = await prisma.purchase.findMany({
        where: { userId: user.id },
        include: { 
            botProduct: true,
            botSettings: {
                orderBy: { updatedAt: 'desc' }
            },
            activePositions: {
                orderBy: { updatedAt: 'desc' }
            },
            pastTrades: {
                orderBy: { closedAt: 'desc' },
                take: 10
            }
        }
    });

    console.log(JSON.stringify(purchases, null, 2));
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
