//+------------------------------------------------------------------+
//|     KOPYTRADE_v78_SCALING_BTC.mq5                                |
//|   BTC IRONCLAD v7.4.7 | SNIPER | RESCUE | SCALING PRO             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.47"
#property strict
#property description "₿ BTC v7.4.7 IRONCLAD | B1-B2 Scaling | Edge Rescue"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- DEFINES ---
#define P_TAG "EVO_V7_B_" 
#define MAGIC_NUMBER 780002
#define STR_COMMENT "EVO_V7_BTC"
#define CLR_BTC C'255,153,0'
#define CLR_GOLD C'212,175,55'
#define CLR_PANEL C'10,10,14'
#define CLR_BLUE C'30,144,255'
#define WEB_URL "https://www.kopytrading.com/api/sync-positions"

//--- PARÁMETROS ---
input group "🛡️ SEGURIDAD Y LICENCIA"
input string   LicenciaKey       = "TRIAL-2023"; 
input bool     ActivarNewsFilter = true;         
input bool     ForceCentMode     = true;         
input double   CentFactor        = 0.01;         
input string   PurchaseID        = "DEMO-USER"; 

input group "== GESTIÓN DE RIESGO v7.4.7 =="
input bool     UsarAutoLote_Def  = true;         // Activar Lote Automático
input double   PorcRiesgo_Def    = 0.5;          // % Riesgo por Operación
input double   MinLotsManual     = 0.02;         // Lote Base / Mínimo
input double   MaxLotMultiplier  = 3.0;          // Multiplicador Máx. Seguridad (x Lote Base)

input group "== CONFIGURACIÓN TÁCTICA =="
input int      FiboHours_Def     = 12;           // Mirada Fibo (Horas)
input double   StopLossPorc      = 105.0;        // Nivel de Stop Loss (%)
input bool     InpGiroOn         = true;         // Permitir GIRO (Edge)
input bool     InpCascadaOn      = true;         // Permitir CASCADA (Bala 2)

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         statusLabel = "🔍 ANALIZANDO...", strategyLabel = "ESPERANDO";
bool           remotePaused = false, isBullish = true, isMinimized = false;
bool           showEMA=true, showRSI=true, showFibo=true, trendConfirmed=false, isFirstRun=true;
bool           GiroOn, CascadaOn, sonidoOn=true;
double         f_p0=0, f_p100=0, f_p38=0, f_p50=0, f_p61=0;
datetime       f_t0, f_t100, lastTrendChange=0, analysisEndTime=0;
double         currLots, currRisk, currBE, currGarantia, currTS, currTSDist, currSLPct;
int            currFiboHours, lateralCndl=0;
datetime       lastBarTime=0, lockUntilBarTime=0, nextFiboCalc=0;
double         lastFiboHi=0, lastFiboLi=0;
bool           isAnalyzing=false, fearOn=false;
datetime       lastSyncTime = 0;

//--- SYNC PROTOCOL ---
void WebSync() {
   if(TimeCurrent() < lastSyncTime + 5) return;
   char post[], result[]; string headers, resp;
   
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl = CalculateFullDayPnL();
   long acc = AccountInfoInteger(ACCOUNT_LOGIN);
   
   string data = "{\"license\":\""+LicenciaKey+"\",\"purchaseId\":\""+PurchaseID+"\",\"acc\":\""+IntegerToString(acc)+"\"" +
                 ",\"lots\":"+DoubleToString(currLots,2)+
                 ",\"balance\":"+DoubleToString(bal,2)+
                 ",\"equity\":"+DoubleToString(eq,2)+
                 ",\"pnl_today\":"+DoubleToString(pnl,2)+
                 ",\"lkb\":"+IntegerToString(currFiboHours)+
                 ",\"trend\":"+(isBullish?"\"BULL\"":"\"BEAR\"")+
                 ",\"armed\":true" + 
                 ",\"b1_be\":"+DoubleToString(currBE,1)+",\"b1_gar\":"+DoubleToString(currGarantia,1)+
                 ",\"cascada\":"+(CascadaOn?"true":"false")+
                 ",\"giro\":"+(GiroOn?"true":"false")+
                 ",\"fear\":"+(fearOn?"true":"false")+"}";
                 
   StringToCharArray(data, post);
   int res = WebRequest("POST", WEB_URL, "", NULL, 3000, post, ArraySize(post), result, headers);
   if(res == 200) Print("🌍 WebSync: Sincronización exitosa con kopytrading.com");
   else if(res == -1) Print("❌ WebSync Error: Verifica que has añadido "+WEB_URL+" en Opciones > Expert Advisors");
   lastSyncTime = TimeCurrent();
}

