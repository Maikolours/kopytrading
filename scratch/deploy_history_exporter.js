const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const scriptCode = `#property copyright "Antigravity AI"
#property version   "1.50"
#property script_show_inputs

// --- IMPORTAR DLL PARA NOTEPAD ---
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

input datetime StartDate = D'2026.06.04 00:00'; // 📅 Fecha de inicio del análisis
input double   CapitalInicial = 500.0;        // 💵 Capital inicial asignado al Bot ($)
input string   PanelTitle = "🤖 MAIKO SNIPER"; // 🏷️ Titulo del Panel
input int      PanelX = 80;                   // 📍 Posición X del Panel
input int      PanelY = 80;                   // 📍 Posición Y del Panel
input int      TargetMagic = 111222;          // 🤖 Magic Number de Maiko

void CleanupDashboard() {
    ObjectsDeleteAll(0, "MaikoDash_");
    ChartRedraw(0);
}

void CreateLabel(string name, string text, int x, int y, int size, color col) {
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CreateBackground(string name, int x, int y, int w, int h, color bgCol) {
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CreateButton(string name, string text, int x, int y, int w, int h, color bgCol, color textCol) {
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
    ObjectSetInteger(0, name, OBJPROP_COLOR, textCol);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

void OnStart() {
    datetime from = 0;
    datetime to = TimeCurrent();
    
    if(!HistorySelect(from, to)) {
        Print("Error seleccionando historial.");
        return;
    }
    
    CleanupDashboard();
    
    int totalDeals = HistoryDealsTotal();
    
    double botProfit = 0;
    double botCommissions = 0;
    double botSwaps = 0;
    int botDealsCount = 0;
    datetime botFirst = 0;
    datetime botLast = 0;
    
    int winTrades = 0;
    int lossTrades = 0;
    
    double current_sim_balance = CapitalInicial;
    double peak = CapitalInicial;
    double max_drawdown = 0;
    
    for(int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket == 0) continue;
        
        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        datetime time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        
        if(time < StartDate) continue;
        if(magic != TargetMagic) continue;
        
        double net = profit + commission + swap;
        botProfit += profit;
        botCommissions += commission;
        botSwaps += swap;
        
        if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) {
            botDealsCount++;
            if(net > 0) winTrades++;
            else if(net < 0) lossTrades++;
            
            current_sim_balance += net;
            if(current_sim_balance > peak) {
                peak = current_sim_balance;
            } else {
                double dd = peak - current_sim_balance;
                if(dd > max_drawdown) max_drawdown = dd;
            }
        }
        
        if(botFirst == 0 || time < botFirst) botFirst = time;
        if(time > botLast) botLast = time;
    }
    
    double botNet = botProfit + botCommissions + botSwaps;
    double botFinalBalance = CapitalInicial + botNet;
    double winRate = (botDealsCount > 0) ? ((double)winTrades / botDealsCount) * 100.0 : 0;
    double max_drawdown_pct = (peak > 0) ? (max_drawdown / peak) * 100.0 : 0;
    
    // Guardar reporte en archivo para el agente y el bloc de notas
    string filename = "Maiko_PnL_Report.txt";
    int filehandle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_ANSI);
    if(filehandle != INVALID_HANDLE) {
        FileWrite(filehandle, "===============================================");
        FileWrite(filehandle, "   REPORTE DE PNL HISTORICO EXCLUSIVO DEL BOT");
        FileWrite(filehandle, "===============================================");
        FileWrite(filehandle, StringFormat("Cuenta: %d", (int)AccountInfoInteger(ACCOUNT_LOGIN)));
        FileWrite(filehandle, StringFormat("Moneda: %s", AccountInfoString(ACCOUNT_CURRENCY)));
        FileWrite(filehandle, StringFormat("Filtro desde: %s", TimeToString(StartDate, TIME_DATE|TIME_MINUTES)));
        FileWrite(filehandle, "");
        FileWrite(filehandle, StringFormat("🤖 %s (Magic: %d)", PanelTitle, TargetMagic));
        FileWrite(filehandle, StringFormat("  Periodo operativo: %s al %s", TimeToString(botFirst, TIME_DATE), TimeToString(botLast, TIME_DATE)));
        FileWrite(filehandle, StringFormat("  Trades cerrados: %d", botDealsCount));
        FileWrite(filehandle, StringFormat("  Ganadas: %d | Perdidas: %d", winTrades, lossTrades));
        FileWrite(filehandle, StringFormat("  Porcentaje de Acierto (WinRate): %.1f%%", winRate));
        FileWrite(filehandle, StringFormat("  Capital Inicial Asignado: %.2f %s", CapitalInicial, AccountInfoString(ACCOUNT_CURRENCY)));
        FileWrite(filehandle, StringFormat("  Beneficio Neto del Bot: %.2f %s", botNet, AccountInfoString(ACCOUNT_CURRENCY)));
        FileWrite(filehandle, StringFormat("  Balance Estimado del Bot: %.2f %s", botFinalBalance, AccountInfoString(ACCOUNT_CURRENCY)));
        FileWrite(filehandle, StringFormat("  Drawdown Maximo del Balance: %.2f (%.1f%%)", max_drawdown, max_drawdown_pct));
        FileWrite(filehandle, "===============================================");
        FileClose(filehandle);
        
        // Intentar abrir el archivo en el Bloc de notas automáticamente
        if(MQLInfoInteger(MQL_DLLS_ALLOWED)) {
            string dataPath = TerminalInfoString(TERMINAL_DATA_PATH);
            string fullPath = dataPath + "\\\\MQL5\\\\Files\\\\" + filename;
            ShellExecuteW(0, "open", "notepad.exe", fullPath, "", 1);
        } else {
            Print("DLLs no permitidas. Activa 'Permitir importar DLL' si quieres que se abra en el Bloc de Notas automáticamente.");
        }
    }
    
    // Crear Dashboard visual en el gráfico
    int width = 560;
    int height = 440;
    color panelBG = C'22,22,22';
    color textColor = clrWhite;
    color accentColor = clrGold;
    color pnlColor = (botNet >= 0) ? C'46,204,113' : C'231,76,60';
    
    CreateBackground("MaikoDash_BG", PanelX, PanelY, width, height, panelBG);
    CreateBackground("MaikoDash_HeaderLine", PanelX, PanelY + 50, width, 2, accentColor);
    
    // Titulo centralizado
    string fullTitle = StringFormat("%s   -   𝗥𝗘𝗣𝗢𝗥𝗧𝗘   𝗘𝗫𝗖𝗟𝗨𝗦𝗜𝗩𝗢", PanelTitle);
    CreateLabel("MaikoDash_Title", fullTitle, PanelX + 25, PanelY + 15, 12, accentColor);
    
    // Botón de cerrar interactivo
    CreateButton("MaikoDash_CloseBtn", "❌  Cerrar", PanelX + width - 110, PanelY + 12, 90, 26, C'192,57,43', clrWhite);
    
    CreateLabel("MaikoDash_Label1", "Periodo Analizado:", PanelX + 30, PanelY + 70, 11, C'180,180,180');
    string dateStr = TimeToString(StartDate, TIME_DATE) + "  al  " + TimeToString(TimeCurrent(), TIME_DATE);
    CreateLabel("MaikoDash_Val1", dateStr, PanelX + 250, PanelY + 70, 11, textColor);
    
    CreateLabel("MaikoDash_Label2", "Capital Inicial Asignado:", PanelX + 30, PanelY + 110, 11, C'180,180,180');
    CreateLabel("MaikoDash_Val2", StringFormat("$ %.2f %s", CapitalInicial, AccountInfoString(ACCOUNT_CURRENCY)), PanelX + 250, PanelY + 110, 11, textColor);
    
    CreateLabel("MaikoDash_Label3", "Beneficio Neto Generado:", PanelX + 30, PanelY + 150, 11, C'180,180,180');
    string sign = (botNet >= 0) ? "+" : "";
    CreateLabel("MaikoDash_Val3", StringFormat("%s$ %.2f %s", sign, botNet, AccountInfoString(ACCOUNT_CURRENCY)), PanelX + 250, PanelY + 150, 12, pnlColor);
    
    CreateLabel("MaikoDash_Label4", "Balance Estimado del Bot:", PanelX + 30, PanelY + 190, 11, C'180,180,180');
    CreateLabel("MaikoDash_Val4", StringFormat("$ %.2f %s", botFinalBalance, AccountInfoString(ACCOUNT_CURRENCY)), PanelX + 250, PanelY + 190, 13, accentColor);
    
    CreateLabel("MaikoDash_Label5", "Operaciones Cerradas:", PanelX + 30, PanelY + 230, 11, C'180,180,180');
    CreateLabel("MaikoDash_Val5", StringFormat("%d trades (WinRate: %.1f%%)", botDealsCount, winRate), PanelX + 250, PanelY + 230, 11, textColor);
    
    CreateLabel("MaikoDash_Label6", "Ganadoras vs Perdedoras:", PanelX + 30, PanelY + 270, 11, C'180,180,180');
    CreateLabel("MaikoDash_Val6", StringFormat("🟢 %d win  /  🔴 %d loss", winTrades, lossTrades), PanelX + 250, PanelY + 270, 11, textColor);
    
    CreateLabel("MaikoDash_Label7", "Drawdown Maximo (Balance):", PanelX + 30, PanelY + 310, 11, C'180,180,180');
    CreateLabel("MaikoDash_Val7", StringFormat("$ %.2f (%.1f%%)", max_drawdown, max_drawdown_pct), PanelX + 250, PanelY + 310, 11, C'231,76,60');
    
    CreateBackground("MaikoDash_FooterLine", PanelX, PanelY + 370, width, 1, C'50,50,50');
    CreateLabel("MaikoDash_FooterText", "* Haz clic en el boton 'Cerrar' arriba a la derecha para quitar este panel del grafico.", PanelX + 20, PanelY + 385, 8, C'120,120,120');
    
    ChartRedraw(0);
    
    // Bucle para mantener el script activo y detectar clics en el boton "Cerrar"
    while(!IsStopped()) {
        if(ObjectGetInteger(0, "MaikoDash_CloseBtn", OBJPROP_STATE) == true) {
            CleanupDashboard();
            break;
        }
        Sleep(200);
    }
}
`;

