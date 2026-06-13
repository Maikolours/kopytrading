const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
const repoPath = "c:\\proyectos\\APP KOPYTRADING\\public\\uploads\\bots";

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

        console.log(`Fixing reversion for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;

        // 1. Revert inputs under // --- SEGURIDAD ---
        const safetyRegex = /\/\/ --- SEGURIDAD ---[\r\n\s]+input bool InpUsarProteccionEquidad =[\s\S]+?MinutoCierreViernes = \d+;[^\r\n]*/;
        if (content.match(safetyRegex)) {
            content = content.replace(safetyRegex, '// --- SEGURIDAD ---');
            console.log(`  - Removed input variables`);
            modified = true;
        }

        // 2. Revert globals
        if (content.includes("bool UsarProteccionEquidad =")) {
            content = content.replace(/bool UsarProteccionEquidad = (true|false);\r?\n/g, '');
            content = content.replace(/double MaxDrawdownPorcentaje = [^;\r\n]+;\r?\n/g, '');
            console.log(`  - Removed globals`);
            modified = true;
        }

        // 3. Revert OnInit initialization
        if (content.includes("UsarProteccionEquidad = InpUsarProteccionEquidad;")) {
            content = content.replace(/UsarProteccionEquidad = InpUsarProteccionEquidad;\r?\n/g, '');
            content = content.replace(/MaxDrawdownPorcentaje = InpMaxDrawdownPorcentaje;\r?\n/g, '');
            console.log(`  - Removed OnInit initializers`);
            modified = true;
        }

        // 4. Remove Friday Close block
        const fridayCloseRegex = /\s*\/\/ --- CIERRE FORZOSO VIERNES NOCHE ---[\s\S]+?ActualizarInterfazMaster\(\);\s*return;\s*\}\s*\}\s*\}/g;
        if (content.match(fridayCloseRegex)) {
            content = content.replace(fridayCloseRegex, '');
            console.log(`  - Removed Friday close OnTick block`);
            modified = true;
        }

        // 5. Remove Stop Loss block (in case it remains)
        const stopLossRegex1 = /\s*double multCent_sl =[\s\S]+?ActualizarInterfazMaster\(\);\s*return;\s*\}\s*\}\s*\}/g;
        if (content.match(stopLossRegex1)) {
            content = content.replace(stopLossRegex1, '');
            console.log(`  - Removed Stop Loss OnTick block (variant 1)`);
            modified = true;
        }
        const stopLossRegex2 = /\s*\/\/ --- PROTECCION DE EQUIDAD[\s\S]+?ActualizarInterfazMaster\(\);\s*return;\s*\}\s*\}\s*\}/g;
        if (content.match(stopLossRegex2)) {
            content = content.replace(stopLossRegex2, '');
            console.log(`  - Removed Stop Loss OnTick block (variant 2)`);
            modified = true;
        }

        // 6. Revert HUD display to original flotante
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
            }
        }

        if (modified) {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Successfully fixed file: ${filename}`);
        } else {
            console.log(`No changes needed for: ${filename}`);
        }
    });
});
