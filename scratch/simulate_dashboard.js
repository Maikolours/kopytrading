const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== SIMULANDO RENDERIZADO DEL DASHBOARD ===");
    
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
            }
        }
    });

    console.log(`\nTotal Purchases fetched: ${purchases.length}`);

    // Agrupación por categoría
    const categoryGroups = {};
    purchases.forEach(p => {
        const name = (p.botProduct?.name || "").toUpperCase();
        const instrument = (p.botProduct?.instrument || "").toUpperCase();
        let key = "MAIKO SNIPER PRO 🎯";
        
        if (instrument.includes("BTC") || name.includes("BTC")) {
            key = "MAIKO SNIPER PRO BTC ₿";
        } else if (name.includes("CENT")) {
            key = "MAIKO SNIPER PRO GOLD CENT ⚡";
        } else if (instrument.includes("XAU") || name.includes("GOLD") || name.includes("ORO")) {
            key = "MAIKO SNIPER PRO GOLD 🏆";
        }
        
        if (!categoryGroups[key]) categoryGroups[key] = [];
        categoryGroups[key].push(p);
    });

    Object.keys(categoryGroups).forEach(cat => {
        console.log(`\nCategoría: ${cat} (Tiene ${categoryGroups[cat].length} compras)`);
        
        // Agrupación por botsByBaseName
        const botsByBaseName = {};
        categoryGroups[cat].forEach(p => {
            const groupKey = p.id;
            botsByBaseName[groupKey] = [p];
        });
        
        Object.entries(botsByBaseName).forEach(([id, variants]) => {
            const purchase = variants[0];
            const botProduct = purchase.botProduct;
            console.log(`  - Card Rendered:`);
            console.log(`    * Title/Name: ${botProduct.name}`);
            console.log(`    * Purchase ID: ${purchase.id}`);
            console.log(`    * Purchase Balance: ${purchase.balance}`);
            console.log(`    * Purchase Equity: ${purchase.equity}`);
            console.log(`    * BotSettings count: ${purchase.botSettings.length}`);
            purchase.botSettings.forEach(s => {
                console.log(`      Acc: ${s.account} | updated: ${s.updatedAt}`);
            });
        });
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
