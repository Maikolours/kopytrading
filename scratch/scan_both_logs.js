const fs = require('fs');
const path = require('path');

const centLogPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';
const goldLogPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\logs\\20260529.log';

function scanLog(logPath, label) {
    if (!fs.existsSync(logPath)) {
        console.log(`\n=== LOG FOR ${label} NOT FOUND AT ${logPath} ===`);
        return;
    }
    const text = fs.readFileSync(logPath, 'utf16le');
    const lines = text.split('\n');
    
    console.log(`\n=== SCANNING LOG FOR ${label} (${lines.length} lines) ===`);
    
    // Find loaded accounts
    const accounts = new Set();
    const experts = new Set();
    
    lines.forEach(line => {
        if (line.includes('authorized on')) {
            accounts.add(line.trim());
        }
        if (line.includes('expert') && (line.includes('loaded') || line.includes('removed'))) {
            experts.add(line.trim());
        }
    });
    
    console.log("Authorized Accounts:");
    accounts.forEach(a => console.log("  " + a));
    
    console.log("Expert EA events:");
    experts.forEach(e => console.log("  " + e));
}

scanLog(centLogPath, 'F762D69EEEA9B4430D7F17C82167C844 (Instance A)');
scanLog(goldLogPath, 'D0E8209F77C8CF37AD8BF550E51FF075 (Instance B)');
