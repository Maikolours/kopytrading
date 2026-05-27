const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== LISTANDO TODAS LAS CONFIGURACIONES DE BOTS EN LA DB ===");
    const settings = await prisma.botSettings.findMany({
        include: {
            purchase: {
                include: {
                    user: true,
                    botProduct: true
                }
            }
        }
    });
    
    settings.forEach(s => {
        console.log(`\nID: ${s.id}`);
        console.log(`Usuario: ${s.purchase.user.email}`);
        console.log(`Bot: ${s.purchase.botProduct.name}`);
        console.log(`Cuenta: ${s.account}`);
        console.log(`Última Actualización: ${s.updatedAt}`);
        console.log(`Settings raw type: ${typeof s.settings}`);
        console.log(`Settings content:`, s.settings);
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
