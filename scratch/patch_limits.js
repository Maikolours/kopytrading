const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const files = [
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5"
];

terminals.forEach(term => {
    files.forEach(filename => {
        const filePath = path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO", filename);
        if (!fs.existsSync(filePath)) {
            console.log(`File not found: ${filePath}`);
            return;
        }

        console.log(`Patching limits for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        // Check if the limit check is already added
        if (content.includes("LimitePosicionesSOS) { txtVeredicto = \"LIMITE POSICIONES ALCANZADO\"")) {
            console.log(`Already patched: ${filename}`);
            return;
        }

        // Replace void GestionarRefuerzoInteligente() { \n int last = ArraySize(pos)-1;
        // with the check
        content = content.replace(
            /void\s+GestionarRefuerzoInteligente\(\)\s*\{([\s\S]*?)int\s+last\s*=\s*ArraySize\(pos\)-1;/m,
            `void GestionarRefuerzoInteligente() {\r\n    if(ArraySize(pos) >= LimitePosicionesSOS) {\r\n        txtVeredicto = "LIMITE POSICIONES ALCANZADO";\r\n        return;\r\n    }\r\n    int last = ArraySize(pos)-1;`
        );

        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Successfully patched limits in: ${filename}`);
    });
});
