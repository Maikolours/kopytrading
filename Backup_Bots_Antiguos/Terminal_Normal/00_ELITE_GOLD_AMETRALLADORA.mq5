//+------------------------------------------------------------------+
//|     00_ELITE_GOLD_AMETRALLADORA.mq5                               |
//|   GOLD AMETRALLADORA v2.2.3 SUPREME | ADN v78 |                 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "2.23"
#property strict
#property description "🔱 XAUUSD v2.2.3 GOLDEN SUPREME | TOTAL SYNC"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- 📥 INCLUIR MÓDULO DE INTEGRACIÓN SUPREME (v1.5) ---
#include "Kopytrading_Integration.mqh.mq5"

//--- DEFINES ---
#define P_TAG "GOLD_AM_" 
#define MAGIC_NUMBER 780003
#define STR_COMMENT "GOLD_AMETRALLADORA"
#define CLR_GOLD C'212,175,55'
#define CLR_PANEL C'10,10,14'
#define WEB_URL "https://www.kopytrading.com/api/sync-positions"

//--- PARÁMETROS ---
input group "🛡️ SEGURIDAD Y LICENCIA"
input string   InpLicKey         = "TRIAL-2023"; 
input string   InpMasterID       = "viajaconsakura@gmail.com";
input bool     InpIsCentAccount  = false;        // ¿Es cuenta Cent?
input bool     InpNewsFilter     = true;         

input group "🔱 CONFIGURACIÓN AMETRALLADORA (ADN v78)"
input double   InpLots           = 0.01;         // Lote Base
input int      InpLookback       = 12;           // Mirada Fibo (Horas)
input double   InpRiskPerTrade   = 0.5;          // % Riesgo Max (Scaling)
input double   InpSL_Pct         = 105.0;        // Stop Loss (%)

input group "🎯 GESTIÓN DE PROTECCIÓN (USD)"
input ENUM_TIMEFRAMES InpOperativeTF = PERIOD_M15;    // Temporalidad Operativa
input double   InpB1_BE          = 3.0;          // [B1] Break-Even ($)
input double   InpB1_GAR         = 2.0;          // [B1] Garantía ($)
input double   InpB1_TRA         = 5.0;          // [B1] Trailing ($)

input group "🔥 CONFIGURACIÓN MODO FUEGO RÁPIDO (MARTINGALA)"
input bool     InpUseScalp       = true;         // Activar Ráfagas en Zona
input double   InpR_Mult         = 1.5;          // Multiplicador de Lote
input int      InpR_MaxOps       = 8;            // Máximo de balas por ráfaga
input double   InpR_DistPips     = 15.0;         // Distancia entre balas (pips)
input double   InpR_ProfitScalp  = 5.0;          // Profit cierre bala ($)
input double   InpR_ProfitIdeal  = 20.0;         // Profit cierre ráfaga completa ($)

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50;
bool           isBullish = true, casOn = true, giroOn = true, fearOn = false;
double         f_p0=0, f_p100=0, f_p38=0, f_p50=0, f_p61=0;
datetime       f_t0, f_t100;
double         lastHi=0, lastLi=0;
string         lastWebStatus = "RED: ---";
bool           fuegoRapido = false;
double         profitRafaga = 0;
bool           isFirstRun = true;
int            hud_x = 20, hud_y = 20;
bool           webConnected = false;
datetime       lastSync = 0;
double         usdMult = 1.0;

