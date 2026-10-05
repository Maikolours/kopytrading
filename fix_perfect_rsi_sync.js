
const fs = require("fs");
const path = require("path");

const files = [
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5",
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5"
];

for (const f of files) {
    let p = path.join("C:/proyectos/APP KOPYTRADING", f);
    if (!fs.existsSync(p)) continue;
    
    let content = fs.readFileSync(p, "utf8");
    
    // In AgregarIndicadoresVisuales, replace indicator adding with clean wipe and direct hRSI_v attachment
    let oldFuncRegex = /void AgregarIndicadoresVisuales\(\)[\s\S]*?CrearInterfazMaster\(\);/;
    
    let newFunc = `void AgregarIndicadoresVisuales() {
    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = ventanas - 1; w >= 0; w--) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = totalInd - 1; i >= 0; i--) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, "RSI") >= 0) {
                ChartIndicatorDelete(0, w, nombre);
            }
        }
    }
    
    // Añadir exactamente el mismo handle del bot al subgráfico de la pantalla
    if(hRSI_v != INVALID_HANDLE) {
        ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
    }
    
    CrearInterfazMaster();`;
    
    content = content.replace(oldFuncRegex, newFunc);
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Perfect RSI sync applied to " + f);
}

