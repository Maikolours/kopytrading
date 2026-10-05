//+------------------------------------------------------------------+
//|             KOPYTRADE_USDJPY_YenNinjaGhost v3.0 TITAN           |
//|        REBOTE + RSI + FILTRO TENDENCIAL EMA 50 H1               |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "3.00"
#property strict
#property description "Yen Ninja Ghost v3.0 | TITAN YEN (USDJPY)"

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;      // Número de cuenta DEMO de MT5
input long     CuentaReal         = 0;      // Número de cuenta REAL de MT5
input string   PurchaseID         = "";     // ID de Vínculo (Copiar del Dashboard)

//--- RELOJ ---
input group "=== RELOJ DE OPERACIÓN (SESIÓN ASIÁTICA) ==="
input int      HoraInicio         = 0;      // Apertura de Tokio (hora broker)
input int      HoraFin            = 8;      // Cierre sesión asiática

//--- GESTIÓN DE RIESGO TITAN ---
input group "=== GESTIÓN DE RIESGO TITAN ==="
input double   RiskPercent        = 1.0;    // Riesgo por operación (%)
input double   LoteFijo           = 0.00;   // Ingrese valor > 0 para desactivar Risk%
input double   StopLossUSD        = 30.0;   // Protección máxima en $ (Yen es volátil)
input double   ProfitObjetivo     = 6.0;    

//--- ESTRATEGIA (NINJA MODE) ---
input group "=== ESTRATEGIA TITAN (BOLLINGER + RSI + EMA H1) ==="
input int      EMA_Filtro_Periodo = 50;     // Filtro Tendencial H1
input int      BB_Periodo         = 20;     
input double   BB_Desviacion      = 1.5;    
input int      RSI_Sobrevendido   = 40;     
input int      RSI_Sobrecomprado  = 60;     

//--- GESTIÓN DE BENEFICIO ---
input group "=== GESTIÓN DE BENEFICIO (BE & TRAILING) ==="
input double   BE_Activacion      = 1.5;    
input double   GarantiaBE         = 0.3;    
input bool     ActivarTrailing    = true;   
input int      DistanciaTrailing  = 100;    
input int      SaltoDelTrailing   = 30;     

//--- AVANZADO ---
input group "=== CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones      = 2;      
input long     MagicPrincipal     = 779933;

//--- GLOBALES SYNC ---
datetime lastPositionsSync = 0;
bool     remotePaused      = false;
CPositionInfo posInfo;

CTrade trade;
bool   licenseValid = false;
int    bbHandle     = INVALID_HANDLE;
int    rsiHandle    = INVALID_HANDLE;
int    emaHandle    = INVALID_HANDLE;

//+------------------------------------------------------------------+
bool CheckTrialAndLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("❌ LICENCIA REQUERIDA PARA REAL. Visitita kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_YNG_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("🆓 TRIAL INICIADO v3.0");
   } else firstRun = (datetime)GlobalVariableGet(gVarName);
   
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) return true;
   Alert("⏰ TRIAL EXPIRADO. Compra tu licencia en kopytrade.com");
   return false;
}

