//+------------------------------------------------------------------+
//|   MAIKO AI CONSENSUS BOT v1.0                                    |
//|   Copyright 2026, kopytrading.com                                |
//|   https://kopytrading.com                                        |
//|                                                                  |
//|   ESTRATEGIA: Consenso Multi-Fuente REAL                         |
//|   - Binance Order Book Imbalance (presión compradora/vendedora)  |
//|   - Fear & Greed Index (alternative.me - GRATIS)                 |
//|   - EMA 20/50/200 en el gráfico actual                           |
//|   - RSI 14 como filtro de sobrecompra/sobreventa                 |
//|                                                                  |
//|   MEJORAS SOBRE EL BOT ANALIZADO:                                |
//|   ✅ SL/TP REALES en el broker (no virtuales)                    |
//|   ✅ Break-Even automático con profit asegurado                  |
//|   ✅ Trailing Stop dinámico                                       |
//|   ✅ Lotaje por % de riesgo real                                  |
//|   ✅ Kill Switch de emergencia                                    |
//|   ✅ Sistema de Licencias (kopytrading.com)                      |
//|   ✅ Telegram con alertas formateadas                            |
//|   ✅ APIs externas gratuitas y verificadas                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, kopytrading.com"
#property link      "https://kopytrading.com"
#property version   "1.00"
#property description "MAIKO AI Consensus Bot - kopytrading.com"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>

CTrade        trade;
CSymbolInfo   symbolInfo;
CPositionInfo positionInfo;

//=================================================================
// ENUMS
//=================================================================
enum ENUM_EXEC_MODE {
    MODE_FULL_AUTO = 0, // FULL AUTO (opera automáticamente)
    MODE_SEMI_AUTO = 1  // SEMI AUTO (solo alerta en Telegram)
};

//=================================================================
// PARAMETROS DE ENTRADA (VISIBLES EN MT5)
//=================================================================

input group "━━━━━━ 🔑 LICENCIA KOPYTRADING ━━━━━━"
input string  InpLicenseKey       = "KOPY-XXXX-XXXX-XXXX"; // 🔑 Clave de Licencia

input group "━━━━━━ 📱 TELEGRAM ━━━━━━"
input bool    InpUseTelegram      = true;                     // 📱 Activar Alertas Telegram
input string  InpTelegramToken    = "TU_TOKEN_AQUI";          // 🤖 Token del Bot Telegram
input string  InpTelegramChatID   = "TU_CHAT_ID_AQUI";        // 👤 Chat ID o Canal

input group "━━━━━━ ⚙️ MODO Y EJECUCIÓN ━━━━━━"
input ENUM_EXEC_MODE InpExecMode  = MODE_FULL_AUTO;  // ⚙️ Modo de ejecución
input int     InpMagicNumber      = 202626;          // 🔮 Magic Number único del bot

input group "━━━━━━ 💰 GESTIÓN DE RIESGO ━━━━━━"
input bool    InpUseFixedLot      = false;   // 🔒 Usar lotaje fijo (False = % automático)
input double  InpFixedLot         = 0.01;    // 📦 Lotaje fijo (si arriba = True)
input double  InpRiskPercent      = 1.5;     // ⚖️ Riesgo por operación (% del balance)
input double  InpMaxSpreadPoints  = 40.0;    // 🚫 Spread máximo (puntos)
input int     InpSlippagePoints   = 15;      // 🚫 Deslizamiento máximo (puntos)
input int     InpMaxTradesOpen    = 1;       // 🔢 Máximo posiciones simultáneas

input group "━━━━━━ 🧠 ESTRATEGIA CONSENSO ━━━━━━"
input int     InpMinConsensusScore = 60;     // 🎯 Consenso mínimo para operar (0-100)
input int     InpSignalCooldownMin = 5;      // ⏱️ Espera mínima entre señales (minutos)
input bool    InpUseBinanceOB      = true;   // 🐋 Usar Binance Order Book (requiere WebRequest)
input bool    InpUseFearGreed      = true;   // 😨 Usar Fear and Greed Index (requiere WebRequest)
input int     InpFG_MinBuy         = 25;     // 😨 F&G mínimo para compras (por debajo = mucho miedo)
input int     InpFG_MaxSell        = 75;     // 🤑 F&G máximo para ventas (por encima = euforia)

