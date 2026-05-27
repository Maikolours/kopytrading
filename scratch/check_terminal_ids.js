const fs = require('fs');

function checkFile(filePath, label) {
    if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        console.log(`=== ${label} ===`);
        const lines = content.split('\n');
        lines.forEach((line, idx) => {
            if (line.includes('PurchaseID') || line.includes('MiLicencia') || line.includes('UserEmail') || line.includes('licenseKey')) {
                console.log(`  Línea ${idx + 1}: ${line.trim()}`);
            }
        });
    } else {
        console.log(`Archivo no encontrado: ${filePath}`);
    }
}

// Terminal 1
checkFile(
    'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\BOTS MAIKO DEV\\Maiko_Sniper_PRO_GOLD_DEV.mq5',
    'Terminal 1: GOLD'
);
checkFile(
    'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\BOTS MAIKO DEV\\Maiko_BTC_Weekend.mq5',
    'Terminal 1: BTC'
);

// Terminal 2
checkFile(
    'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\MQL5\\Experts\\BOTS MAIKO DEV\\Maiko_Sniper_PRO_CENT_DEV.mq5',
    'Terminal 2: CENT'
);
