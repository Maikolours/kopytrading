const fs = require('fs');
const path = require('path');

const centChartsDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\MQL5\\Profiles\\Charts\\Default';
const goldChartsDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Profiles\\Charts\\Default';

function scanChartProfiles(dir, label) {
    if (!fs.existsSync(dir)) {
        console.log(`Directory not found for ${label}`);
        return;
    }
    console.log(`\n=== CHART PROFILES FOR ${label} ===`);
    fs.readdirSync(dir).forEach(file => {
        if (file.endsWith('.chr')) {
            const filePath = path.join(dir, file);
            const buffer = fs.readFileSync(filePath);
            const content = buffer.toString('utf16le');
            console.log(`Profile: ${file} | Length: ${content.length}`);
            
            const lines = content.split('\r\n');
            let inExpert = false;
            lines.forEach(line => {
                if (line.includes('<expert>')) inExpert = true;
                if (line.includes('</expert>')) inExpert = false;
                
                if (inExpert) {
                    if (line.includes('name=') || line.includes('inputs=')) {
                        console.log(`  ${line.trim()}`);
                    }
                }
            });
        }
    });
}

scanChartProfiles(centChartsDir, 'CENT Terminal (Instance A)');
scanChartProfiles(goldChartsDir, 'GOLD Terminal (Instance B)');
