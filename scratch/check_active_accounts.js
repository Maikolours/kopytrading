const fs = require('fs');
const path = require('path');

const centDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs';
const goldDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\logs';

function scanLogHistory(logsDir, label) {
    if (!fs.existsSync(logsDir)) {
        console.log(`Logs directory not found for ${label}`);
        return;
    }
    console.log(`\n=== ACCOUNT HISTORY FOR ${label} ===`);
    const files = fs.readdirSync(logsDir).filter(f => f.endsWith('.log')).sort().reverse().slice(0, 5);
    
    files.forEach(file => {
        const filePath = path.join(logsDir, file);
        const text = fs.readFileSync(filePath, 'utf16le');
        const lines = text.split('\n');
        const auths = lines.filter(l => l.includes('authorized on'));
        if (auths.length > 0) {
            console.log(`File: ${file}`);
            auths.forEach(a => console.log("  " + a.trim()));
        }
    });
}

scanLogHistory(centDir, 'F762D69EEEA9B4430D7F17C82167C844 (Instance A)');
scanLogHistory(goldDir, 'D0E8209F77C8CF37AD8BF550E51FF075 (Instance B)');
