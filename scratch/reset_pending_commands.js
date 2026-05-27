const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("=== RESETTING STUCK PENDING COMMANDS ===");
    const settings = await prisma.botSettings.findMany();
    
    for (const s of settings) {
        try {
            const parsed = JSON.parse(s.settings);
            if (parsed.pendingCmd && parsed.pendingCmd !== "NONE") {
                console.log(`Resetting pendingCmd for Account: ${s.account}, Bot Purchase ID: ${s.purchaseId} (was ${parsed.pendingCmd})`);
                parsed.pendingCmd = "NONE";
                await prisma.botSettings.update({
                    where: { id: s.id },
                    data: { settings: JSON.stringify(parsed) }
                });
            }
        } catch (e) {
            console.error(`Error resetting setting ${s.id}:`, e);
        }
    }
    console.log("=== RESET COMPLETE ===");
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
