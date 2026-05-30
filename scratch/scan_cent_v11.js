const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

console.log("=== SCANNING FOR V11 MAGIC (111222) OR COMMENT (MAIKO_CENT_V11) ===");
let count = 0;
lines.forEach(line => {
    if (line.includes('111222') || line.includes('MAIKO_CENT_V11') || line.includes('CENT v11')) {
        console.log(line.trim());
        count++;
    }
});

console.log(`Total found: ${count}`);
