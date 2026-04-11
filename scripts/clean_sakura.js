const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function clean() {
    console.log("--- Iniciando Limpieza Técnica para Sakura ---");
    
    // 1. Encontrar al usuario
    const user = await prisma.user.findFirst({
        where: { OR: [{ id: "viajaconsakura" }, { email: { contains: "viajaconsakura" } }] }
    });

    if (user) {
        // 2. Borrar todos los registros de telemetría previos (BotSettings)
        const deleted = await prisma.botSettings.deleteMany({
            where: { purchase: { userId: user.id } }
        });
        console.log(`✅ Se han eliminado ${deleted.count} registros de telemetría antiguos.`);
        console.log("🚀 El camino está libre para que el bot v13 sincronice sus $993.64.");
    } else {
        console.log("❌ Usuario Sakura no encontrado.");
    }
}

clean()
    .catch(e => console.error(e))
    .finally(() => prisma.$disconnect());