//--- HUD HELPERS ---
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int z=200){ ObjectCreate(0,P_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial",int z=210){ ObjectCreate(0,P_TAG+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,c); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,P_TAG+n,OBJPROP_FONT,f); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrEdit(string n,int x,int y,int w,int h,string t,int s=9,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,C'40,40,60'); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetInteger(0,P_TAG+n,OBJPROP_ALIGN,ALIGN_CENTER); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }

//--- BALA_1 SETTINGS ---
double b1_BE_USD = 3.00, b1_G_USD = 2.00, b1_T_USD = 5.00;
//--- BALA_2 SETTINGS ---
double b2_BE_USD = 2.00, b2_G_USD = 1.00, b2_T_USD = 4.00;
//--- EDGE SETTINGS ---
double edge_BE_USD = 3.00, edge_G_USD = 2.00, edge_T_USD = 5.00;

//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   profitFactor = ForceCentMode ? CentFactor : 1.0;
   currRisk=PorcRiesgo_Def; currLots=MinLotsManual; currBE=3.00; currGarantia=2.00; currTS=5.00; currTSDist=2.00; currSLPct=StopLossPorc; currFiboHours=FiboHours_Def;
   // Forzar reinicio de globales para nuevos parámetros
   GlobalVariableSet(P_TAG+"be"+IntegerToString(MAGIC_NUMBER), 3.00);
   GlobalVariableSet(P_TAG+"gar"+IntegerToString(MAGIC_NUMBER), 2.00);
   GlobalVariableSet(P_TAG+"ts"+IntegerToString(MAGIC_NUMBER), 5.00);
   GiroOn = InpGiroOn; CascadaOn = InpCascadaOn;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   LoadSettings(); 
   EventSetTimer(1); CrearHUD(); UpdateAutoFibo();
   analysisEndTime = TimeCurrent() + 10; isAnalyzing = true;
   // Forzado de parámetros institucionales solicitados
   currBE=3.00; currGarantia=2.00; currTS=5.00; 
   string m = IntegerToString(MAGIC_NUMBER);
   GlobalVariableSet(P_TAG+"be"+m, 3.00); GlobalVariableSet(P_TAG+"gar"+m, 2.00); GlobalVariableSet(P_TAG+"ts"+m, 5.00);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { SaveSettings(); ObjectsDeleteAll(0, P_TAG); }
void OnTick() { UpdateAutoFibo(); ManageStrategy(); ProtectPositions(); dayPnL = CalculateFullDayPnL(); ActualizarHUD(); WebSync(); }
void OnTimer() { if(!MQLInfoInteger(MQL_TESTER) && ActivarNewsFilter) CheckRemoteNews(); else remotePaused = false; }

double CalculateAutoLot() {
   if(!UsarAutoLote_Def) return currLots;
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = bal * (currRisk / 100.0);
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double range = MathAbs(f_p0 - f_p100) * (currSLPct/100.0); 
   if(range <= 0 || tickVal <= 0) return currLots;
   double lots = riskMoney / ((range / tickSize) * tickVal);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;
   // Blindaje de Seguridad: No exceder el multiplicador del lote manual
   double maxSafeLot = NormalizeDouble(MinLotsManual * MaxLotMultiplier, 2);
   lots = fmin(lots, maxSafeLot);
   return fmax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), fmin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), NormalizeDouble(lots, 2)));
}

//--- TRACKER DE PROTECCIÓN ---
bool IsPositionProtected(string comment) {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) {
         double open = pos.PriceOpen(), sl = pos.StopLoss();
         if(pos.PositionType()==POSITION_TYPE_BUY) return (sl >= open - _Point);
         if(pos.PositionType()==POSITION_TYPE_SELL) return (sl <= open + _Point && sl > 0);
      }
   }
   return false;
}

