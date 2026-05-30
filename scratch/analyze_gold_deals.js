const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

console.log("=== COMPREHENSIVE DEAL ANALYSIS FOR GOLD TERMINAL ===");

lines.forEach(line => {
    if (line.includes('deal #') && (line.includes('buy') || line.includes('sell'))) {
        console.log(line.trim());
    }
});
