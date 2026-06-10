const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const allFiles = [
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5"
];

const normalAndEurFiles = [
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5"
];

const newOnChartEvent = `void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        if(sparam == "MAIKO_BtnP") {
            BotActivo = !BotActivo; 
            if(BotActivo) {
                enFaseAnalisis = true;
                proximoAtaque = TimeCurrent();
                pausaVolatilidad = 0;
            }
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ActualizarInterfazMaster();
        }
        if(sparam == "MAIKO_BtnC") { 
            CerrarTodo(); 
            enFaseAnalisis = false; 
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ActualizarInterfazMaster();
        } 
        if(sparam == "MAIKO_BtnMin") { 
            ToggleHUD(); 
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); 
        } 
        ChartRedraw(); 
    } 
}`;

const newStatusMetaTP = `    double metaTP = CalcularMetaEscapeTP();
    if(metaTP > 0) {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP: %.2f", metaTP));
    } else {
        if(!BotActivo) {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BOT APAGADO (INACTIVO)");
        } else if(!EsHorarioPermitido()) {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: FUERA DE HORARIO");
        } else if(TimeCurrent() < pausaVolatilidad) {
            int seg = (int)(pausaVolatilidad - TimeCurrent());
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("PAUSA VOLATILIDAD: %ds", seg));
        } else if(TimeCurrent() < proximoAtaque) {
            int seg = (int)(proximoAtaque - TimeCurrent());
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("PAUSA SEGURIDAD: %ds", seg));
        } else {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BUSCANDO ENTRADA EN M1...");
        }
    }`;

terminals.forEach(term => {
    allFiles.forEach(filename => {
        const filePath = path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO", filename);
        if (!fs.existsSync(filePath)) {
            return;
        }

        console.log(`Patching instant start for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        // 1. Replace OnChartEvent
        const onChartEventRegex = /void\s+OnChartEvent\([\s\S]*?\n\}/;
        if (content.match(onChartEventRegex)) {
            content = content.replace(onChartEventRegex, newOnChartEvent);
            console.log(`  - Patched OnChartEvent`);
        }

        // 2. For Normal & EURUSD files: fix Label and status messages
        if (normalAndEurFiles.includes(filename)) {
            // Replace CrearLabel MetaTP to avoid showing "Label" initially
            content = content.replace(
                /CrearLabel\(\"MAIKO_MetaTP\"\s*,\s*x\+10\s*,\s*y\+190\s*,\s*\"\"\s*,/g,
                'CrearLabel("MAIKO_MetaTP", x+10, y+190, " ",'
            );

            // Replace metaTP display logic with live status messages
            const metaTPRegex = /double\s+metaTP\s*=\s*CalcularMetaEscapeTP\(\);[\s\S]*?ObjectSetString\(0,\s*\"MAIKO_MetaTP\",\s*OBJPROP_TEXT,\s*\"\"\s*\);\s*\r?\n?\t*\}/;
            if (content.match(metaTPRegex)) {
                content = content.replace(metaTPRegex, newStatusMetaTP);
                console.log(`  - Patched MetaTP HUD Status`);
            } else {
                console.log(`  - Warning: MetaTP display block not matched in ${filename}`);
            }
        }

        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Successfully patched: ${filename}`);
    });
});