void UpdateAutoFibo() {
   if(PositionsTotalBots() > 0 && !CascadaOn) return;
   if(TimeCurrent() < nextFiboCalc) return;
   nextFiboCalc = TimeCurrent() + 30;
   datetime tNow = TimeCurrent();
   datetime tStart = tNow - (currFiboHours * 3600);
   int bars = iBarShift(_Symbol, _Period, tStart);
   if(bars < 2) bars = 10;
   int hiIdx = iHighest(_Symbol, _Period, MODE_HIGH, bars, 0);
   int liIdx = iLowest(_Symbol, _Period, MODE_LOW, bars, 0);
   if(hiIdx < 0 || liIdx < 0) return;
// Label superior eliminado por redundancia
   double vHi = iHigh(_Symbol, _Period, hiIdx), vLi = iLow(_Symbol, _Period, liIdx);
   double ema20[], ema50[]; ArraySetAsSeries(ema20,true); ArraySetAsSeries(ema50,true);
   CopyBuffer(h_ema20,0,0,1,ema20); CopyBuffer(h_ema50,0,0,1,ema50);
   // Detección Instantánea: Si el máximo es más reciente que el mínimo -> Alcista
   isBullish = (hiIdx < liIdx);
   trendConfirmed = true;
   if(vHi > lastFiboHi || vLi < lastFiboLi) { lockUntilBarTime = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period); lastFiboHi = vHi; lastFiboLi = vLi; }
   if(isBullish) { f_p100 = vLi; f_t100 = iTime(_Symbol, _Period, liIdx); f_p0 = vHi; f_t0 = iTime(_Symbol, _Period, hiIdx); }
   else { f_p100 = vHi; f_t100 = iTime(_Symbol, _Period, hiIdx); f_p0 = vLi; f_t0 = iTime(_Symbol, _Period, liIdx); }
   double diff = f_p0 - f_p100;
   f_p38 = f_p100 + diff * 0.382; f_p50 = f_p100 + diff * 0.500; f_p61 = f_p100 + diff * 0.618;
   if(showFibo) { 
      DrawFullFibo();
      DrawTranslucentZone();
      DrawDirectionalArrow(isBullish, (TimeCurrent() >= analysisEndTime));
   }
}

void DrawFullFibo() {
   string n = P_TAG+"fibo";
   if(ObjectFind(0,n)<0) { ObjectCreate(0,n,OBJ_FIBO,0,f_t100,f_p100,f_t0,f_p0); ObjectSetInteger(0,n,OBJPROP_BACK,true); ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,true); }
   ObjectSetInteger(0,n,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p100); // 100% en el Origen
   ObjectSetInteger(0,n,OBJPROP_TIME,1,f_t0); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p0);     // 0% en el Target
   ObjectSetInteger(0,n,OBJPROP_LEVELS,8);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,0,0.0);    ObjectSetString(0,n,OBJPROP_LEVELTEXT,0,"🎯 TARGET (0.0)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,0,clrLime);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,1,-0.272); ObjectSetString(0,n,OBJPROP_LEVELTEXT,1,"💰 ZONA TAKE PROFIT (-27)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,1,clrLime);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,2,0.214);  ObjectSetString(0,n,OBJPROP_LEVELTEXT,2,"⚠️ ALERTA REVERSION (21.4)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,2,clrYellow);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,3,0.382);  ObjectSetString(0,n,OBJPROP_LEVELTEXT,3,"📥 ZONA ENTRADA (38.2)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,3,clrOrange);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,4,0.500);  ObjectSetString(0,n,OBJPROP_LEVELTEXT,4,"🔵 ZONA SMART (50.0)");   ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,4,clrDeepSkyBlue);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,5,0.618);  ObjectSetString(0,n,OBJPROP_LEVELTEXT,5,"🛑 RESISTENCIA / EDGE (61.8)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,5,clrRed);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,6,0.764);  ObjectSetString(0,n,OBJPROP_LEVELTEXT,6,"⚡ ULTIMA DEFENSA (76)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,6,clrCrimson);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,7,1.0);    ObjectSetString(0,n,OBJPROP_LEVELTEXT,7,"🚫 ORIGEN / STOP (100)");   ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,7,clrRed);
}

