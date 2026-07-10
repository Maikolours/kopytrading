const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("Setting CLOSE_ALL for account 27625151...");
    
    const purchaseId = 'cmn9hfapj000hvhbca86faz0c';
    const account = '27625151';
    
    const setting = await prisma.botSettings.findFirst({
        where: {
            purchaseId,
            account
        }
    });

    if (!setting) {
        console.error("Setting not found!");
        return;
    }

    let updatedJson = {};
    try {
        updatedJson = typeof setting.settings === 'string' ? JSON.parse(setting.settings) : setting.settings;
    } catch (e) {
        updatedJson = {};
    }

    updatedJson.pendingCmd = "CLOSE_ALL";

    const res = await prisma.botSettings.update({
        where: { id: setting.id },
        data: { settings: JSON.stringify(updatedJson) }
    });

    console.log("SUCCESS! Updated settings.");
}

main().catch(console.error).finally(() => prisma.$disconnect());