int OnInit() {
   if(!CheckTrialAndLicense()) return(INIT_FAILED);
   bbHandle  = iBands(_Symbol, _Period, BB_Periodo, 0, BB_Desviacion, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   emaHandle = iMA(_Symbol, PERIOD_H1, EMA_Filtro_Periodo, 0, MODE_EMA, PRICE_CLOSE);
   
   licenseValid = true;
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   // HUD Consola
   Print("🚀 Yen Ninja Ghost v3.0 TITAN Initialized");
   
   SyncPositions();
   return(INIT_SUCCEEDED);
}

void OnTick() {
   if(!licenseValid) return;
   
   CheckRemoteCommands();
   SyncPositions();
   
   if(remotePaused) return;
   
   GestionarIndividual();
   if(ContarPosiciones() < MaxPosiciones && EstaEnHorario()) BuscarEntrada();
}

double GetDynamicLot() {
    if(LoteFijo > 0) return LoteFijo;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if(tickVal <= 0) return 0.01;
    // Calculamos lote para que el StopLossUSD represente el Risk% si es posible
    // Pero en este bot el StopLossUSD es fijo. Calculamos basado en balance.
    double lot = NormalizeDouble((balance * RiskPercent / 100.0) / (StopLossUSD * 10), 2);
    if(lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if(lot > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    return lot;
}

void BuscarEntrada() {
   double bbUpper[2], bbLower[2], rsi[2], ema[2];
   ArraySetAsSeries(bbUpper,true); ArraySetAsSeries(bbLower,true); ArraySetAsSeries(rsi,true); ArraySetAsSeries(ema,true);
   
   if(CopyBuffer(bbHandle, 1, 0, 2, bbUpper) < 2) return;
   if(CopyBuffer(bbHandle, 2, 0, 2, bbLower) < 2) return;
   if(CopyBuffer(rsiHandle, 0, 0, 2, rsi) < 2) return;
   if(CopyBuffer(emaHandle, 0, 0, 2, ema) < 2) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double pNow = iClose(_Symbol, PERIOD_H1, 0);
   
   // Filtro Tendencial EMA 50 en H1
   bool tendenciaAlcista = pNow > ema[0];
   bool tendenciaBajista = pNow < ema[0];

   double lote = GetDynamicLot();
   double sl_puntos = StopLossUSD / (lote * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point);

   // COMPRA: Rebote en Banda Inferior + RSI Bajo + Tendencia Alcista o Neutral
   if(bid <= bbLower[0] && rsi[0] < RSI_Sobrevendido && tendenciaAlcista) {
      double sl = ask - sl_puntos * _Point;
      trade.Buy(lote, _Symbol, 0, sl, 0, "YNG_TITAN_BUY");
   }
   // VENTA: Rebote en Banda Superior + RSI Alto + Tendencia Bajista o Neutral
   if(ask >= bbUpper[0] && rsi[0] > RSI_Sobrecomprado && tendenciaBajista) {
      double sl = bid + sl_puntos * _Point;
      trade.Sell(lote, _Symbol, 0, sl, 0, "YNG_TITAN_SELL");
   }
}

void GestionarIndividual() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t) || PositionGetInteger(POSITION_MAGIC) != MagicPrincipal) continue;
      double profit = PositionGetDouble(POSITION_PROFIT);
      double pOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl     = PositionGetDouble(POSITION_SL);
      long   tipo   = PositionGetInteger(POSITION_TYPE);
      
      if(profit >= ProfitObjetivo) { trade.PositionClose(t); continue; }
      
      if(profit >= BE_Activacion) {
         double g = GarantiaBE * 10 * _Point;
         double nBE = (tipo == POSITION_TYPE_BUY) ? pOpen + g : pOpen - g;
         if(tipo == POSITION_TYPE_BUY  && sl < nBE) trade.PositionModify(t, nBE, 0);
         if(tipo == POSITION_TYPE_SELL && (sl == 0 || sl > nBE)) trade.PositionModify(t, nBE, 0);
      }
      if(ActivarTrailing && profit >= BE_Activacion) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(tipo == POSITION_TYPE_BUY) { double ns = bid - DistanciaTrailing*_Point; if(ns > sl + SaltoDelTrailing*_Point) trade.PositionModify(t, ns, 0); }
         else { double ns = ask + DistanciaTrailing*_Point; if(sl==0||ns < sl - SaltoDelTrailing*_Point) trade.PositionModify(t, ns, 0); }
      }
   }
}

bool EstaEnHorario() { MqlDateTime dt; TimeToStruct(TimeCurrent(),dt); return(dt.hour >= HoraInicio && dt.hour < HoraFin); }
int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==MagicPrincipal) c++; return c; }

