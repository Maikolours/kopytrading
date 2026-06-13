const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
const repoPath = "c:\\proyectos\\APP KOPYTRADING\\public\\uploads\\bots";

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

        console.log(`Patching StopLoss & Friday Close for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;

        // 1. Add inputs under // --- SEGURIDAD ---
        if (!content.includes("InpUsarProteccionEquidad")) {
            const seguridadRegex = /(\/\/ --- SEGURIDAD ---[\r\n]+)/;
            const newInputs = `// --- SEGURIDAD ---
input bool InpUsarProteccionEquidad = true;      // Activar Stop Loss por Equidad (Drawdown)
input double InpMaxDrawdownPorcentaje = 30.0;   // % Maximo de Drawdown permitido
input bool CerrarTodoViernesNoche = true;       // Cerrar todo el viernes a la hora limite (esten como esten)
input int HoraCierreViernes = 21;               // Hora limite de cierre (21 = 9:00 PM)
input int MinutoCierreViernes = 30;             // Minuto limite de cierre (30 = 9:30 PM)
`;
            content = content.replace(seguridadRegex, newInputs);
            console.log(`  - Patched inputs`);
            modified = true;
        }

        // 2. Add globals
        if (!content.includes("double MaxDrawdownPorcentaje = 30.0;")) {
            const globalsRegex = /(\/\/ Globales[\r\n]+)/;
            const newGlobals = `// Globales
bool UsarProteccionEquidad = true;
double MaxDrawdownPorcentaje = 30.0;
`;
            content = content.replace(globalsRegex, newGlobals);
            console.log(`  - Patched globals`);
            modified = true;
        }

        // 3. Add OnInit initialization
        if (!content.includes("MaxDrawdownPorcentaje = InpMaxDrawdownPorcentaje;")) {
            const onInitRegex = /(int\s+OnInit\(\)\s*\{)/;
            const initBlock = `int OnInit() {
    UsarProteccionEquidad = InpUsarProteccionEquidad;
    MaxDrawdownPorcentaje = InpMaxDrawdownPorcentaje;
`;
            content = content.replace(onInitRegex, initBlock);
            console.log(`  - Patched OnInit`);
            modified = true;
        }

        // 4. Add OnTick checks at the start of OnTick()
        if (!content.includes("STOP LOSS POR DRAWDOWN")) {
            const onTickChecks = `void OnTick() {
    ActualizarEstadoMaster();
    ganadoHoy = CalcularGanadoHoy();
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;

    double multCent_sl = EsCuentaCent ? 100.0 : 1.0;

    // --- PROTECCION DE EQUIDAD (STOP LOSS POR DRAWDOWN) ---
    if(UsarProteccionEquidad && ArraySize(pos) > 0) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance > 0) {
            double ddPercent = (flotante < 0) ? (-flotante / balance) * 100.0 : 0.0;
            if(ddPercent >= MaxDrawdownPorcentaje) {
                txtVoz = StringFormat("SL EQUIDAD ALCANZADO: %.1f%%", ddPercent);
                CerrarTodo();
                enFaseAnalisis = false;
                BotActivo = false;
                ActualizarInterfazMaster();
                return;
            }
        }
    }

    // --- CIERRE FORZOSO VIERNES NOCHE ---
    if(CerrarTodoViernesNoche && ArraySize(pos) > 0) {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        if(dt.day_of_week == FRIDAY) {
            if(dt.hour > HoraCierreViernes || (dt.hour == HoraCierreViernes && dt.min >= MinutoCierreViernes)) {
                txtVoz = "CIERRE VIERNES NOCHE ACTIVO.";
                CerrarTodo();
                enFaseAnalisis = false;
                ActualizarInterfazMaster();
                return;
            }
        }
    }
`;

            const oldOnTickRegex = /void\s+OnTick\(\)\s*\{\s*ActualizarEstadoMaster\(\);\s*\r?\n?\s*ganadoHoy\s*=\s*CalcularGanadoHoy\(\);\s*\r?\n?\s*flotante\s*=\s*CalcularProfit\(\);\s*\r?\n?\s*spreadActual\s*=\s*\(SymbolInfoDouble\(_Symbol,\s*SYMBOL_ASK\)\s*-\s*SymbolInfoDouble\(_Symbol,\s*SYMBOL_BID\)\)\s*\/\s*_Point\s*\/\s*10;/;
            if (content.match(oldOnTickRegex)) {
                content = content.replace(oldOnTickRegex, onTickChecks);
                console.log(`  - Patched OnTick header and added checks`);
                modified = true;
            } else {
                console.log(`  - Error: OnTick header pattern not matched for ${filename}!`);
            }
        }

        // 5. Update HUD to display current DD % next to flotante
        if (!content.includes("divVal = EsCuentaCent ? 100.0 : multCent;")) {
            const hudRegex = /ObjectSetString\(0,\s*\"MAIKO_Flot\",\s*OBJPROP_TEXT,\s*StringFormat\(\"FLOTANTE:\s*\$%\.2f\",\s*flotante\s*\/\s*[\w\d\.]+\)\);/;
            const newHud = `string ddStr = "";
    if(UsarProteccionEquidad) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance > 0) {
            double ddPercent = (flotante < 0) ? (-flotante / balance) * 100.0 : 0.0;
            ddStr = StringFormat(" (DD: %.1f%% / %.1f%%)", ddPercent, MaxDrawdownPorcentaje);
        }
    }
    double divVal = EsCuentaCent ? 100.0 : multCent;
    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE: $%.2f%s", flotante / divVal, ddStr));`;

            if (content.match(hudRegex)) {
                content = content.replace(hudRegex, newHud);
                console.log(`  - Patched HUD display with DD%`);
                modified = true;
            } else {
                console.log(`  - Warning: HUD display pattern not matched in ${filename}!`);
            }
        }

        if (modified) {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Successfully patched: ${filename}`);
        } else {
            console.log(`No changes needed: ${filename}`);
        }
    });
});
