const fs = require('fs');
const path = require('path');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const ex5Main = path.join(baseProject, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5");
const mq5Main = path.join(baseProject, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const rootExperts = path.join(basePath, f, "MQL5", "Experts");
        const subExperts1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const subExperts2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");

        [rootExperts, subExperts1, subExperts2].forEach(dir => {
            if (fs.existsSync(dir)) {
                fs.copyFileSync(ex5Main, path.join(dir, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5"));
                fs.copyFileSync(mq5Main, path.join(dir, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5"));
            }
        });
    });
    console.log("✓ Copiado V11.33 en la raíz de Experts y en todas las subcarpetas.");
}
