const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const files = [
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5"
];

// Let's use the main MetaTrader editor, if not found fallback to MetaTrader 5
let editorPath = "C:\\Program Files\\MetaTrader\\MetaEditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader 5\\MetaEditor64.exe";
}
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader 5-3\\MetaEditor64.exe";
}

console.log("Using MetaEditor path:", editorPath);

files.forEach(file => {
    const absPath = path.resolve(file);
    console.log("\n------------------------------------------------");
    console.log("Compiling:", absPath);
    
    // Remove previous EX5 and log
    const ex5Path = absPath.replace(".mq5", ".ex5");
    const logPath = absPath.replace(".mq5", ".log");
    if (fs.existsSync(ex5Path)) fs.unlinkSync(ex5Path);
    if (fs.existsSync(logPath)) fs.unlinkSync(logPath);

    try {
        // MetaEditor CLI command: metaeditor64.exe /compile:"path" /log
        execSync(`"${editorPath}" /compile:"${absPath}" /log`);
    } catch (e) {
        // execSync throws if exit code != 0
    }

    if (fs.existsSync(logPath)) {
        const logContent = fs.readFileSync(logPath, 'utf16le'); // MetaEditor logs are UTF-16LE
        console.log("--- Compilation Log ---");
        console.log(logContent);
    } else {
        console.log("No log file found.");
    }

    if (fs.existsSync(ex5Path)) {
        console.log("RESULT: SUCCESS. EX5 generated.");
    } else {
        console.log("RESULT: FAILED. EX5 not generated.");
        process.exitCode = 1;
    }
});
