const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    let user = await prisma.user.findUnique({where: {email: "viajaconsakura@gmail.com"}});
    let product = await prisma.botProduct.findFirst({where: {name: "MAIKO UFVG"}});
    
    if (user && product) {
        let purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: product.id,
                amount: 0,
                status: "COMPLETED"
            }
        });
        console.log("Created real purchase: " + purchase.id);
    } else {
        console.log("Could not find user or product");
    }
}
main().catch(e => console.error(e)).finally(() => prisma.$disconnect());
