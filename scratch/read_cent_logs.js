const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

console.log("=== LOADED EXPERTS TODAY ===");
lines.forEach(line => {
    if (line.includes('expert') && (line.includes('loaded') || line.includes('removed'))) {
        console.log(line.trim());
    }
});

console.log("\n=== ALL COMPLETED DEALS (deal #...) ===");
lines.forEach(line => {
    if (line.includes('deal #')) {
        console.log(line.trim());
    }
});