input group "━━━━━━ 🛡️ SL / TP / BREAK-EVEN / TRAILING ━━━━━━"
input int     InpSL_Points         = 400;    // 🛑 Stop Loss (puntos) - SE PONE EN EL BROKER
input int     InpTP_Points         = 800;    // 🎯 Take Profit (puntos) - SE PONE EN EL BROKER
input bool    InpUseBreakEven      = true;   // 🛡️ Activar Break-Even automático
input int     InpBE_TriggerPoints  = 150;    // 🛡️ Puntos a favor para activar Break-Even
input int     InpBE_LockPoints     = 20;     // 🔒 Puntos de ganancia mínima a bloquear
input bool    InpUseTrailing       = true;   // 📈 Activar Trailing Stop
input int     InpTrailingStart     = 200;    // 📈 Puntos a favor para activar Trailing
input int     InpTrailingStep      = 50;     // 📈 Paso del Trailing Stop (puntos)

input group "━━━━━━ ⏰ HORARIOS ━━━━━━"
input int     InpHoraInicio        = 3;      // 🔔 Hora de inicio (hora broker)
input int     InpHoraFin           = 22;     // 🔕 Hora de fin
input bool    InpNoViernes         = true;   // 🚫 No operar viernes noche (>=21h)

input group "━━━━━━ 🚨 KILL SWITCH (EMERGENCIA) ━━━━━━"
input bool    InpKillSwitch        = false;  // ☠️ ACTIVAR = Cierra todo y para el bot

//=================================================================
// VARIABLES GLOBALES
//=================================================================
string   g_symbol;
double   g_point;
bool     g_botActivo     = true;
int      g_lastFearGreed = 50;
datetime g_lastFGUpdate  = 0;
datetime g_lastSignalTime = 0;
double   g_peakBalance   = 0;
double   g_maxDrawdown   = 0;
int      g_totalTrades   = 0;
int      g_winTrades     = 0;

//=================================================================
// INIT
//=================================================================
int OnInit() {
    if(InpKillSwitch) {
        CloseAllPositions();
        Alert("☠️ KILL SWITCH: Todo cerrado.");
        return INIT_FAILED;
    }
    if(!CheckLicense(InpLicenseKey)) {
        Alert("❌ Licencia inválida. Visita kopytrading.com");
        SendTelegramMsg("❌ *LICENCIA INVÁLIDA*\nVisita kopytrading.com");
        return INIT_FAILED;
    }

    g_symbol = _Symbol;
    symbolInfo.Name(g_symbol);
    symbolInfo.RefreshRates();
    g_point = symbolInfo.Point();
    g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippagePoints);

    EventSetTimer(30);
    g_lastFearGreed = (InpUseFearGreed && !MQLInfoInteger(MQL_TESTER)) ? GetFearAndGreedIndex() : 50;

    string msg = "✅ *MAIKO AI CONSENSUS BOT Iniciado*\n" +
                 "• Par: " + g_symbol + "\n" +
                 "• Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2) + "\n" +
                 "• Riesgo/Trade: " + DoubleToString(InpRiskPercent,1) + "%\n" +
                 "• Fear & Greed: " + IntegerToString(g_lastFearGreed) + "/100\n" +
                 "• SL REAL: " + IntegerToString(InpSL_Points) + "p | TP REAL: " + IntegerToString(InpTP_Points) + "p\n" +
                 "• Order Book Binance: " + (InpUseBinanceOB ? "ON" : "OFF") + "\n" +
                 "• Modo: " + EnumToString(InpExecMode);
    SendTelegramMsg(msg);
    Print(msg);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    EventKillTimer();
    SendTelegramMsg("🔴 *Bot MAIKO AI Detenido*\n• Trades: " + IntegerToString(g_totalTrades) + "\n• Max Drawdown: " + DoubleToString(g_maxDrawdown,2) + "%");
}

