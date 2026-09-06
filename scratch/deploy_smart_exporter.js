const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const scriptCode = `#property copyright "KopyTrading AI"
#property version   "2.50"
#property script_show_inputs

// --- IMPORTAR DLL PARA NOTEPAD (OPCIONAL) ---
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

// --- PARÁMETROS DE ENTRADA ---
input string   InpCustomTitle = "";          // 🏷️ Título Personalizado (Vacío = Detección Automática)
input int      InpTargetMagic = 0;           // 🤖 Magic Number (0 = Detección Automática)
input double   InpManualCapital = 0.0;       // 💵 Capital Inicial Personalizado (0.0 = Autocalcular)
input int      InpPanelX = 460;              // 📍 Posición X en Pantalla
input int      InpPanelY = 60;               // 📍 Posición Y en Pantalla

// --- ESTADOS GLOBALES INTERACTIVOS ---
int g_selectedPeriodMode = 0; // 0: Todo, 1: Este Mes, 2: Últimos 30 Días, 3: Esta Semana, 4: Hoy
int g_detectedMagic = 0;
string g_botName = "";

// --- ESTRUCTURA DE RESULTADOS ---
struct StatsReport {
    datetime periodStart;
    datetime periodEnd;
    double capitalInicialPeriodo;
    double netProfit;
    double realBalance;
    int totalDeals;
    int winTrades;
    int lossTrades;
    double winRate;
    double maxDD;
    double maxDDPct;
    double profitFactor;
    double avgWin;
    double avgLoss;
};

// --- LIMPIEZA DE OBJETOS ---
void CleanupDashboard() {
    ObjectsDeleteAll(0, "MaikoSmart_");
    ChartRedraw(0);
}

// --- CREACIÓN DE OBJETOS DIBUJO ---
void CreateBackground(string name, int x, int y, int w, int h, color bgCol, color borderCol = clrNONE) {
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    if(borderCol != clrNONE) {
        ObjectSetInteger(0, name, OBJPROP_COLOR, borderCol);
    }
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 20);
}

void CreateLabel(string name, string text, int x, int y, int size, color col, bool bold=false) {
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetString(0, name, OBJPROP_FONT, bold ? "Segoe UI Bold" : "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 21);
}

void CreateButton(string name, string text, int x, int y, int w, int h, color bgCol, color textCol, bool isActive=false) {
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, isActive ? C'168,85,247' : bgCol);
    ObjectSetInteger(0, name, OBJPROP_COLOR, textCol);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_STATE, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 22);
}

// --- AUTODETECCIÓN INTELIGENTE ---
void AutoDetectBotInfo() {
    g_detectedMagic = InpTargetMagic;
    g_botName = InpCustomTitle;

    HistorySelect(0, TimeCurrent());
    int totalDeals = HistoryDealsTotal();

    if(g_detectedMagic == 0) {
        for(int i = totalDeals - 1; i >= 0; i--) {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket == 0) continue;
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            if(symbol == _Symbol) {
                long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
                if(magic > 0) {
                    g_detectedMagic = (int)magic;
                    break;
                }
            }
        }
    }

    if(g_botName == "") {
        if(g_detectedMagic == 111111 || g_detectedMagic == 888888) g_botName = "MAIKO PRO GOLD DEMO";
        else if(g_detectedMagic == 111222) g_botName = "MAIKO PRO GOLD REAL";
        else if(g_detectedMagic == 111333 || g_detectedMagic == 111335) g_botName = "MAIKO PRO GOLD CENT";
        else if(g_detectedMagic == 222333) g_botName = "MAIKO PRO BTC";
        else if(g_detectedMagic == 333444) g_botName = "MAIKO EURO PRECISION";
        else if(g_detectedMagic == 444555) g_botName = "MAIKO YEN GHOST";
        else if(g_detectedMagic > 0)       g_botName = StringFormat("MAIKO BOT (Magic: %d)", g_detectedMagic);
        else                               g_botName = StringFormat("MAIKO BOT (%s)", _Symbol);
    }
}

// --- CÁLCULO DE ESTADÍSTICAS AVANZADAS (CON PROFIT FACTOR Y AVG WIN/LOSS) ---
void CalculateStats(int mode, StatsReport &rep) {
    HistorySelect(0, TimeCurrent());
    int totalDeals = HistoryDealsTotal();

    datetime now = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(now, dt);

    datetime filterStart = 0;

    if(mode == 1) { // Este Mes
        dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
        filterStart = StructToTime(dt);
    } else if(mode == 2) { // Últimos 30 Días
        filterStart = now - (30 * 24 * 3600);
    } else if(mode == 3) { // Esta Semana
        datetime monday = now - (dt.day_of_week > 0 ? (dt.day_of_week - 1) : 6) * 86400;
        MqlDateTime dtM; TimeToStruct(monday, dtM);
        dtM.hour = 0; dtM.min = 0; dtM.sec = 0;
        filterStart = StructToTime(dtM);
    } else if(mode == 4) { // Hoy
        dt.hour = 0; dt.min = 0; dt.sec = 0;
        filterStart = StructToTime(dt);
    }

    double netProfit = 0;
    double grossProfit = 0;
    double grossLoss = 0;
    int botDealsCount = 0;
    int winTrades = 0;
    int lossTrades = 0;
    datetime firstTrade = 0;
    datetime lastTrade = 0;

    double currentRealBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    for(int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket == 0) continue;

        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        datetime time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        double comm = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);

        bool isTarget = (g_detectedMagic > 0) ? (magic == g_detectedMagic) : (symbol == _Symbol);
        if(!isTarget) continue;

        double net = profit + comm + swap;

        if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) {
            if(time >= filterStart) {
                botDealsCount++;
                netProfit += net;
                if(net > 0) {
                    winTrades++;
                    grossProfit += net;
                } else if(net < 0) {
                    lossTrades++;
                    grossLoss += MathAbs(net);
                }

                if(firstTrade == 0 || time < firstTrade) firstTrade = time;
                if(time > lastTrade) lastTrade = time;
            }
        }
    }

    double capitalInicial = (InpManualCapital > 0.0) ? InpManualCapital : (currentRealBalance - netProfit);

    // Calcular Drawdown Peak-to-Trough
    double runningBal = capitalInicial;
    double peak = runningBal;
    double maxDD = 0.0;

    for(int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket == 0) continue;

        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        datetime time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        double comm = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);

        bool isTarget = (g_detectedMagic > 0) ? (magic == g_detectedMagic) : (symbol == _Symbol);
        if(!isTarget) continue;

        if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) {
            if(time >= filterStart) {
                double net = profit + comm + swap;
                runningBal += net;
                if(runningBal > peak) {
                    peak = runningBal;
                } else {
                    double dd = peak - runningBal;
                    if(dd > maxDD) maxDD = dd;
                }
            }
        }
    }

    rep.periodStart = (firstTrade > 0) ? firstTrade : (filterStart > 0 ? filterStart : now);
    rep.periodEnd = (lastTrade > 0) ? lastTrade : now;
    rep.capitalInicialPeriodo = capitalInicial;
    rep.netProfit = netProfit;
    rep.realBalance = currentRealBalance;
    rep.totalDeals = botDealsCount;
    rep.winTrades = winTrades;
    rep.lossTrades = lossTrades;
    rep.winRate = (botDealsCount > 0) ? ((double)winTrades / botDealsCount) * 100.0 : 0.0;
    rep.maxDD = maxDD;
    rep.maxDDPct = (peak > 0) ? (maxDD / peak) * 100.0 : 0.0;
    rep.profitFactor = (grossLoss > 0) ? (grossProfit / grossLoss) : (grossProfit > 0 ? 99.9 : 0.0);
    rep.avgWin = (winTrades > 0) ? (grossProfit / winTrades) : 0.0;
    rep.avgLoss = (lossTrades > 0) ? (grossLoss / lossTrades) : 0.0;
}

// --- DIBUJAR PANEL COMPLETO ---
void RenderDashboard(int mode) {
    CleanupDashboard();

    StatsReport rep;
    CalculateStats(mode, rep);

    int width = 540;
    int height = 460;
    int px = InpPanelX;
    int py = InpPanelY;

    color panelBG = C'12,14,24';
    color headerBorder = C'245,158,11';
    color textColor = clrWhite;
    color mutedColor = C'160,170,190';
    color pnlColor = (rep.netProfit >= 0) ? C'34,197,94' : C'239,68,68';
    string curr = AccountInfoString(ACCOUNT_CURRENCY);

    // Fondo y marco
    CreateBackground("MaikoSmart_BG", px, py, width, height, panelBG, C'40,45,65');
    CreateBackground("MaikoSmart_HeaderLine", px, py + 48, width, 2, headerBorder);

    // Título principal
    string titleText = StringFormat("🤖 %s  -  REPORTE SMART", g_botName);
    CreateLabel("MaikoSmart_Title", titleText, px + 20, py + 14, 11, headerBorder, true);

    // Botón de cerrar
    CreateButton("MaikoSmart_CloseBtn", "❌ Cerrar", px + width - 95, py + 10, 80, 26, C'185,28,28', clrWhite);

    // --- BARRA DE BOTONES INTERACTIVOS DE FILTRO DE TIEMPO ---
    int btnY = py + 60;
    int btnW = 96;
    int btnH = 24;
    int btnGap = 6;
    int btnStartX = px + 18;

    CreateButton("MaikoSmart_BtnP0", "Todo el Historial", btnStartX, btnY, btnW, btnH, C'30,35,55', clrWhite, mode == 0);
    CreateButton("MaikoSmart_BtnP1", "Este Mes", btnStartX + (btnW + btnGap), btnY, btnW, btnH, C'30,35,55', clrWhite, mode == 1);
    CreateButton("MaikoSmart_BtnP2", "Últimos 30D", btnStartX + (btnW + btnGap)*2, btnY, btnW, btnH, C'30,35,55', clrWhite, mode == 2);
    CreateButton("MaikoSmart_BtnP3", "Esta Semana", btnStartX + (btnW + btnGap)*3, btnY, btnW, btnH, C'30,35,55', clrWhite, mode == 3);
    CreateButton("MaikoSmart_BtnP4", "Hoy", btnStartX + (btnW + btnGap)*4, btnY, btnW, btnH, C'30,35,55', clrWhite, mode == 4);

    CreateBackground("MaikoSmart_FilterLine", px + 15, py + 95, width - 30, 1, C'40,45,65');

    // --- FILAS DE DATOS ---
    int rowY = py + 108;
    int rowStep = 34;

    // Fila 1: Periodo Analizado
    CreateLabel("MaikoSmart_L1", "Periodo Analizado:", px + 25, rowY, 10, mutedColor);
    string dateRange = StringFormat("%s  al  %s", TimeToString(rep.periodStart, TIME_DATE), TimeToString(rep.periodEnd, TIME_DATE));
    CreateLabel("MaikoSmart_V1", dateRange, px + 230, rowY, 10, textColor, true);

    // Fila 2: Balance Inicio de Periodo
    rowY += rowStep;
    CreateLabel("MaikoSmart_L2", "Balance Inicio del Periodo:", px + 25, rowY, 10, mutedColor);
    CreateLabel("MaikoSmart_V2", StringFormat("$ %.2f %s", rep.capitalInicialPeriodo, curr), px + 230, rowY, 10, textColor, true);

    // Fila 3: Beneficio Neto Generado
    rowY += rowStep;
    CreateLabel("MaikoSmart_L3", "Beneficio Neto Generado:", px + 25, rowY, 10, mutedColor);
    string sign = (rep.netProfit >= 0) ? "+" : "";
    CreateLabel("MaikoSmart_V3", StringFormat("%s$ %.2f %s", sign, rep.netProfit, curr), px + 230, rowY, 11, pnlColor, true);

    // Fila 4: Balance Real Actual MT5
    rowY += rowStep;
    CreateLabel("MaikoSmart_L4", "Balance Real Actual MT5:", px + 25, rowY, 10, mutedColor);
    CreateLabel("MaikoSmart_V4", StringFormat("$ %.2f %s", rep.realBalance, curr), px + 230, rowY, 12, headerBorder, true);

    // Fila 5: Profit Factor & WinRate
    rowY += rowStep;
    CreateLabel("MaikoSmart_L5", "Profit Factor / WinRate:", px + 25, rowY, 10, mutedColor);
    color pfCol = (rep.profitFactor >= 1.5) ? C'34,197,94' : (rep.profitFactor >= 1.1 ? C'245,158,11' : C'239,68,68');
    CreateLabel("MaikoSmart_V5", StringFormat("PF: %.2f  |  WinRate: %.1f%% (%d trades)", rep.profitFactor, rep.winRate, rep.totalDeals), px + 230, rowY, 10, pfCol, true);

    // Fila 6: Ganancia Media vs Pérdida Media
    rowY += rowStep;
    CreateLabel("MaikoSmart_L6", "Ganancia Media / Pérdida Media:", px + 25, rowY, 10, mutedColor);
    CreateLabel("MaikoSmart_V6", StringFormat("🟢 +$%.2f  /  🔴 -$%.2f", rep.avgWin, rep.avgLoss), px + 230, rowY, 10, textColor, true);

    // Fila 7: Ganadoras vs Perdedoras
    rowY += rowStep;
    CreateLabel("MaikoSmart_L7", "Ganadoras vs Perdedoras:", px + 25, rowY, 10, mutedColor);
    CreateLabel("MaikoSmart_V7", StringFormat("🟢 %d win  /  🔴 %d loss", rep.winTrades, rep.lossTrades), px + 230, rowY, 10, textColor, true);

    // Fila 8: Drawdown Máximo del Periodo
    rowY += rowStep;
    CreateLabel("MaikoSmart_L8", "Drawdown Máximo del Periodo:", px + 25, rowY, 10, mutedColor);
    CreateLabel("MaikoSmart_V8", StringFormat("$ %.2f (%.1f%%)", rep.maxDD, rep.maxDDPct), px + 230, rowY, 10, C'239,68,68', true);

    // Pie de página
    CreateBackground("MaikoSmart_FooterLine", px, py + 425, width, 1, C'40,45,65');
    CreateLabel("MaikoSmart_FooterText", "* Haz clic en los botones superiores para filtrar el tiempo o en 'Cerrar' para quitar.", px + 20, py + 435, 8, C'100,110,130');

    ChartRedraw(0);
}

// --- FUNCIÓN PRINCIPAL ---
void OnStart() {
    AutoDetectBotInfo();
    RenderDashboard(g_selectedPeriodMode);

    // Event Loop para detectar clics interactivos en los botones
    while(!IsStopped()) {
        if(ObjectGetInteger(0, "MaikoSmart_CloseBtn", OBJPROP_STATE) == true) {
            CleanupDashboard();
            break;
        }

        if(ObjectGetInteger(0, "MaikoSmart_BtnP0", OBJPROP_STATE) == true) {
            ObjectSetInteger(0, "MaikoSmart_BtnP0", OBJPROP_STATE, false);
            g_selectedPeriodMode = 0;
            RenderDashboard(0);
        }
        if(ObjectGetInteger(0, "MaikoSmart_BtnP1", OBJPROP_STATE) == true) {
            ObjectSetInteger(0, "MaikoSmart_BtnP1", OBJPROP_STATE, false);
            g_selectedPeriodMode = 1;
            RenderDashboard(1);
        }
        if(ObjectGetInteger(0, "MaikoSmart_BtnP2", OBJPROP_STATE) == true) {
            ObjectSetInteger(0, "MaikoSmart_BtnP2", OBJPROP_STATE, false);
            g_selectedPeriodMode = 2;
            RenderDashboard(2);
        }
        if(ObjectGetInteger(0, "MaikoSmart_BtnP3", OBJPROP_STATE) == true) {
            ObjectSetInteger(0, "MaikoSmart_BtnP3", OBJPROP_STATE, false);
            g_selectedPeriodMode = 3;
            RenderDashboard(3);
        }
        if(ObjectGetInteger(0, "MaikoSmart_BtnP4", OBJPROP_STATE) == true) {
            ObjectSetInteger(0, "MaikoSmart_BtnP4", OBJPROP_STATE, false);
            g_selectedPeriodMode = 4;
            RenderDashboard(4);
        }

        Sleep(100);
    }
}
`;