//--- FUNCIONES DE SINCRONIZACIÓN ---
void SyncPositions() {
    if(PurchaseID == "") return;
    if(TimeCurrent() < lastPositionsSync + 30) return;
    lastPositionsSync = TimeCurrent();
    
    string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
    string positionsJson = "";
    int count = 0;
    
    for(int i=0; i<PositionsTotal(); i++) {
        if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicPrincipal) {
            if(count > 0) positionsJson += ",";
            positionsJson += "{\"ticket\":\"" + IntegerToString((long)posInfo.Ticket()) + "\"," +
                             "\"type\":\"" + (posInfo.PositionType()==POSITION_TYPE_BUY?"BUY":"SELL") + "\"," +
                             "\"symbol\":\"" + posInfo.Symbol() + "\"," +
                             "\"lots\":" + DoubleToString(posInfo.Volume(), 2) + "," +
                             "\"openPrice\":" + DoubleToString(posInfo.PriceOpen(), _Digits) + "," +
                             "\"sl\":" + DoubleToString(posInfo.StopLoss(), _Digits) + "," +
                             "\"tp\":" + DoubleToString(posInfo.TakeProfit(), _Digits) + "," +
                             "\"profit\":" + DoubleToString(posInfo.Profit() + posInfo.Commission() + posInfo.Swap(), 2) + "}";
            count++;
        }
    }
    
    // --- Sincronizar Historial de Hoy ---
    string historyJson = "";
    int hCount = 0;
    HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicPrincipal && HistoryDealGetDouble(t, DEAL_PROFIT) != 0) {
            if(hCount > 0) historyJson += ",";
            historyJson += "{\"ticket\":\"" + IntegerToString((long)t) + "\"," +
                           "\"type\":\"" + (HistoryDealGetInteger(t, DEAL_TYPE)==DEAL_TYPE_BUY?"BUY":"SELL") + "\"," +
                           "\"symbol\":\"" + HistoryDealGetString(t, DEAL_SYMBOL) + "\"," +
                           "\"lots\":" + DoubleToString(HistoryDealGetDouble(t, DEAL_VOLUME), 2) + "," +
                           "\"profit\":" + DoubleToString(HistoryDealGetDouble(t, DEAL_PROFIT), 2) + "}";
            hCount++;
            if(hCount >= 10) break; // Limitar para no saturar el JSON
        }
    }

    string postData = "{\"purchaseId\":\"" + PurchaseID + "\",\"account\":\"" + account + "\",\"positions\":[" + positionsJson + "],\"history\":[" + historyJson + "]}";
    char post[], result[];
    string headers = "Content-Type: application/json\r\n";
    StringToCharArray(postData, post, 0, WHOLE_ARRAY, CP_UTF8);
    
    ResetLastError();
    int res = WebRequest("POST", "https://kopytrading.com/api/sync-positions", headers, 3000, post, result, headers);
    if(res == -1) {
        // Reintento sin www si falla
        res = WebRequest("POST", "http://kopytrading.com/api/sync-positions", headers, 3000, post, result, headers);
    }
}

void CheckRemoteCommands() {
    if(PurchaseID == "") return;
    char post[], result[];
    string headers = "Content-Type: application/json\r\n";
    string url = "https://kopytrading.com/api/bot-command?purchaseId=" + PurchaseID;
    
    ResetLastError();
    int res = WebRequest("GET", url, headers, 2000, post, result, headers);
    if(res == 200) {
        string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
        if(StringFind(response, "\"command\":\"PAUSE\"") >= 0) remotePaused = true;
        if(StringFind(response, "\"command\":\"RESUME\"") >= 0) remotePaused = false;
        if(StringFind(response, "\"command\":\"CLOSE_ALL\"") >= 0) {
            for(int i=PositionsTotal()-1; i>=0; i--) 
                if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicPrincipal) trade.PositionClose(posInfo.Ticket());
        }
    }
}
