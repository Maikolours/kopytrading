const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

console.log("=== COMPREHENSIVE DEAL ANALYSIS ===");
let totalProfit = 0;
const groups = {};

// We look for trade/deal entries like:
// Trades   '23449251': deal #853660271 sell 0.01 XAUUSD-STDc at 4560.50 done (based on order #907597127)
// Wait! Let's look for all lines containing 'deal #' and parse them.
lines.forEach(line => {
    if (line.includes('deal #')) {
        // Let's print all deals to see their structure
        const match = line.match(/deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+(\S+)\s+at\s+([\d.]+)/);
        if (match) {
            const dealId = match[1];
            const type = match[2];
            const lot = parseFloat(match[3]);
            const symbol = match[4];
            const price = parseFloat(match[5]);
            
            // Let's also check if we can find the order close comments by searching for close or order ID
            console.log(`Deal #${dealId} | Type: ${type} | Lot: ${lot} | Symbol: ${symbol} | Price: ${price} | Line: ${line.trim()}`);
        } else {
            console.log(`Other deal line: ${line.trim()}`);
        }
    }
});
