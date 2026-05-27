const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== ANÁLISIS DE LICENCIAS Y DESCARGAS DE BOTS ===");
    
    // 1. Obtener todas las compras y sincronizaciones
    const purchases = await prisma.purchase.findMany({
        include: {
            user: {
                select: { name: true, email: true }
            },
            botProduct: {
                select: { name: true, productKey: true }
            },
            licenseSessions: true
        },
        orderBy: { lastSync: 'desc' }
    });

    console.log(`\nTotal de registros de licencias/compras: ${purchases.length}`);
    
    const activeSyncs = purchases.filter(p => p.lastSync);
    console.log(`Licencias que han sincronizado alguna vez (Demos o Reales): ${activeSyncs.length}\n`);

    console.log("Detalles de las sincronizaciones de usuarios:");
    console.log("------------------------------------------------------------------------------------------------------------------");
    console.log(String("Usuario").padEnd(25) + " | " + String("Email").padEnd(25) + " | " + String("Bot").padEnd(25) + " | " + String("Última Sincro").padEnd(20) + " | " + "Balance / Equity");
    console.log("------------------------------------------------------------------------------------------------------------------");
    
    purchases.forEach(p => {
        const userName = p.user.name || "Sin nombre";
        const userEmail = p.user.email || "Sin email";
        const botName = p.botProduct.name || "Desconocido";
        const lastSyncStr = p.lastSync ? new Date(p.lastSync).toLocaleString('es-ES') : "Nunca (Solo descargado o inactivo)";
        const balanceEquity = p.balance !== null ? `$${p.balance} / $${p.equity}` : "N/A";
        
        console.log(
            userName.substring(0, 25).padEnd(25) + " | " +
            userEmail.substring(0, 25).padEnd(25) + " | " +
            botName.substring(0, 25).padEnd(25) + " | " +
            lastSyncStr.padEnd(20) + " | " +
            balanceEquity
        );
    });

    // 2. Sesiones de Licencia activas en MetaTrader
    console.log("\n=== SESIONES DE LICENCIA ACTIVAS EN METATRADER ===");
    const sessions = await prisma.licenseSession.findMany({
        include: {
            purchase: {
                include: {
                    user: { select: { name: true, email: true } },
                    botProduct: { select: { name: true } }
                }
            }
        }
    });

    if (sessions.length === 0) {
        console.log("No hay sesiones de licencia activas registradas actualmente en terminales MT5.");
    } else {
        sessions.forEach(s => {
            console.log(`Usuario: ${s.purchase.user.name || "N/A"} (${s.purchase.user.email})`);
            console.log(`Bot: ${s.purchase.botProduct.name}`);
            console.log(`Cuenta de Trading: ${s.account}`);
            console.log(`Última actividad: ${new Date(s.lastActivity).toLocaleString('es-ES')}`);
            console.log(`Estado: ${s.isActive ? "ACTIVO 🟢" : "INACTIVO 🔴"}`);
            console.log("--------------------------------------------------");
        });
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
