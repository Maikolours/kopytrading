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
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5"
];

const newOnChartEvent = `void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        if(sparam == "MAIKO_BtnP") {
            BotActivo = !BotActivo; 
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

const newCrearBoton = `void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, ENUM_BASE_CORNER c) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h); 
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg); 
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); 
    int z = 80;
    if(StringFind(n, "Btn") >= 0) z = 110;
    ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
}`;

const newCrearLabel = `void CrearLabel(string n, int x, int y, string t, color col, int s, ENUM_BASE_CORNER c) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); 
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_BACK, false); 
    ObjectSetInteger(0, n, OBJPROP_ZORDER, 100); 
}`;

terminals.forEach(term => {
    files.forEach(filename => {
        const filePath = path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO", filename);
        if (!fs.existsSync(filePath)) {
            console.log(`File not found: ${filePath}`);
            return;
        }

        console.log(`Patching HUD interaction for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        // Replace OnChartEvent
        const onChartEventRegex = /void\s+OnChartEvent\([\s\S]*?\n\}/;
        if (content.match(onChartEventRegex)) {
            content = content.replace(onChartEventRegex, newOnChartEvent);
            console.log(`  - Patched OnChartEvent`);
        } else {
            console.log(`  - Warning: OnChartEvent not found in ${filename}`);
        }

        // Replace CrearBoton
        const crearBotonRegex = /void\s+CrearBoton\([\s\S]*?\n\}/;
        if (content.match(crearBotonRegex)) {
            content = content.replace(crearBotonRegex, newCrearBoton);
            console.log(`  - Patched CrearBoton`);
        } else {
            console.log(`  - Warning: CrearBoton not found in ${filename}`);
        }

        // Replace CrearLabel
        const crearLabelRegex = /void\s+CrearLabel\([\s\S]*?\n\}/;
        if (content.match(crearLabelRegex)) {
            content = content.replace(crearLabelRegex, newCrearLabel);
            console.log(`  - Patched CrearLabel`);
        } else {
            console.log(`  - Warning: CrearLabel not found in ${filename}`);
        }

        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Successfully patched HUD in: ${filename}`);
    });
});