const cleanerCode = `#property copyright "KopyTrading AI"
#property version   "2.50"
#property script_show_inputs

void OnStart() {
    ObjectsDeleteAll(0, "MaikoSmart_");
    ObjectsDeleteAll(0, "MaikoDash_");
    ChartRedraw(0);
    Print("Paneles Maiko eliminados del gráfico.");
}
`;

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

async function main() {
    console.log("=== Desplegando v2.50 con Profit Factor y Ganancia/Pérdida Media ===");

    if (!fs.existsSync(basePath)) return;

    const folders = fs.readdirSync(basePath).filter(f => {
        const full = path.join(basePath, f);
        return fs.statSync(full).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help';
    });

    for (const folder of folders) {
        const scriptDir = path.join(basePath, folder, "MQL5", "Scripts");
        if (!fs.existsSync(scriptDir)) continue;

        const mq5Path = path.join(scriptDir, "ExportMaikoHistory.mq5");
        fs.writeFileSync(mq5Path, scriptCode, 'utf8');

        if (fs.existsSync(editorPath)) {
            try {
                execSync(`"${editorPath}" /compile:"${mq5Path}" /log`);
                console.log(`Compilado v2.50 en ${folder}`);
            } catch (err) {}
        }
    }
}

main().catch(console.error);