//--- HELPERS HUD ---
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int z=200){ 
   string nm = P_TAG+n; if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,nm,OBJPROP_XSIZE,w); ObjectSetInteger(0,nm,OBJPROP_YSIZE,h); ObjectSetInteger(0,nm,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,nm,OBJPROP_COLOR,bd); ObjectSetInteger(0,nm,OBJPROP_ZORDER,z); 
}
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial",int z=210){ 
   string nm = P_TAG+n; if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,y); ObjectSetString(0,nm,OBJPROP_TEXT,t); 
   ObjectSetInteger(0,nm,OBJPROP_COLOR,c); ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,s); ObjectSetString(0,nm,OBJPROP_FONT,f); ObjectSetInteger(0,nm,OBJPROP_ZORDER,z); 
}
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,int z=220){ 
   string nm = P_TAG+n; if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,nm,OBJPROP_XSIZE,w); ObjectSetInteger(0,nm,OBJPROP_YSIZE,h); ObjectSetString(0,nm,OBJPROP_TEXT,t); ObjectSetInteger(0,nm,OBJPROP_BGCOLOR,bg); 
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,8); ObjectSetInteger(0,nm,OBJPROP_ZORDER,z); 
   ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_STATE,false);
}

void CrearHUD() {
   int hx=hud_x, hy=hud_y, hw=300, hh=520;
   ObjectsDeleteAll(0,P_TAG);
   CrRect("bg",hx,hy,hw,hh,CLR_PANEL,CLR_GOLD,100); CrRect("hdr",hx,hy,hw,30,C'40,35,10',CLR_GOLD,110);
   CrLabel("ttl",hx+10,hy+10,"🔱 GOLDEN SUPREME v2.2.0",CLR_GOLD,9,"Impact",120);
   CrLabel("net",hx+210,hy+10,"RED: PAUSA",clrWhite,7);
   
   int ry = hy+45;
   CrLabel("l_mod",hx+20,ry,"...",clrWhite,10,"Impact"); ry+=30;
   
   string operativeTF = StringSubstr(EnumToString(InpOperativeTF), 7);
   CrLabel("l_tf",hx+20,ry,"ANÁLISIS: "+IntegerToString(InpLookback)+"h | TF: "+operativeTF,clrSilver,7); ry+=35;
   
   CrRect("stbg",hx+10,ry,hw-20,90,C'20,20,25',C'60,55,40',115);
   CrLabel("l_st",hx+20,ry+15,"ESTADO: ---",clrWhite,9,"Arial Bold");
   CrLabel("l_arm",hx+170,ry+15,"STRAT: ---",clrWhite,8);
   
   int by = ry+45;
   CrBtn("b1",hx+20,by,125,32,"GIRO: ...",clrGray);
   CrBtn("b2",hx+155,by,125,32,"CASCADA: ...",clrGray); ry+=105;
   
   CrRect("pbg",hx+10,ry,hw-20,100,C'20,20,25',C'60,55,40',115);
   CrLabel("l_bl",hx+20,ry+15,"BALANCE: $ 0.00",clrWhite,8);
   CrLabel("l_eq",hx+20,ry+35,"EQUIDAD: $ 0.00",clrSpringGreen,8);
   CrLabel("l_prf",hx+20,ry+60,"PROFIT RÁFAGA:",clrOrange,8);
   CrLabel("l_prv",hx+140,ry+60,"$0.00",clrOrange,11,"Impact");
   ry+=115;
   
   CrBtn("panic",hx+10,ry,hw-20,45,"🛑 PÁNICO: CERRAR TODO",C'150,30,30');
   CrLabel("lic",hx+10,ry+55,"MASTER: "+InpMasterID,clrDimGray,6);
   ActualizarHUD();
}

