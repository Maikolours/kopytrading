const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
const repoPath = "c:\\proyectos\\APP KOPYTRADE\\public\\uploads\\bots";

const filesToPatch = [
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5"
];

// Target directories
const dirs = [];
terminals.forEach(term => {
    dirs.push(path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO"));
});
dirs.push(repoPath);

dirs.forEach(dir => {
    filesToPatch.forEach(filename => {
        const filePath = path.join(dir, filename);
        if (!fs.existsSync(filePath)) {
            return;
        }

        console.log(`Removing StopLoss pause for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        // Target the tester check block and replace it with just keeping the bot active and resetting analysis
        const targetOld = `                if(!MQLInfoInteger(MQL_TESTER)) {\r\n                    BotActivo = false;\r\n                } else {\r\n                    proximoAtaque = TimeCurrent() + (24 * 3600);\r\n                }\r\n                ActualizarInterfazMaster();\r\n                return;`;
        const targetOldLF = `                if(!MQLInfoInteger(MQL_TESTER)) {\n                    BotActivo = false;\n                } else {\n                    proximoAtaque = TimeCurrent() + (24 * 3600);\n                }\n                ActualizarInterfazMaster();\n                return;`;

        const replacement = `                // Mantener BotActivo = true para volver a analizar y operar inmediatamente\r\n                ActualizarInterfazMaster();\r\n                return;`;
        const replacementLF = `                // Mantener BotActivo = true para volver a analizar y operar inmediatamente\n                ActualizarInterfazMaster();\n                return;`;

        if (content.includes(targetOld)) {
            content = content.replace(targetOld, replacement);
            console.log(`  - Patched StopLoss block (CRLF)`);
            fs.writeFileSync(filePath, content, 'utf8');
        } else if (content.includes(targetOldLF)) {
            content = content.replace(targetOldLF, replacementLF);
            console.log(`  - Patched StopLoss block (LF)`);
            fs.writeFileSync(filePath, content, 'utf8');
        } else {
            console.log(`  - Warning: StopLoss block target not found (might be already modified or in different format)`);
        }
    });
});
