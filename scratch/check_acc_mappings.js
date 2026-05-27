const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== ANÁLISIS DE CUENTAS Y LLAVES EN LA BASE DE DATOS ===");
    
    console.log("\n--- Posiciones Activas en DB (LivePosition) ---");
    const positions = await prisma.livePosition.findMany({
        include: {
            purchase: {
                include: {
                    botProduct: true
                }
            }
        }
    });
    
    positions.forEach(p => {
        console.log(`Cuenta: ${p.account} | Símbolo: ${posSymbol(p)} | PurchaseID: ${p.purchaseId} | Bot: ${p.purchase.botProduct.name}`);
    });
    
    console.log("\n--- Ajustes en DB (BotSettings) ---");
    const settings = await prisma.botSettings.findMany({
        include: {
            purchase: {
                include: {
                    botProduct: true
                }
            }
        }
    });
    
    settings.forEach(s => {
        console.log(`Cuenta: ${s.account} | PurchaseID: ${s.purchaseId} | Bot: ${s.purchase.botProduct.name}`);
    });
}

function posSymbol(p) {
    return p.symbol;
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