//=================================================================
// TICK PRINCIPAL
//=================================================================
void OnTick() {
    if(!g_botActivo) return;
    if(InpKillSwitch) { CloseAllPositions(); g_botActivo = false; return; }

    symbolInfo.RefreshRates();
    if(!IsOperatingHour()) return;

    ManagePositions();
    UpdateDrawdown();

    if(CountOpenPositions() >= InpMaxTradesOpen) return;
    if((TimeCurrent() - g_lastSignalTime) < (InpSignalCooldownMin * 60)) return;

    double spreadNow = (symbolInfo.Ask() - symbolInfo.Bid()) / g_point;
    if(spreadNow > InpMaxSpreadPoints) return;

    int score = 0, signal = 0;
    CalculateConsensus(score, signal);

    if(signal != 0 && score >= InpMinConsensusScore) {
        g_lastSignalTime = TimeCurrent();
        if(InpExecMode == MODE_FULL_AUTO) {
            ExecuteTrade(signal, score);
        } else {
            SendTelegramMsg("⚠️ *SEÑAL SEMI-AUTO*\n• " + g_symbol +
                           "\n• " + (signal==1?"🟢 COMPRA":"🔴 VENTA") +
                           "\n• Consenso: " + IntegerToString(score) + "/100");
        }
    }
}

void OnTimer() {
    if((TimeCurrent() - g_lastFGUpdate) > 900 && !MQLInfoInteger(MQL_TESTER)) {
        g_lastFearGreed = InpUseFearGreed ? GetFearAndGreedIndex() : 50;
        g_lastFGUpdate  = TimeCurrent();
    }
    ManagePositions();
}

//=================================================================
// CONSENSO MULTI-FUENTE
//=================================================================
void CalculateConsensus(int &outScore, int &outSignal) {
    outScore = 0; outSignal = 0;

    // FUENTE 1: Binance Order Book (35 puntos)
    double buyPres = 1, sellPres = 1;
    if(InpUseBinanceOB && !MQLInfoInteger(MQL_TESTER)) {
        GetBinanceOrderBookImbalance(buyPres, sellPres);
    }

    // FUENTE 2: Fear & Greed (25 puntos)
    int fg = g_lastFearGreed;

    // FUENTE 3: EMA Trend M5 (25 puntos)
    double ema20h = iMA(g_symbol,PERIOD_M5,20,0,MODE_EMA,PRICE_CLOSE);
    double ema50h = iMA(g_symbol,PERIOD_M5,50,0,MODE_EMA,PRICE_CLOSE);
    double ema200h= iMA(g_symbol,PERIOD_M5,200,0,MODE_EMA,PRICE_CLOSE);
    double e20[1],e50[1],e200[1];
    CopyBuffer(ema20h,0,0,1,e20);
    CopyBuffer(ema50h,0,0,1,e50);
    CopyBuffer(ema200h,0,0,1,e200);
    IndicatorRelease(ema20h); IndicatorRelease(ema50h); IndicatorRelease(ema200h);
    double price = symbolInfo.Bid();
    bool tBull = (e20[0]>e50[0]) && (e50[0]>e200[0]) && (price>e20[0]);
    bool tBear = (e20[0]<e50[0]) && (e50[0]<e200[0]) && (price<e20[0]);

    // FUENTE 4: RSI (15 puntos)
    double rsiH = iRSI(g_symbol,PERIOD_M5,14,PRICE_CLOSE);
    double rsi[1]; CopyBuffer(rsiH,0,0,1,rsi); IndicatorRelease(rsiH);
    bool rsiBull = (rsi[0]>30 && rsi[0]<45);
    bool rsiBear = (rsi[0]>55 && rsi[0]<70);

    // Calcular score BUY
    int buyS = 0;
    if(buyPres > sellPres*1.3) buyS += 35;
    else if(buyPres > sellPres*1.1) buyS += 20;
    if(InpUseFearGreed) {
        if(fg<=25) buyS+=25; else if(fg<=InpFG_MinBuy) buyS+=15; else if(fg>InpFG_MaxSell) buyS-=15;
    } else buyS+=12;
    if(tBull) buyS+=25; else if(tBear) buyS-=10;
    if(rsiBull) buyS+=15; else if(rsiBear) buyS-=5;

    // Calcular score SELL
    int selS = 0;
    if(sellPres > buyPres*1.3) selS += 35;
    else if(sellPres > buyPres*1.1) selS += 20;
    if(InpUseFearGreed) {
        if(fg>=75) selS+=25; else if(fg>=InpFG_MaxSell) selS+=15; else if(fg<InpFG_MinBuy) selS-=15;
    } else selS+=12;
    if(tBear) selS+=25; else if(tBull) selS-=10;
    if(rsiBear) selS+=15; else if(rsiBull) selS-=5;

    buyS = MathMax(0, MathMin(100, buyS));
    selS = MathMax(0, MathMin(100, selS));

    Print("🧠 Consenso | BUY:", buyS, " SELL:", selS, " F&G:", fg,
          " Trend:", tBull?"BULL":tBear?"BEAR":"NEUTRO", " RSI:", DoubleToString(rsi[0],1),
          " OB:", DoubleToString(buyPres,0), "/", DoubleToString(sellPres,0));

    if(buyS > selS && buyS >= InpMinConsensusScore) { outSignal=1;  outScore=buyS; }
    else if(selS > buyS && selS >= InpMinConsensusScore) { outSignal=-1; outScore=selS; }
}