void ActualizarHUD() {
   ObjectSetString(0,P_TAG+"net",OBJPROP_TEXT, (webConnected ? "RED: ONLINE" : "RED: OFFLINE"));
   ObjectSetInteger(0,P_TAG+"net",OBJPROP_COLOR, (webConnected ? clrLime : clrRed));

   string sMod = fuegoRapido ? "🔥 FUEGO RÁPIDO ACTIVO" : "🔱 MODO SCALING (v78)";
   color cMod = fuegoRapido ? clrOrange : clrWhite;
   ObjectSetString(0,P_TAG+"l_mod",OBJPROP_TEXT, sMod);
   ObjectSetInteger(0,P_TAG+"l_mod",OBJPROP_COLOR, cMod);

   ObjectSetString(0,P_TAG+"l_st",OBJPROP_TEXT, "ESTADO: "+(isBullish?"ALCISTA ▲":"BAJISTA ▼"));
   ObjectSetInteger(0,P_TAG+"l_st",OBJPROP_COLOR, (isBullish?clrLime:clrRed));
   
   ObjectSetString(0,P_TAG+"l_arm",OBJPROP_TEXT, "STRAT: "+(fuegoRapido?"RAFAGA":"ARMADO"));
   ObjectSetInteger(0,P_TAG+"l_arm",OBJPROP_COLOR, (fuegoRapido?clrOrange:clrLime));

   ObjectSetString(0,P_TAG+"b1",OBJPROP_TEXT, "GIRO: "+(giroOn?"ON":"OFF"));
   ObjectSetInteger(0,P_TAG+"b1",OBJPROP_BGCOLOR, (giroOn?C'40,110,50':clrMaroon));
   
   ObjectSetString(0,P_TAG+"b2",OBJPROP_TEXT, "CASCADA: "+(casOn?"ON":"OFF"));
   ObjectSetInteger(0,P_TAG+"b2",OBJPROP_BGCOLOR, (casOn?C'40,110,50':clrMaroon));

   ObjectSetString(0,P_TAG+"l_bl",OBJPROP_TEXT, "BALANCE: $ "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   ObjectSetString(0,P_TAG+"l_eq",OBJPROP_TEXT, "EQUIDAD: $ "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   
   bool showProfit = (fuegoRapido || profitRafaga!=0);
   ObjectSetInteger(0,P_TAG+"l_prf",OBJPROP_TIMEFRAMES, showProfit ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
   ObjectSetInteger(0,P_TAG+"l_prv",OBJPROP_TIMEFRAMES, showProfit ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
   if(showProfit) ObjectSetString(0,P_TAG+"l_prv",OBJPROP_TEXT, "$"+DoubleToString(profitRafaga,2));

   ChartRedraw();
}
   
int OnInit() {
   //--- VALIDACIÓN SUPREME (v1.5) ---
   if(!ValidateLicense(InpMasterID, InpLicKey, (int)AccountInfoInteger(ACCOUNT_LOGIN))) {
      MessageBox("Licencia inválida: " + GetLicenseStatus(), "Kopytrade Sync", MB_OK | MB_ICONERROR);
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   ChartSetInteger(0,CHART_SCALE,4);
   ChartSetInteger(0,CHART_SHOW_OBJECT_DESCR,false);
   CrearHUD(); EventSetTimer(1);
   isFirstRun = true;
   usdMult = InpIsCentAccount ? 100.0 : 1.0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0,P_TAG); EventKillTimer(); }
void OnTick() { 
   //--- CONTROL REMOTO (v1.5) ---
   GetRemoteStatus();
   if(IsRemotePaused()) {
      webConnected = true;
      SyncPositions("PAUSA");
      ActualizarHUD();
      return;
   }

   UpdateFibo(); ManageAmetralladora(); 
   if(InpUseScalp) ShootAmetralladora();
   ProtectPositions(); ActualizarHUD(); 
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == P_TAG+"b1") { giroOn = !giroOn; ActualizarHUD(); }
      else if(sparam == P_TAG+"b2") { casOn = !casOn; ActualizarHUD(); }
      else if(sparam == P_TAG+"panic") { Wipeout(); }
      else if(sparam == P_TAG+"net") { SyncPositions("FORZADO"); } // Forzar sincronización
      
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      ChartRedraw();
   }
}

void OnTimer() { 
   string st = (fuegoRapido ? "FUEGO" : "ARMADO");
   SyncPositions(st);
   webConnected = (g_KopyLastSync > 0 && TimeCurrent() < g_KopyLastSync + 60);
   ActualizarHUD();
}

#define FIBO_NAME P_TAG+"FIBO"

void UpdateFibo() {
   datetime tStart = TimeCurrent() - (InpLookback * 3600);
   int bars = iBarShift(_Symbol, InpOperativeTF, tStart);
   if(bars < 10) bars = 20;
   int hiIdx = iHighest(_Symbol, InpOperativeTF, MODE_HIGH, bars, 0);
   int liIdx = iLowest(_Symbol, InpOperativeTF, MODE_LOW, bars, 0);
   double vHi = iHigh(_Symbol, InpOperativeTF, hiIdx), vLi = iLow(_Symbol, InpOperativeTF, liIdx);
   isBullish = (hiIdx < liIdx);
   if(vHi != lastHi || vLi != lastLi || isFirstRun) {
      isFirstRun = false; lastHi = vHi; lastLi = vLi;
      if(isBullish) { f_p100=vLi; f_p0=vHi; f_t100=iTime(_Symbol,InpOperativeTF,liIdx); f_t0=iTime(_Symbol,InpOperativeTF,hiIdx); } 
      else { f_p100=vHi; f_p0=vLi; f_t100=iTime(_Symbol,InpOperativeTF,hiIdx); f_t0=iTime(_Symbol,InpOperativeTF,liIdx); }
      double diff = f_p0 - f_p100;
      f_p38=f_p100+diff*0.382; f_p50=f_p100+diff*0.500; f_p61=f_p100+diff*0.618;
      DrawFibo(f_p100, f_p0, f_t100, f_t0);
   }
}

void DrawFibo(double p100, double p0, datetime t100, datetime t0) {
   if(ObjectFind(0,FIBO_NAME)<0) {
      ObjectCreate(0,FIBO_NAME,OBJ_FIBO,0,t100,p100,t0,p0);
      ObjectSetInteger(0,FIBO_NAME,OBJPROP_COLOR,CLR_GOLD);
      ObjectSetInteger(0,FIBO_NAME,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,FIBO_NAME,OBJPROP_RAY_RIGHT,true);
      ObjectSetInteger(0,FIBO_NAME,OBJPROP_BACK,true);
      ObjectSetInteger(0,FIBO_NAME,OBJPROP_LEVELS,6);
      ObjectSetDouble(0,FIBO_NAME,OBJPROP_LEVELVALUE,0,0.0);    ObjectSetString(0,FIBO_NAME,OBJPROP_LEVELTEXT,0,"0.0 TARGET");
      ObjectSetDouble(0,FIBO_NAME,OBJPROP_LEVELVALUE,1,0.236);  ObjectSetString(0,FIBO_NAME,OBJPROP_LEVELTEXT,1,"23.6 SCALP START");
      ObjectSetDouble(0,FIBO_NAME,OBJPROP_LEVELVALUE,2,0.382);  ObjectSetString(0,FIBO_NAME,OBJPROP_LEVELTEXT,2,"38.2 SCALP END");
      ObjectSetDouble(0,FIBO_NAME,OBJPROP_LEVELVALUE,3,0.5);    ObjectSetString(0,FIBO_NAME,OBJPROP_LEVELTEXT,3,"50.0 MID");
      ObjectSetDouble(0,FIBO_NAME,OBJPROP_LEVELVALUE,4,0.618);  ObjectSetString(0,FIBO_NAME,OBJPROP_LEVELTEXT,4,"61.8 GOLDEN");
      ObjectSetDouble(0,FIBO_NAME,OBJPROP_LEVELVALUE,5,1.0);    ObjectSetString(0,FIBO_NAME,OBJPROP_LEVELTEXT,5,"100.0 SL HARD");
      for(int i=0; i<6; i++) ObjectSetInteger(0,FIBO_NAME,OBJPROP_LEVELCOLOR,i,CLR_GOLD);
   }
   ObjectMove(0,FIBO_NAME,0,t100,p100);
   ObjectMove(0,FIBO_NAME,1,t0,p0);
}

void ManageAmetralladora() {
   double price = SymbolInfoDouble(_Symbol, isBullish ? SYMBOL_ASK : SYMBOL_BID);
   double tr = MathAbs(f_p0 - f_p100); if(tr <= 0) return;
   double pct = (MathAbs(price - f_p0) / tr) * 100;
   profitRafaga = GetTotalPnL();
   
   int totalOps = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) totalOps++;
   }

   if(pct > InpSL_Pct || profitRafaga >= InpR_ProfitIdeal * usdMult) { Wipeout(); return; }
   
   // Si hay ráfaga activa, no paramos hasta ganar o tocar SL Hard.
   if(totalOps > 0) fuegoRapido = true;
   else fuegoRapido = (pct >= 23.6 && pct <= 38.2);
}