void ManageStrategy() {
   strategyLabel = StringSubstr(_Symbol, 0, 3) + " x" + (string)PositionsTotalBots();
   
   double rsi[1], ema20[1], ema50[1], high[1], low[1];
   if(CopyBuffer(h_rsi,0,0,1,rsi)<=0 || CopyBuffer(h_ema20,0,0,1,ema20)<=0 || CopyBuffer(h_ema50,0,0,1,ema50)<=0) return;
// Usamos precio real instantáneo para evitar lag en rupturas
   double priceReal = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // DETERMINAR TENDENCIA BASE
   datetime barrier = iTime(_Symbol,_Period,0);
   bool isTrapped = (priceReal > ema20[0] && priceReal < ema50[0]) || (priceReal < ema20[0] && priceReal > ema50[0]);
   string trendText = isTrapped ? "LATERAL (Velas: "+(string)lateralCndl+")" : (isBullish ? "📈 ALCISTA" : "📉 BAJISTA");
   
   if(isTrapped) { if(barrier != lastBarTime) { lateralCndl++; lastBarTime = barrier; } } 
   else { lateralCndl = 0; lastBarTime = barrier; }

   // CONCATENAR ESTADO
   statusLabel = trendText;
   if(TimeCurrent() < analysisEndTime) { statusLabel += " | 🕒 ANALIZANDO..."; return; }
// Bloqueo de espera de vela eliminado para mayor agresividad
   statusLabel += " (BUSCANDO)";

   double price = SymbolInfoDouble(_Symbol, isBullish ? SYMBOL_ASK : SYMBOL_BID);
   double totalRange = MathAbs(f_p0 - f_p100);
   double pct = (totalRange > 0) ? (MathAbs(price - f_p100) / totalRange) * 100 : 0;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // --- BALA 1: ENTRADA (Zona Smart 38.2 - 50) ---
   bool inZone = (pct >= 38.2 && pct <= 50.0);
   if(PositionsTotalBots() == 0 && inZone && trendConfirmed) {
      // --- SELLO DE SEGURIDAD: Solo disparamos en la dirección del semáforo HUD ---
      double lots = CalculateAutoLot();
      double sl = f_p100 - (f_p0 - f_p100) * (currSLPct/100.0);
      
      if(isBullish && bid > ema20[0] && bid > ema50[0]) { // Confirmación visual ALCISTA
         if(trade.Buy(lots, _Symbol, ask, sl, 0, "EVO_V7_B1")) {
            if(trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED)
               statusLabel = "⚠️ ERROR: " + trade.ResultRetcodeDescription();
         }
      } 
      else if(!isBullish && bid < ema20[0] && bid < ema50[0]) { // Confirmación visual BAJISTA
         if(trade.Sell(lots, _Symbol, bid, sl, 0, "EVO_V7_B1")) {
            if(trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED)
               statusLabel = "⚠️ ERROR: " + trade.ResultRetcodeDescription();
         }
      }
   }

   // --- PUERTA DE SEGURIDAD: SI NO HAY B1 Abierta, NO HAY NADA MAS ---
   int countB1 = CountPositions("EVO_V7_B1");
   if(countB1 == 0) return;
   
   // --- BALA 2: CASCADA (Solo si B1 está PROTEGIDA en BE) ---
   double p1 = GetPositionProfit("EVO_V7_B1");
   bool b1Protected = IsPositionProtected("EVO_V7_B1");
   
   if(CascadaOn && p1 != -999 && p1 >= currBE && b1Protected && CountPositions("EVO_V7_B2") == 0) {
      double lots = CalculateAutoLot(); 
      double sl = ValidSL(GetPositionOpenPrice("EVO_V7_B1"), isBullish); 
      if(isBullish) { if(trade.Buy(lots, _Symbol, ask, sl, 0, "EVO_V7_B2")) if(sonidoOn) { PlaySound("ok.wav"); PlaySound("ok.wav"); } }
      else { if(trade.Sell(lots, _Symbol, bid, sl, 0, "EVO_V7_B2")) if(sonidoOn) { PlaySound("ok.wav"); PlaySound("ok.wav"); } }
   }

   // --- MODO GIRO: Entramos con la CONTRARIA al B1 original si falló ---
   if(GiroOn && p1 != -999 && p1 < 0 && pct > 61.8 && CountPositions("EVO_V7_RESCUE") == 0) {
      double lots = CalculateAutoLot() * 1.5; 
      // Buscamos el tipo de posición real de B1 para girarnos correctamente
      ENUM_POSITION_TYPE b1Type = POSITION_TYPE_BUY;
      for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()=="EVO_V7_B1") { b1Type = pos.PositionType(); break; }
      
      if(b1Type == POSITION_TYPE_BUY) { // B1 era Compra, falló -> Rescatamos con VENTA
         if(trade.Sell(lots, _Symbol, bid, 0, 0, "EVO_V7_RESCUE")) if(sonidoOn) PlaySound("alert.wav"); 
      }
      else { // B1 era Venta, falló -> Rescatamos con COMPRA
         if(trade.Buy(lots, _Symbol, ask, 0, 0, "EVO_V7_RESCUE")) if(sonidoOn) PlaySound("alert.wav"); 
      }
   }

   statusLabel = isBullish ? "📈 ALCISTA (TRABAJANDO)" : "📉 BAJISTA (TRABAJANDO)";
   strategyLabel = StringSubstr(_Symbol, 0, 3) + " x" + (string)PositionsTotalBots();
}