//=================================================================
// BINANCE ORDER BOOK (API GRATIS, SIN CLAVE)
// Endpoint: https://www.binance.com/api/v3/depth?symbol=BTCUSDT&limit=20
//=================================================================
void GetBinanceOrderBookImbalance(double &buyVol, double &sellVol) {
    buyVol=1; sellVol=1;
    string url = "https://www.binance.com/api/v3/depth?symbol=BTCUSDT&limit=20";
    char post[], result[];
    string headers = "User-Agent: Mozilla/5.0\r\n";
    string rHeaders;
    ResetLastError();
    int res = WebRequest("GET", url, headers, 5000, post, result, rHeaders);
    if(res != 200) { Print("Binance OB error HTTP:", res, " LastErr:", GetLastError()); return; }
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    buyVol  = SumOBVolume(json, "bids");
    sellVol = SumOBVolume(json, "asks");
}

double SumOBVolume(const string &json, const string &side) {
    double total = 0;
    int pos = StringFind(json, "\"" + side + "\":");
    if(pos < 0) return 1;
    pos = StringFind(json, "[", pos);
    if(pos < 0) return 1;
    int depth=0, count=0;
    for(int i=pos; i<StringLen(json) && count<20; i++) {
        ushort c = StringGetCharacter(json, i);
        if(c=='[') depth++;
        if(c==']') { depth--; if(depth==0) break; }
        // Cuando depth==2 y encontramos coma, el siguiente string es el volumen
        if(c==',' && depth==2) {
            int q1=StringFind(json,"\"",i); if(q1<0) continue;
            int q2=StringFind(json,"\"",q1+1); if(q2<0) continue;
            total += StringToDouble(StringSubstr(json,q1+1,q2-q1-1));
            count++;
        }
    }
    return total > 0 ? total : 1;
}

//=================================================================
// FEAR & GREED INDEX (alternative.me - GRATIS, SIN CLAVE)
// Endpoint: https://api.alternative.me/fng/?limit=1&format=json
//=================================================================
int GetFearAndGreedIndex() {
    char post[], result[];
    string headers = "User-Agent: Mozilla/5.0\r\n";
    string rHeaders;
    ResetLastError();
    int res = WebRequest("GET","https://api.alternative.me/fng/?limit=1&format=json",headers,5000,post,result,rHeaders);
    if(res != 200) { Print("F&G API error:", res); return 50; }
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    int pos = StringFind(json, "\"value\":\"");
    if(pos < 0) return 50;
    pos += 9;
    int end = StringFind(json,"\"",pos);
    if(end<=pos) return 50;
    int val = (int)StringToInteger(StringSubstr(json,pos,end-pos));
    Print("Fear & Greed: ", val, "/100");
    return MathMax(0, MathMin(100, val));
}

