const fs = require('fs');
const path = require('path');

const logDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\logs';
const files = ['20260529.log', '20260530.log'];

console.log("=== SCANNING BTCUSD TRADES IN GOLD TERMINAL LOGS ===");

files.forEach(fileName => {
    const filePath = path.join(logDir, fileName);
    if (!fs.existsSync(filePath)) {
        console.log(`Log file not found: ${fileName}`);
        return;
    }
    
    console.log(`\n--- Reading log: ${fileName} ---`);
    const text = fs.readFileSync(filePath, 'utf16le');
    const lines = text.split('\n');
    
    lines.forEach(line => {
        const lowerLine = line.toLowerCase();
        if (lowerLine.includes('btcusd') || lowerLine.includes('418437977') || lowerLine.includes('418449725') || lowerLine.includes('418481630')) {
            console.log(line.trim());
        }
    });
});