void ProtectPositions() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || ts <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic() == MAGIC_NUMBER) {
         string comm = pos.Comment();
         double pUSD = (pos.Profit() + pos.Swap() + pos.Commission()) * profitFactor;
         double vol = pos.Volume(), openP = pos.PriceOpen(), curSL = pos.StopLoss(), newSL = curSL;
         
         // --- BALA 1 PROTECTION (USANDO VALORES DEL HUD) ---
         if(comm == "EVO_V7_B1") {
            double distG = (currGarantia * ts) / (vol * tv), distT = (currTSDist * ts) / (vol * tv);
            if(pos.PositionType()==POSITION_TYPE_BUY) {
               if(pUSD >= currBE && (newSL < openP + distG)) newSL = openP + distG;
               if(pUSD >= currTS && (bid - distT) > newSL) newSL = bid - distT;
               double slDist = MathAbs(openP - curSL);
               if(fearOn && pUSD < 0 && MathAbs(bid - openP) > slDist * 0.5 && CountPositions("EVO_V7_RESCUE") > 0) { trade.PositionClose(pos.Ticket()); continue; }
            } else {
               if(pUSD >= currBE && (newSL > openP - distG || newSL == 0)) newSL = openP - distG;
               if(pUSD >= currTS && (ask + distT) < newSL && ask + distT > 0) newSL = ask + distT;
               double slDist = MathAbs(openP - curSL);
               if(fearOn && pUSD < 0 && MathAbs(ask - openP) > slDist * 0.5 && CountPositions("EVO_V7_RESCUE") > 0) { trade.PositionClose(pos.Ticket()); continue; }
            }
         }
         // --- BALA 2 PROTECTION (DINÁMICA: HUD - 1.0) ---
         else if(comm == "EVO_V7_B2") {
            double b2BE = fmax(0.5, currBE - 1.0), b2G = fmax(0.5, currGarantia - 1.0), b2TS = fmax(1.0, currTS - 1.0);
            double distG = (b2G * ts) / (vol * tv), distT = (currTSDist * ts) / (vol * tv);
            if(pos.PositionType()==POSITION_TYPE_BUY) {
               if(pUSD >= b2BE && (newSL < openP + distG)) newSL = openP + distG;
               if(pUSD >= b2TS && (bid - distT) > newSL) newSL = bid - distT;
            } else {
               if(pUSD >= b2BE && (newSL > openP - distG || newSL == 0)) newSL = openP - distG;
               if(pUSD >= b2TS && (ask + distT) < newSL && ask + distT > 0) newSL = ask + distT;
            }
         }
         // --- RESCUE PROTECTION (MISMO QUE B1) ---
         else if(comm == "EVO_V7_RESCUE") {
            double distG = (currGarantia * ts) / (vol * tv), distT = (currTSDist * ts) / (vol * tv);
            if(pos.PositionType()==POSITION_TYPE_BUY) {
               if(pUSD >= currBE && (newSL < openP + distG)) newSL = openP + distG;
               if(pUSD >= currTS && (bid - distT) > newSL) newSL = bid - distT;
            } else {
               if(pUSD >= currBE && (newSL > openP - distG || newSL == 0)) newSL = openP - distG;
               if(pUSD >= currTS && (ask + distT) < newSL && ask + distT > 0) newSL = ask + distT;
            }
         }

         if(MathAbs(newSL - curSL) > _Point) trade.PositionModify(pos.Ticket(), NormalizeDouble(newSL, _Digits), 0);
      }
   }
}

//--- HELPERS ---
double GetPositionProfit(string comment) { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) return (pos.Profit()+pos.Swap()+pos.Commission())*profitFactor; return -999; }
double GetPositionOpenPrice(string comment) { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) return pos.PriceOpen(); return 0; }
int CountPositions(string comment) { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) c++; return c; }
int PositionsTotalBots() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) c++; return c; }
void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) trade.PositionClose(pos.Ticket()); }
double ValidSL(double price, bool buy) {
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double stpMin = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double freeze = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
   double limit = fmax(stpMin, freeze);
   limit = fmax(limit, 50 * _Point); // Seguridad extra de 50 puntos
   
   double b = SymbolInfoDouble(_Symbol, SYMBOL_BID), a = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(buy) { 
      if(price > b - limit) price = b - limit; 
   }
   else { 
      if(price > 0 && price < a + limit) price = a + limit; 
   }
   
   if(ts > 0) price = MathRound(price / ts) * ts;
   return NormalizeDouble(price, _Digits);
}

