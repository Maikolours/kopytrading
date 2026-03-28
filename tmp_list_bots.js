const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function listBots() {
    console.log("🤖 Listing all BotProducts...");
    
    try {
        const bots = await prisma.botProduct.findMany();
        bots.forEach(b => {
            console.log(` - [${b.id}] ${b.name} (${b.instrument}) - File: ${b.ex5FilePath}`);
        });
    } catch (e) {
        console.error("❌ Error:", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

listBots();
