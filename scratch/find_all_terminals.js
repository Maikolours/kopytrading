const fs = require('fs');
const path = require('path');

const terminalParentDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal';

if (fs.existsSync(terminalParentDir)) {
    console.log("=== ALL DETECTED METATRADER 5 TERMINALS ===");
    fs.readdirSync(terminalParentDir).forEach(folder => {
        const fullPath = path.join(terminalParentDir, folder);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
            console.log(`\nTerminal ID: ${folder}`);
            
            // Check origin.txt if exists
            const originPath = path.join(fullPath, 'origin.txt');
            if (fs.existsSync(originPath)) {
                console.log(`  Origin: ${fs.readFileSync(originPath, 'utf8').trim()}`);
            }
            
            // Check if there is a logs directory and read the last line of today's log to see connected account
            const logsDir = path.join(fullPath, 'logs');
            const todayStr = new Date().toISOString().substring(0, 10).replace(/-/g, '');
            const todayLog = path.join(logsDir, todayStr + '.log');
            if (fs.existsSync(todayLog)) {
                console.log(`  Today's log exists: ${todayLog} (${fs.statSync(todayLog).size} bytes)`);
                const content = fs.readFileSync(todayLog, 'utf16le');
                const lines = content.split('\n');
                const auths = lines.filter(l => l.includes('authorized on'));
                if (auths.length > 0) {
                    console.log(`  Last Authorization: ${auths[auths.length - 1].trim()}`);
                }
            } else {
                console.log(`  No log file for today: ${todayStr}.log`);
            }
            
            // Check BOTS MAIKO experts
            const expertsDir = path.join(fullPath, 'MQL5', 'Experts', 'BOTS MAIKO');
            if (fs.existsSync(expertsDir)) {
                const files = fs.readdirSync(expertsDir).filter(f => f.includes('Maiko_BTC_Weekend_PRUEBA'));
                console.log(`  Maiko_BTC_Weekend_PRUEBA files in Experts: ${files.join(', ')}`);
            } else {
                console.log(`  BOTS MAIKO experts folder does not exist!`);
            }
        }
    });
} else {
    console.log("MetaQuotes Terminal directory not found!");
}