void ActualizarHUD() {
   if(ObjectFind(0,P_TAG+"bg")<0) return;
   ObjectSetString(0,P_TAG+"pV",OBJPROP_TEXT,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / LOTE 1: "+DoubleToString(currLots,2));
   
   // --- LÓGICA DE SEMÁFORO ---
   double e20[1], e50[1], bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   CopyBuffer(h_ema20,0,0,1,e20); CopyBuffer(h_ema50,0,0,1,e50);
   color stC = clrWhite;
   if(!trendConfirmed) stC = clrWhite;
   else if(bid > e20[0] && bid > e50[0]) stC = clrCyan;
   else if(bid < e20[0] && bid < e50[0]) stC = clrRed;
   else stC = clrDimGray;
   
   long rem = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period) - TimeCurrent();
   if(rem < 0) rem = 0;
   string clock = "[" + IntegerToString(rem/60, 2, '0') + ":" + IntegerToString(rem%60, 2, '0') + "] ";
   ObjectSetString(0,P_TAG+"stV",OBJPROP_TEXT, clock + statusLabel);
   ObjectSetInteger(0,P_TAG+"stV",OBJPROP_COLOR, stC);

   ObjectSetString(0,P_TAG+"l_nx",OBJPROP_TEXT,"ESTRATEGIA: "+strategyLabel);
   double p1 = GetPositionProfit("EVO_V7_B1");
   double p2 = GetPositionProfit("EVO_V7_B2");
   double pE = GetPositionProfit("EVO_V7_RESCUE");
   
   string s1 = (p1 == -999) ? "Esperando..." : (p1 >= 0 ? "+$ " : "-$ ") + DoubleToString(MathAbs(p1),2);
   string s2 = (p2 == -999) ? "En Reposo" : (p2 >= 0 ? "+$ " : "-$ ") + DoubleToString(MathAbs(p2),2);
   string sE = (pE == -999) ? "Apagado" : (pE >= 0 ? "+$ " : "-$ ") + DoubleToString(MathAbs(pE),2);

   ObjectSetString(0,P_TAG+"m1",OBJPROP_TEXT,"B1: " + s1);
   ObjectSetString(0,P_TAG+"m2",OBJPROP_TEXT,"B2: " + s2);
   ObjectSetString(0,P_TAG+"mE",OBJPROP_TEXT,"EDGE: " + sE);

   datetime tS = TimeCurrent() - (currFiboHours * 3600);
   int vls = iBarShift(_Symbol, _Period, tS);
   ObjectSetString(0,P_TAG+"l_fhV",OBJPROP_TEXT,IntegerToString(currFiboHours)+"h ("+IntegerToString(vls)+" velas)");
}