const cleanerCode = `#property copyright "Antigravity AI"
#property version   "1.00"
#property script_show_inputs

void OnStart() {
    ObjectsDeleteAll(0, "MaikoDash_");
    ChartRedraw(0);
    Print("Panel MaikoDash eliminado del grafico.");
    MessageBox("Panel de reporte Maiko eliminado del grafico con exito.", "Limpieza Completada");
}
`;

// Find MetaEditor path
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

async function main() {
    console.log("=== Deploying and Compiling ExportMaikoHistory & DeleteMaikoReport (v1.50) ===");

    if (!fs.existsSync(basePath)) {
        console.error("Base path not found:", basePath);
        return;
    }

    const folders = fs.readdirSync(basePath).filter(f => {
        const full = path.join(basePath, f);
        return fs.statSync(full).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help';
    });

    for (const folder of folders) {
        const scriptDir = path.join(basePath, folder, "MQL5", "Scripts");
        if (!fs.existsSync(scriptDir)) {
            continue;
        }

        // 1. Write and compile ExportMaikoHistory
        const mq5Path = path.join(scriptDir, "ExportMaikoHistory.mq5");
        fs.writeFileSync(mq5Path, scriptCode, 'utf8');
        console.log(`Written script to: ${mq5Path}`);
        if (fs.existsSync(editorPath)) {
            try {
                execSync(`"${editorPath}" /compile:"${mq5Path}" /log`);
                console.log(`Compiled ExportMaikoHistory in ${folder}`);
            } catch (err) {}
        }

        // 2. Write and compile DeleteMaikoReport
        const cleanerPath = path.join(scriptDir, "DeleteMaikoReport.mq5");
        fs.writeFileSync(cleanerPath, cleanerCode, 'utf8');
        console.log(`Written cleaner to: ${cleanerPath}`);
        if (fs.existsSync(editorPath)) {
            try {
                execSync(`"${editorPath}" /compile:"${cleanerPath}" /log`);
                console.log(`Compiled DeleteMaikoReport in ${folder}`);
            } catch (err) {}
        }
    }
}

main().catch(console.error);
