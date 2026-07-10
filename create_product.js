const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
    let product = await prisma.botProduct.create({
        data: {
            name: "MAIKO UFVG",
            description: "Bot para MT5 que opera rupturas del rango de 5M de NY con confirmacion de FVG en 1M.",
            instrument: "Varios",
            strategyType: "Breakout",
            riskLevel: "Medio",
            price: 299,
            version: "1.00",
            isActive: true,
            status: "ACTIVE"
        }
    });
    console.log("Created product: " + product.id);
    
    let user = await prisma.user.findUnique({where: {email: "viajaconsakura@gmail.com"}});
    if (user) {
        let purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: product.id,
                amount: 0,
                status: "COMPLETED"
            }
        });
        console.log("Created real purchase for user: " + purchase.id);
    }
}
main().catch(e => console.error(e)).finally(() => prisma.$disconnect());