double GetTotalPnL() {
   double p = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) p += pos.Profit() + pos.Swap() + pos.Commission();
   return p;
}

void Wipeout() {
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) trade.PositionClose(pos.Ticket());
}

void ProtectPositions() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) {
         double pUSD = pos.Profit() + pos.Swap() + pos.Commission();
         double curSL = pos.StopLoss(), newSL = curSL;
         double openP = pos.PriceOpen();
         double cp = SymbolInfoDouble(_Symbol, pos.PositionType()==POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK);

         // 1. BREAK-EVEN
         if(pUSD >= InpB1_BE * usdMult) {
            if(pos.PositionType()==POSITION_TYPE_BUY && (curSL < openP)) newSL = openP + 0.30;
            if(pos.PositionType()==POSITION_TYPE_SELL && (curSL > openP || curSL == 0)) newSL = openP - 0.30;
         }
         
         // 2. TRAILING STOP
         if(pUSD >= InpB1_TRA * usdMult) {
            double trailDist = 0.80; 
            if(pos.PositionType()==POSITION_TYPE_BUY && (cp - trailDist > curSL)) newSL = cp - trailDist;
            if(pos.PositionType()==POSITION_TYPE_SELL && (cp + trailDist < curSL || curSL == 0)) newSL = cp + trailDist;
         }

         if(MathAbs(newSL - curSL) > 0.02) {
            trade.PositionModify(pos.Ticket(), NormalizeDouble(newSL, _Digits), 0);
         }
      }
   }
}

