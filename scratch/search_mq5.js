const fs = require('fs');

const pathDemo = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\BOTS MARTINGALA CLAUDE\\Elite_Gold_MAIKO_Sniper.mq5';
const pathCent = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\MQL5\\Experts\\BOTS MARTINGALA CLAUDE\\Maiko_Sniper_PRO_CENT.mq5';

function searchInFile(filePath, name) {
    if (!fs.existsSync(filePath)) {
        console.log(`File not found: ${filePath}`);
        return;
    }
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');
    console.log(`\n--- SEARCH IN ${name} ---`);
    
    // Search for license ID, WebRequest, URLs, sync functions
    let licenseLines = [];
    let webRequestLines = [];
    let urlLines = [];
    let magicLines = [];
    
    lines.forEach((line, idx) => {
        const lower = line.toLowerCase();
        if (lower.includes('license') || lower.includes('licencia') || lower.includes('cmn9h')) {
            licenseLines.push(`${idx + 1}: ${line.trim()}`);
        }
        if (lower.includes('webrequest')) {
            webRequestLines.push(`${idx + 1}: ${line.trim()}`);
        }
        if (lower.includes('url') || lower.includes('http')) {
            urlLines.push(`${idx + 1}: ${line.trim()}`);
        }
        if (lower.includes('magic') || lower.includes('input uint')) {
            magicLines.push(`${idx + 1}: ${line.trim()}`);
        }
    });

    console.log(`\nLicense-related lines (showing first 10):`);
    licenseLines.slice(0, 10).forEach(l => console.log(l));

    console.log(`\nWebRequest lines:`);
    webRequestLines.forEach(l => console.log(l));

    console.log(`\nURL/HTTP lines (showing first 10):`);
    urlLines.slice(0, 10).forEach(l => console.log(l));
    
    console.log(`\nMagic/Input lines (showing first 10):`);
    magicLines.slice(0, 10).forEach(l => console.log(l));
}

searchInFile(pathDemo, 'DEMO GOLD BOT');
searchInFile(pathCent, 'CENT GOLD BOT');
