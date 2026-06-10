const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
const repoPath = "c:\\proyectos\\APP KOPYTRADE\\public\\uploads\\bots";

const filesToRevert = [
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5"
];

const dirs = [];
terminals.forEach(term => {
    dirs.push(path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO"));
});
dirs.push(repoPath);

dirs.forEach(dir => {
    filesToRevert.forEach(filename => {
        const filePath = path.join(dir, filename);
        if (!fs.existsSync(filePath)) {
            return;
        }

        console.log(`Reverting StopLoss & Friday Close for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;

        // 1. Revert inputs under // --- SEGURIDAD ---
        const safetyRegex = /\/\/ --- SEGURIDAD ---[\r\n\s]+input bool InpUsarProteccionEquidad =[\s\S]+?MinutoCierreViernes = \d+;[^\r\n]*/;
        if (content.match(safetyRegex)) {
            content = content.replace(safetyRegex, '// --- SEGURIDAD ---');
            console.log(`  - Reverted inputs`);
            modified = true;
        }

        // 2. Revert globals
        if (content.includes("bool UsarProteccionEquidad =")) {
            content = content.replace(/bool UsarProteccionEquidad = (true|false);\r?\n/g, '');
            content = content.replace(/double MaxDrawdownPorcentaje = [^;\r\n]+;\r?\n/g, '');
            console.log(`  - Reverted globals`);
            modified = true;
        }

        // 3. Revert OnInit initialization
        if (content.includes("UsarProteccionEquidad = InpUsarProteccionEquidad;")) {
            content = content.replace(/UsarProteccionEquidad = InpUsarProteccionEquidad;\r?\n/g, '');
            content = content.replace(/MaxDrawdownPorcentaje = InpMaxDrawdownPorcentaje;\r?\n/g, '');
            console.log(`  - Reverted OnInit`);
            modified = true;
        }

        // 4. Revert OnTick check block
        let startIdx = content.indexOf("double multCent_sl = EsCuentaCent ? 100.0 : 1.0;");
        if (startIdx >= 0) {
            let endStr = "ActualizarInterfazMaster();\r\n                return;\r\n            }\r\n        }\r\n    }";
            let endIdx = content.indexOf(endStr, startIdx);
            if (endIdx < 0) {
                // Try LF line endings
                endStr = "ActualizarInterfazMaster();\n                return;\n            }\n        }\n    }";
                endIdx = content.indexOf(endStr, startIdx);
            }

            if (endIdx >= 0) {
                let totalEndIdx = endIdx + endStr.length;
                content = content.slice(0, startIdx) + content.slice(totalEndIdx);
                console.log(`  - Reverted OnTick checks`);
                modified = true;
            } else {
                console.log(`  - Warning: End of OnTick checks not found`);
            }
        }

        // 5. Revert HUD display to original flotante
        let hudStartIdx = content.indexOf("string ddStr = \"\";");
        if (hudStartIdx >= 0) {
            let hudEndStr = "ObjectSetString(0, \"MAIKO_Flot\", OBJPROP_TEXT, StringFormat(\"FLOTANTE: $%.2f%s\", flotante / multCent, ddStr));";
            let hudEndIdx = content.indexOf(hudEndStr, hudStartIdx);
            if (hudEndIdx < 0) {
                hudEndStr = "ObjectSetString(0, \"MAIKO_Flot\", OBJPROP_TEXT, StringFormat(\"FLOTANTE: $%.2f%s\", flotante / divVal, ddStr));";
                hudEndIdx = content.indexOf(hudEndStr, hudStartIdx);
            }

            if (hudEndIdx >= 0) {
                let totalHudEndIdx = hudEndIdx + hudEndStr.length;
                content = content.slice(0, hudStartIdx) + "ObjectSetString(0, \"MAIKO_Flot\", OBJPROP_TEXT, StringFormat(\"FLOTANTE: $%.2f\", flotante / multCent));" + content.slice(totalHudEndIdx);
                console.log(`  - Reverted HUD update`);
                modified = true;
            } else {
                console.log(`  - Warning: End of HUD update not found`);
            }
        }

        if (modified) {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Successfully reverted file: ${filename}`);
        } else {
            console.log(`No reversion needed for: ${filename}`);
        }
    });
});