void ShootAmetralladora() {
   if(!fuegoRapido) return;
   
   int totalOps = 0;
   double worstPrice = isBullish ? 9999999 : 0;
   double lastLot = InpLots;
   
   for(int i=0; i<PositionsTotal(); i++) {
      if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) {
         totalOps++;
         double op = pos.PriceOpen();
         lastLot = pos.Volume();
         if(isBullish && op < worstPrice) worstPrice = op;
         if(!isBullish && op > worstPrice) worstPrice = op;
      }
   }
   
   if(totalOps >= InpR_MaxOps) return;
   
   double cp = SymbolInfoDouble(_Symbol, isBullish ? SYMBOL_ASK : SYMBOL_BID);
   double ps = (_Digits<=2?1.0:(_Digits==3||_Digits==5?10.0*_Point:_Point));
   
   bool shouldShoot = false;
   double newLot = InpLots;
   
   if(totalOps == 0) {
      // CONFIRMACIÓN M1: Solo entramos si la última vela de 1 min cerró a favor
      double c1 = iClose(_Symbol, PERIOD_M1, 1);
      double o1 = iOpen(_Symbol, PERIOD_M1, 1);
      if(!isBullish && c1 < o1) shouldShoot = true;
      if(isBullish && c1 > o1) shouldShoot = true;
   } else {
      double dist = isBullish ? (worstPrice - cp)/ps : (cp - worstPrice)/ps;
      if(dist >= InpR_DistPips) {
         shouldShoot = true;
         newLot = lastLot * InpR_Mult;
      }
   }
   
   if(shouldShoot) {
      double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double stepL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      newLot = MathFloor(newLot/stepL)*stepL;
      newLot = MathMax(minL, newLot);
      if(isBullish) trade.Buy(newLot); else trade.Sell(newLot);
   }
}
