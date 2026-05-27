const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== COMPRAS DETALLADAS DE SAKURA ===");
    
    // Obtener el ID de usuario de viajaconsakura@gmail.com
    const user = await prisma.user.findUnique({
        where: { email: "viajaconsakura@gmail.com" }
    });
    
    if (!user) {
        console.error("Usuario no encontrado");
        return;
    }
    
    const purchases = await prisma.purchase.findMany({
        where: { userId: user.id },
        include: {
            botProduct: true,
            botSettings: true
        }
    });
    
    purchases.forEach(p => {
        console.log(`\n--------------------------------------------`);
        console.log(`Purchase ID: ${p.id}`);
        console.log(`Bot Product Name: ${p.botProduct.name}`);
        console.log(`Purchase Balance: ${p.balance}`);
        console.log(`Purchase Equity: ${p.equity}`);
        console.log(`Last Sync: ${p.lastSync}`);
        console.log(`BotSettings Count: ${p.botSettings.length}`);
        
        p.botSettings.forEach(s => {
            console.log(`  - Account: ${s.account}`);
            console.log(`  - Settings sample: ${s.settings.substring(0, 150)}...`);
            try {
                const parsed = JSON.parse(s.settings);
                console.log(`    * Parsed settings balance: ${parsed.balance}`);
                console.log(`    * Parsed settings equity: ${parsed.equity}`);
                console.log(`    * Parsed settings status: ${parsed.status}`);
            } catch (err) {}
        });
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
