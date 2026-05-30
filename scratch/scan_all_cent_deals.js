const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

console.log("=== SCANNING ALL CENT DEALS ===");
const symbols = new Set();
lines.forEach(line => {
    if (line.includes('deal #')) {
        console.log(line.trim());
        const match = line.match(/deal #\d+\s+\S+\s+[\d.]+\s+(\S+)/);
        if (match) {
            symbols.add(match[1]);
        }
    }
});

console.log("\nSymbols traded today:");
symbols.forEach(s => console.log("  " + s));
