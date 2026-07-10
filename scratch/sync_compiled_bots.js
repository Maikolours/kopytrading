const fs = require('fs');
const path = require('path');

const terminals = [
    "BB8163656548A371304D87AABB7A68EB",
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const filesToCopy = [
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.ex5",
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.ex5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.ex5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.ex5"
];

const srcDir = "private_bots_backup";
const publicDir = "public/uploads/bots";

// 1. Copy to Terminals
terminals.forEach(term => {
    const destDir = path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO");
    if (!fs.existsSync(destDir)) {
        console.log(`Destination directory not found for terminal ${term}: ${destDir}`);
        return;
    }
    
    filesToCopy.forEach(file => {
        const srcPath = path.join(srcDir, file);
        const destPath = path.join(destDir, file);
        if (fs.existsSync(srcPath)) {
            fs.copyFileSync(srcPath, destPath);
            console.log(`Copied ${file} to terminal ${term}`);
        }
    });
});

// 2. Copy compiled EX5s to website uploads directory
filesToCopy.filter(f => f.endsWith(".ex5")).forEach(file => {
    const srcPath = path.join(srcDir, file);
    const destPath = path.join(publicDir, file);
    if (fs.existsSync(srcPath)) {
        if (!fs.existsSync(publicDir)) {
            fs.mkdirSync(publicDir, { recursive: true });
        }
        fs.copyFileSync(srcPath, destPath);
        console.log(`Copied ${file} to public uploads directory`);
    }
});