void CrearHUD() {
   ObjectsDeleteAll(0, P_TAG); int hx=15, hy=15, hw=380, hh=isMinimized?40:480;
   CrRect("bg",hx,hy,hw,hh,CLR_PANEL,CLR_BTC, 300); 
   CrLabel("ttl",hx+15,hy+13,isMinimized?"₿ BTC MONITOR":"🛡️ BTC IRONCLAD v747",CLR_BTC,11,"Impact", 310);
   CrBtn("b_min",hx+hw-35,hy+8,25,25,isMinimized?"+":"-",C'60,60,80',clrWhite, 325);
   CrBtn("b_vol",hx+hw-65,hy+8,25,25,sonidoOn?"🔊":"🔇",sonidoOn?C'30,80,30':C'60,60,60',clrWhite,330);
   if(isMinimized) return;
   
   CrLabel("pV",hx+15,hy+50,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / LOTE 1: "+DoubleToString(currLots,2),clrWhite,8,"Arial Bold", 310);
   CrLabel("stV",hx+15,hy+72,statusLabel,clrCyan,9,"Arial Bold", 310);
   CrLabel("l_nx",hx+15,hy+95,"ESTRATEGIA: "+strategyLabel,clrOrange,8,"Arial Bold", 310);
   
   int ry = hy+115, mx=hx+hw/2+10;
   // COLUMNA 1
   CrLabel("l_lot",hx+15,ry+5, "LOTES B1:",clrSilver,7); CrEdit("e_lot",hx+100,ry,60,20,DoubleToString(currLots,2)); 
   CrLabel("l_td", mx,ry+5, "DISTANCIA ($):",clrSilver,7); CrEdit("e_tsd",mx+100,ry,60,20,DoubleToString(currTSDist,2)); ry+=25;
   
   CrLabel("l_be", hx+15,ry+5, "BE ($):",clrSilver,7); CrEdit("e_be", hx+100,ry,60,20,DoubleToString(currBE,2)); 
   CrLabel("l_gar",mx,ry+5, "GARANTIA ($):",CLR_GOLD,7); CrEdit("e_gar",mx+100,ry,60,20,DoubleToString(currGarantia,2)); ry+=25;

   CrLabel("l_ts", hx+15,ry+5, "TRAILING ($):",clrSilver,7); CrEdit("e_ts", hx+100,ry,60,20,DoubleToString(currTS,2)); 
   CrLabel("l_sl", mx,ry+5, "STOP LOSS (%):",clrRed,7);    CrEdit("e_slp",mx+100,ry,60,20,DoubleToString(currSLPct,1)); ry+=35;
   
   // CONTROLES FIBO
   CrLabel("l_fib", hx+15,ry+2, "RANGO FIBO:",clrSilver,7);
   CrBtn("b_fM",hx+100,ry,30,22,"-",C'60,60,80',clrWhite,330);
   CrLabel("l_fhV", hx+140,ry+2, IntegerToString(currFiboHours)+"h (48 velas)",clrWhite,8,"Arial Bold");
   CrBtn("b_fP",hx+230,ry,30,22,"+",C'60,60,80',clrWhite,330); ry+=35;

   // MONITOR OPERACIONES
   CrRect("m_bg",hx+10,ry,hw-20,70,C'15,15,25',clrDimGray,310);
   CrLabel("m1",hx+20,ry+7, "B1: Esperando...",clrLime,8,"Arial", 320);
   CrLabel("m2",hx+20,ry+27,"B2: En Reposo",clrDeepSkyBlue,8,"Arial", 320);
   CrLabel("mE",hx+20,ry+47,"EDGE: Apagado",clrOrange,8,"Arial", 320); ry+=85;
   
   // TOGGLES CORE
   CrBtn("b_giro",hx+10,ry,105,32,"GIRO: "+(GiroOn?"ON":"OFF"),GiroOn?clrGreen:clrRed,clrWhite,320); 
   CrBtn("b_cas", hx+122,ry,110,32,"CASCADA: "+(CascadaOn?"ON":"OFF"),CascadaOn?clrGreen:clrRed,clrWhite,320);
   CrBtn("b_fear",hx+240,ry,100,32,"MIEDO: "+(fearOn?"ON":"OFF"),fearOn?clrGreen:clrRed,clrWhite,320); ry+=45;
   
   CrBtn("b_app",hx+10,ry,hw-20,32,"APLICAR CAMBIOS",C'40,80,150',clrWhite,330); ry+=50;
   CrBtn("b_cls",hx+10,ry,hw-20,40,"🛑 CERRAR TODO (PANICO)",C'180,40,40',clrWhite,340);
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==P_TAG+"b_min")   { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==P_TAG+"b_fM")   { currFiboHours = (int)fmax(1, currFiboHours - 1); SaveSettings(); UpdateAutoFibo(); ActualizarHUD(); }
      if(sp==P_TAG+"b_fP")   { currFiboHours = (int)fmin(72, currFiboHours + 1); SaveSettings(); UpdateAutoFibo(); ActualizarHUD(); }
      if(sp==P_TAG+"b_vol")   { sonidoOn=!sonidoOn; SaveSettings(); ObjectSetString(0,sp,OBJPROP_TEXT,sonidoOn?"🔊":"🔇"); ObjectSetInteger(0,sp,OBJPROP_BGCOLOR,sonidoOn?C'30,80,30':C'60,60,60'); }
      if(sp==P_TAG+"b_giro")  { GiroOn=!GiroOn; SaveSettings(); ObjectSetString(0,sp,OBJPROP_TEXT,"GIRO: "+(GiroOn?"ON":"OFF")); ObjectSetInteger(0,sp,OBJPROP_BGCOLOR,GiroOn?clrGreen:clrRed); }
      if(sp==P_TAG+"b_cas")   { CascadaOn=!CascadaOn; SaveSettings(); ObjectSetString(0,sp,OBJPROP_TEXT,"CASCADA: "+(CascadaOn?"ON":"OFF")); ObjectSetInteger(0,sp,OBJPROP_BGCOLOR,CascadaOn?clrGreen:clrRed); }
      if(sp==P_TAG+"b_fear")  { fearOn=!fearOn; SaveSettings(); ObjectSetString(0,sp,OBJPROP_TEXT,"MIEDO: "+(fearOn?"ON":"OFF")); ObjectSetInteger(0,sp,OBJPROP_BGCOLOR,fearOn?clrGreen:clrRed); }
      if(sp==P_TAG+"b_cls")   { CloseAll(); if(sonidoOn) PlaySound("alert.wav"); }
      if(sp==P_TAG+"b_app")   { SaveSettings(); analysisEndTime = TimeCurrent()+10; UpdateAutoFibo(); if(sonidoOn) PlaySound("ok.wav"); }
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==P_TAG+"e_lot") currLots = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_be")  currBE = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_gar") currGarantia = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_ts")  currTS = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_tsd") currTSDist = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_slp") currSLPct = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      SaveSettings();
   }
}

