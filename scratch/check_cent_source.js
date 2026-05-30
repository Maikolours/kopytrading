const fs = require('fs');
const path = require('path');

const centExpertsDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\MQL5\\Experts\\BOTS MAIKO';

if (fs.existsSync(centExpertsDir)) {
    console.log("=== CENT EXPERTS FILES ===");
    fs.readdirSync(centExpertsDir).forEach(file => {
        const fullPath = path.join(centExpertsDir, file);
        const stat = fs.statSync(fullPath);
        console.log(`File: ${file} | Size: ${stat.size} | Modified: ${stat.mtime}`);
    });
} else {
    console.log("CENT experts directory not found!");
}