//=================================================================
// EJECUTAR TRADE (SL/TP REALES EN EL BROKER DESDE EL PRIMER TICK)
//=================================================================
void ExecuteTrade(int direction, int score) {
    symbolInfo.RefreshRates();
    double price = (direction==1) ? symbolInfo.Ask() : symbolInfo.Bid();
    double lot   = CalculateLotSize(InpSL_Points);
    double sl, tp;

    if(direction==1) {
        sl = NormalizeDouble(price - InpSL_Points*g_point, symbolInfo.Digits());
        tp = NormalizeDouble(price + InpTP_Points*g_point, symbolInfo.Digits());
    } else {
        sl = NormalizeDouble(price + InpSL_Points*g_point, symbolInfo.Digits());
        tp = NormalizeDouble(price - InpTP_Points*g_point, symbolInfo.Digits());
    }

    bool ok = (direction==1)
        ? trade.Buy (lot, g_symbol, price, sl, tp, "MAIKO_AI_BUY")
        : trade.Sell(lot, g_symbol, price, sl, tp, "MAIKO_AI_SELL");

    if(ok) {
        g_totalTrades++;
        string msg = "🚀 *NUEVA ENTRADA - MAIKO AI*\n" +
                     "• Par: " + g_symbol + "\n" +
                     "• " + (direction==1?"🟢 COMPRA":"🔴 VENTA") + "\n" +
                     "• Lote: " + DoubleToString(lot,2) + " (Riesgo " + DoubleToString(InpRiskPercent,1) + "%)\n" +
                     "• Precio: " + DoubleToString(price,symbolInfo.Digits()) + "\n" +
                     "• ✅ SL REAL: " + DoubleToString(sl,symbolInfo.Digits()) + "\n" +
                     "• ✅ TP REAL: " + DoubleToString(tp,symbolInfo.Digits()) + "\n" +
                     "• Consenso: " + IntegerToString(score) + "/100\n" +
                     "• Fear & Greed: " + IntegerToString(g_lastFearGreed) + "/100";
        SendTelegramMsg(msg);
        Print(msg);
    } else {
        string err = "❌ Error ejecución: " + trade.ResultRetcodeDescription();
        SendTelegramMsg("❌ *Error*\n" + err);
        Print(err);
    }
}

//=================================================================
// GESTIÓN DE POSICIONES (BREAK-EVEN + TRAILING)
//=================================================================
void ManagePositions() {
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(!positionInfo.SelectByIndex(i)) continue;
        if(positionInfo.Symbol() != g_symbol || positionInfo.Magic() != InpMagicNumber) continue;

        double openP   = positionInfo.PriceOpen();
        double curSL   = positionInfo.StopLoss();
        double curTP   = positionInfo.TakeProfit();
        ulong  ticket  = positionInfo.Ticket();
        bool   isBuy   = (positionInfo.PositionType()==POSITION_TYPE_BUY);
        symbolInfo.RefreshRates();
        double curP    = isBuy ? symbolInfo.Bid() : symbolInfo.Ask();
        double ptsProfit = isBuy ? (curP-openP)/g_point : (openP-curP)/g_point;

        // Break-Even
        if(InpUseBreakEven && ptsProfit >= InpBE_TriggerPoints) {
            double newSL = NormalizeDouble(
                isBuy ? openP + InpBE_LockPoints*g_point : openP - InpBE_LockPoints*g_point,
                symbolInfo.Digits());
            bool move = isBuy ? (newSL>curSL) : (curSL==0 || newSL<curSL);
            if(move && trade.PositionModify(ticket, newSL, curTP)) {
                SendTelegramMsg("🛡️ *BREAK-EVEN ACTIVADO*\n• " + g_symbol + "\n• Ticket: " +
                               IntegerToString(ticket) + "\n• Nuevo SL: " +
                               DoubleToString(newSL,symbolInfo.Digits()) + "\n• Bloqueados: +" +
                               IntegerToString(InpBE_LockPoints) + " puntos");
            }
        }

        // Trailing Stop
        if(InpUseTrailing && ptsProfit >= InpTrailingStart) {
            double newSL = NormalizeDouble(
                isBuy ? curP - InpTrailingStep*g_point : curP + InpTrailingStep*g_point,
                symbolInfo.Digits());
            bool move = isBuy ? (newSL>curSL) : (curSL==0 || newSL<curSL);
            if(move) trade.PositionModify(ticket, newSL, curTP);
        }
    }
}

//=================================================================
// CÁLCULO DE LOTE POR % DE RIESGO
//=================================================================
double CalculateLotSize(int slPts) {
    if(InpUseFixedLot) return NormLot(InpFixedLot);
    double risk  = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPercent/100.0);
    double tv    = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE);
    double ts    = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tv==0||ts==0) return NormLot(InpFixedLot);
    double lplot = slPts * (tv/(ts/g_point));
    if(lplot<=0) return NormLot(InpFixedLot);
    return NormLot(risk/lplot);
}

