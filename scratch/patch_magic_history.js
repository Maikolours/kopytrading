// Script to apply strict Magic Number filtering to history calculations across all bots
const fs = require('fs');
const path = require('path');

const uploadsDir = "c:\\proyectos\\APP KOPYTRADE\\public\\uploads\\bots";

// List of all MQ5 files to patch
const files = [
    "Maiko_Sniper_PRO_GOLD_DEV.mq5",
    "Maiko_Sniper_PRO_CENT_DEV.mq5",
    "Maiko_Sniper_PRO_GOLD_CLIENT.mq5",
    "Maiko_Sniper_PRO_CENT_CLIENT.mq5",
    "Maiko_Sniper_PRO_GOLD_V11.mq5",
    "Maiko_Sniper_PRO_CENT_V11.mq5"
];

console.log("=== STEP 1: Patching MQ5 files in uploads directory ===");

files.forEach(fileName => {
    const filePath = path.join(uploadsDir, fileName);
    if (!fs.existsSync(filePath)) {
        console.warn(`File not found, skipping: ${fileName}`);
        return;
    }

    let content = fs.readFileSync(filePath, 'utf8');
    let patched = false;

    if (fileName.includes("_V11")) {
        // High-frequency V11 files: patch CalcularGanadoHoy()
        const target = `double CalcularGanadoHoy() { \r\n    double total = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent()); \r\n    for(int i=HistoryDealsTotal()-1; i>=0; i--) {\r\n        ulong t = HistoryDealGetTicket(i);\r\n        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));\r\n    }\r\n    return total; \r\n}`;
        const targetLf = `double CalcularGanadoHoy() { \n    double total = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent()); \n    for(int i=HistoryDealsTotal()-1; i>=0; i--) {\n        ulong t = HistoryDealGetTicket(i);\n        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));\n    }\n    return total; \n}`;
        
        const replacement = `double CalcularGanadoHoy() { \n    double total = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent()); \n    for(int i=HistoryDealsTotal()-1; i>=0; i--) {\n        ulong t = HistoryDealGetTicket(i);\n        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == ExpertMagic) {\n            total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));\n        }\n    }\n    return total; \n}`;

        if (content.includes(target)) {
            content = content.replace(target, replacement);
            patched = true;
        } else if (content.includes(targetLf)) {
            content = content.replace(targetLf, replacement);
            patched = true;
        } else {
            // Fallback string replacement if formatting differs slightly
            const fallbackTarget = `if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));`;
            const fallbackReplacement = `if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == ExpertMagic) {\n            total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));\n        }`;
            if (content.includes(fallbackTarget)) {
                content = content.replace(fallbackTarget, fallbackReplacement);
                patched = true;
            }
        }
    } else {
        // Slow strategy files (DEV, CLIENT): patch CalcularGanadoUltraPreciso()
        const target = `ulong t = HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol) continue;`;
        const replacement = `ulong t = HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(t, DEAL_MAGIC) != ExpertMagic) continue;`;
        
        if (content.includes(target)) {
            content = content.replace(target, replacement);
            patched = true;
        }
    }

    if (patched) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Successfully patched file: ${fileName}`);
    } else {
        console.log(`File was already patched or signature not found: ${fileName}`);
    }
});

console.log("=== MQ5 Patching Completed successfully ===");
