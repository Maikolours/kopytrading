
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
    
    // Ensure hRSI_v is created FIRST in OnInit before AgregarIndicadoresVisuales
    content = content.replace(/hEMA_v = iMA\(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE\);\s*hRSI_v = iRSI\(_Symbol, _Period, 14, PRICE_CLOSE\);/g, "");
    
    // Insert hEMA_v and hRSI_v creation at top of OnInit
    let initStart = `int OnInit() {
    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);`;
    content = content.replace(/int OnInit\(\) \{/g, initStart);
    
    // In AgregarIndicadoresVisuales, delete any existing RSI indicator and force Add hRSI_v
    let replaceRsiVisual = `
    // Limpiar RSI antiguo visual para evitar desajustes y sincronizar handle exacto
    int vTotal = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < vTotal; w++) {
        int tInd = ChartIndicatorsTotal(0, w);
        for(int i = tInd - 1; i >= 0; i--) {
            string nInd = ChartIndicatorName(0, w, i);
            if(StringFind(nInd, "RSI") >= 0) ChartIndicatorDelete(0, w, nInd);
        }
    }
    ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
`;
    content = content.replace(/if\(!tieneRSI\) ChartIndicatorAdd\(0, \(int\)ChartGetInteger\(0, CHART_WINDOWS_TOTAL\), hRSI_v\);/g, replaceRsiVisual);
    content = content.replace(/if\(!tieneRSI\) ChartIndicatorAdd\(0, \(int\)ChartGetInteger\(0, CHART_WINDOWS_TOTAL\), hRSI_chart\);/g, replaceRsiVisual);
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Forced exact same RSI handle for " + f);
}