double NormLot(double lot) {
    double mn=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_MIN);
    double mx=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_MAX);
    double st=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_STEP);
    return MathMax(mn, MathMin(mx, MathFloor(lot/st)*st));
}

//=================================================================
// CERRAR TODAS LAS POSICIONES
//=================================================================
void CloseAllPositions() {
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(positionInfo.SelectByIndex(i) && positionInfo.Magic()==InpMagicNumber)
            trade.PositionClose(positionInfo.Ticket());
    }
    SendTelegramMsg("☠️ *KILL SWITCH*: Todas las posiciones de " + g_symbol + " cerradas.");
}

int CountOpenPositions() {
    int n=0;
    for(int i=0;i<PositionsTotal();i++)
        if(positionInfo.SelectByIndex(i) && positionInfo.Symbol()==g_symbol && positionInfo.Magic()==InpMagicNumber) n++;
    return n;
}

bool IsOperatingHour() {
    MqlDateTime dt; TimeToStruct(TimeTradeServer(),dt);
    if(dt.day_of_week==0||dt.day_of_week==6) return false;
    if(InpNoViernes && dt.day_of_week==5 && dt.hour>=21) return false;
    return (dt.hour>=InpHoraInicio && dt.hour<InpHoraFin);
}

void UpdateDrawdown() {
    double eq=AccountInfoDouble(ACCOUNT_EQUITY);
    if(eq>g_peakBalance) g_peakBalance=eq;
    double dd=((g_peakBalance-eq)/g_peakBalance)*100.0;
    if(dd>g_maxDrawdown) {
        g_maxDrawdown=dd;
        if(dd>10.0)
            SendTelegramMsg("⚠️ *ALERTA DRAWDOWN*\n• Drawdown: "+DoubleToString(dd,2)+"%\n• Máximo: "+DoubleToString(g_maxDrawdown,2)+"%");
    }
}

//=================================================================
// LICENCIAS (kopytrading.com)
// Para activar la verificación online:
// 1. Crea un endpoint en kopytrading.com/api/verify
// 2. El endpoint debe recibir ?key=...&account=...
// 3. Debe devolver JSON: {"valid":true} o {"valid":false}
// 4. Descomenta el bloque WebRequest y comenta el "return true"
//=================================================================
bool CheckLicense(const string key) {
    if(key==""||StringLen(key)<10) return false;
    if(StringFind(key,"KOPY-")!=0) return false;
    // --- VERIFICACIÓN ONLINE (descomentar en producción) ---
    /*
    if(MQLInfoInteger(MQL_TESTER)) return true;
    string url = "https://kopytrading.com/api/verify?key="+key+"&account="+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    char post[],result[]; string rH;
    int res = WebRequest("GET",url,"",8000,post,result,rH);
    if(res==200) { string r=CharArrayToString(result); return StringFind(r,"\"valid\":true")>=0; }
    return false;
    */
    return true; // MODO DEMO - cambiar en producción
}

//=================================================================
// TELEGRAM
// IMPORTANTE: Añadir https://api.telegram.org en
// MT5 > Herramientas > Opciones > Expert Advisors > Permitir WebRequest
//=================================================================
void SendTelegramMsg(const string message) {
    if(!InpUseTelegram || InpTelegramToken=="" || InpTelegramChatID=="") return;
    if(MQLInfoInteger(MQL_TESTER)) return;
    string safeMsg = message;
    StringReplace(safeMsg,"&","%26");
    string post_str = "chat_id=" + InpTelegramChatID + "&text=" + safeMsg + "&parse_mode=Markdown";
    char post[], result[];
    StringToCharArray(post_str, post, 0, StringLen(post_str), CP_UTF8);
    string rH;
    int res = WebRequest("POST","https://api.telegram.org/bot"+InpTelegramToken+"/sendMessage",
                        "Content-Type: application/x-www-form-urlencoded\r\n",5000,post,result,rH);
    if(res!=200) Print("Telegram error HTTP:", res, " | Asegúrate de permitir api.telegram.org en opciones MT5");
}