void CheckRemoteNews() { char data[], res[]; string h; int s = WebRequest("GET","https://kopytrading.com/api/news-filter",NULL,NULL,500,data,0,res,h); if(s==200) remotePaused = (StringFind(CharArrayToString(res),"PAUSE")>=0); }
void LoadSettings() {
   string m = IntegerToString(MAGIC_NUMBER);
   if(GlobalVariableCheck(P_TAG+"lot"+m))  currLots = GlobalVariableGet(P_TAG+"lot"+m);
   if(GlobalVariableCheck(P_TAG+"risk"+m)) currRisk = GlobalVariableGet(P_TAG+"risk"+m);
   if(GlobalVariableCheck(P_TAG+"be"+m))   currBE = GlobalVariableGet(P_TAG+"be"+m);
   if(GlobalVariableCheck(P_TAG+"gar"+m))  currGarantia = GlobalVariableGet(P_TAG+"gar"+m);
   if(GlobalVariableCheck(P_TAG+"ts"+m))   currTS = GlobalVariableGet(P_TAG+"ts"+m);
   if(GlobalVariableCheck(P_TAG+"td"+m))   currTSDist = GlobalVariableGet(P_TAG+"td"+m);
   if(GlobalVariableCheck(P_TAG+"sl"+m))   currSLPct = GlobalVariableGet(P_TAG+"sl"+m);
   if(GlobalVariableCheck(P_TAG+"fib"+m))  currFiboHours = (int)GlobalVariableGet(P_TAG+"fib"+m);
   if(GlobalVariableCheck(P_TAG+"vol"+m))  sonidoOn = (bool)GlobalVariableGet(P_TAG+"vol"+m);
   if(GlobalVariableCheck(P_TAG+"gir"+m))  GiroOn = (bool)GlobalVariableGet(P_TAG+"gir"+m);
   if(GlobalVariableCheck(P_TAG+"cas"+m))  CascadaOn = (bool)GlobalVariableGet(P_TAG+"cas"+m);
}

void SaveSettings() {
   string m = IntegerToString(MAGIC_NUMBER);
   GlobalVariableSet(P_TAG+"lot"+m, currLots);
   GlobalVariableSet(P_TAG+"risk"+m, currRisk);
   GlobalVariableSet(P_TAG+"be"+m, currBE);
   GlobalVariableSet(P_TAG+"gar"+m, currGarantia);
   GlobalVariableSet(P_TAG+"ts"+m, currTS);
   GlobalVariableSet(P_TAG+"td"+m, currTSDist);
   GlobalVariableSet(P_TAG+"sl"+m, currSLPct);
   GlobalVariableSet(P_TAG+"fib"+m, currFiboHours);
   GlobalVariableSet(P_TAG+"vol"+m, (double)sonidoOn);
   GlobalVariableSet(P_TAG+"gir"+m, (double)GiroOn);
   GlobalVariableSet(P_TAG+"cas"+m, (double)CascadaOn);
   GlobalVariableSet(P_TAG+"fear"+m, (double)fearOn);
   GlobalVariablesFlush();
}


void DrawTranslucentZone() {
   string name = P_TAG+"zone";
   double p38 = f_p100 + (f_p0 - f_p100) * 0.382;
   double p61 = f_p100 + (f_p0 - f_p100) * 0.618;
   if(ObjectFind(0,name)<0) { ObjectCreate(0,name,OBJ_RECTANGLE,0,f_t100,p38,TimeCurrent()+3600*12,p61); }
   else { ObjectSetInteger(0,name,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,name,OBJPROP_PRICE,0,p38); ObjectSetInteger(0,name,OBJPROP_TIME,1,TimeCurrent()+3600*12); ObjectSetDouble(0,name,OBJPROP_PRICE,1,p61); }
   ObjectSetInteger(0,name,OBJPROP_COLOR,C'60,45,15'); // Naranja suave traslúcido
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
}

void DrawDirectionalArrow(bool bull, bool active) {
   string n = P_TAG+"arrow";
   color clr = active ? (bull ? clrLime : clrRed) : clrGray;
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_ARROW,0,TimeCurrent(),0);
   ObjectSetInteger(0,n,OBJPROP_ARROWCODE,bull?233:234);
   ObjectSetInteger(0,n,OBJPROP_TIME,TimeCurrent());
   ObjectSetDouble(0,n,OBJPROP_PRICE,f_p0); // Flecha en el Target para visibilidad total
   ObjectSetInteger(0,n,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,n,OBJPROP_WIDTH,8);
}
double CalculateFullDayPnL() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0; HistorySelect(StructToTime(dt), TimeCurrent()); double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t=HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == MAGIC_NUMBER) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); } return p * profitFactor; }
