//+------------------------------------------------------------------+
//| EA Scalping Inteligente v4.8 – MT5 (SL/TP FÍSICOS EN DÓLARES)    |
//| Creado para fijar la pérdida máxima exacta sin depender de ATR   |
//+------------------------------------------------------------------+
#property strict
#property version "4.8"
#include <Trade/Trade.mqh>
CTrade trade;

// ================= GESTIÓN DE RIESGO FÁCIL =================
input double Lote_Fijo          = 0.01;      // 📦 Tamaño del Lote a operar
input double StopLoss_USD       = 6.0;       // 🔴 Límite de Pérdida en USD (Stop Loss Físico)
input double TakeProfit_USD     = 6.0;       // 🟢 Límite de Ganancia en USD (Take Profit Físico)
input int    MagicNumber        = 202509;    // 🔑 Magic Number

// ================= FILTRO DE TENDENCIA (NUEVO) =================
input bool   Usar_Filtro_EMA    = true;      // 📈 Sólo operar a favor de la tendencia
input int    EMA_Period         = 50;        // 📏 Periodo de la línea de Tendencia (EMA)

// ================= ESTRATEGIA MOMENTUM =================
input int    MomentumCandles     = 3;        // Velas a analizar
input int    MomentumRequired    = 2;        // Velas verdes/rojas requeridas
input int    MaxTradesPerSide    = 1;        // Máximo de operaciones a la vez por tipo
input int    CooldownSeconds     = 60;       // Espera entre operaciones

// ================= CORTAFUEGOS DE TIEMPO =================
input int    MaxVelasContra      = 2;        // ⏱️ Cerrar si han pasado X velas y sigue en pérdida

// ================= BREAK EVEN Y TRAILING =================
input bool   EnableBE            = true;     // Activar Break Even
input double BE_Trigger_USD      = 2.5;      // Ganancia en USD para activar BE
input double BE_Cushion_USD      = 0.5;      // Ganancia asegurada en USD en BE

input bool   EnableTrailing      = true;     // Activar Trailing Stop
input double Trail_Trigger_USD   = 2.5;      // Ganancia en USD para activar trailing
input double Trail_Distance_USD  = 2.0;      // Mantener X USD de distancia persiguiendo el precio

// ================= PANEL VISUAL =================
input bool   ShowPanel           = true;     // Mostrar panel

//---------------- GLOBALS ----------------
datetime lastTradeTime = 0;
datetime lastBarTime   = 0;
int emaHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
{
   emaHandle = iMA(_Symbol, _Period, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   if(emaHandle==INVALID_HANDLE) return(INIT_FAILED);
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(emaHandle!=INVALID_HANDLE) IndicatorRelease(emaHandle);
   Comment(""); 
}

double GetEMA()
{
   if(emaHandle==INVALID_HANDLE) return 0.0;
   double buf[];
   if(CopyBuffer(emaHandle,0,0,1,buf)<=0) return 0.0;
   return buf[0];
}

bool CheckMomentum(bool bullish)
{
   if(Bars(_Symbol,_Period) < MomentumCandles+1) return false;
   int count = 0;
   for(int i=1; i<=MomentumCandles; i++) {
      double o = iOpen(_Symbol,_Period,i);
      double c = iClose(_Symbol,_Period,i);
      if(bullish && c>o) count++;
      if(!bullish && c<o) count++;
   }
   return (count >= MomentumRequired);
}

int CountTrades(int type)
{
   int total=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol &&
            PositionGetInteger(POSITION_TYPE)==type)
            total++;
      }
   }
   return total;
}

double USDtoPriceDist(double usd, double lot)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue<=0 || lot<=0) return 0;
   return (usd * tickSize) / (tickValue * lot);
}

void ManageCortafuegos()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int barsOpen = iBarShift(_Symbol,_Period,openTime,false);
      
      if(barsOpen >= MaxVelasContra && profit < 0)
      {
         trade.PositionClose(ticket);
         continue;
      }
   }
}

void ManageBETrailing()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      double profit      = PositionGetDouble(POSITION_PROFIT);
      double openPrice   = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL   = PositionGetDouble(POSITION_SL);
      double currentTP   = PositionGetDouble(POSITION_TP);
      long   type        = PositionGetInteger(POSITION_TYPE);
      double lot         = PositionGetDouble(POSITION_VOLUME);
      double bid         = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask         = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double stopLevel   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double newSL = 0;

      if(EnableBE && profit >= BE_Trigger_USD)
      {
         bool modifyObj = false;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = openPrice + USDtoPriceDist(BE_Cushion_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if(newSL > currentSL && newSL <= (bid - stopLevel)) modifyObj = true;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            newSL = openPrice - USDtoPriceDist(BE_Cushion_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if((currentSL==0 || newSL < currentSL) && newSL >= (ask + stopLevel)) modifyObj = true;
         }
         if(modifyObj) trade.PositionModify(ticket, newSL, currentTP);
      }

      if(EnableTrailing && profit >= Trail_Trigger_USD)
      {
         bool modifyObj = false;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = bid - USDtoPriceDist(Trail_Distance_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if(newSL > currentSL && newSL > openPrice && newSL <= (bid - stopLevel)) modifyObj = true;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            newSL = ask + USDtoPriceDist(Trail_Distance_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if((currentSL==0 || newSL < currentSL) && newSL < openPrice && newSL >= (ask + stopLevel)) modifyObj = true;
         }
         if(modifyObj) trade.PositionModify(ticket, newSL, currentTP);
      }
   }
}

void DrawPanel()
{
   if(!ShowPanel) {
      Comment("");
      return;
   }
   double ema = GetEMA();
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   string trendStr = "Calculando...";
   if(ema > 0) {
       trendStr = (price > ema) ? "ALCISTA (Busca Compras)" : "BAJISTA (Busca Ventas)";
   }

   string text = "╔══════════════════════════════════════════════╗\n";
   text += "║  EA Scalping v4.8 [TP/SL en Dólares Fijos] \n";
   text += "╠══════════════════════════════════════════════╣\n";
   text += "║ Tendencia EMA(50): " + trendStr + "\n";
   text += "║ SL Físico: -$" + DoubleToString(StopLoss_USD, 2) + " | TP Físico: +$" + DoubleToString(TakeProfit_USD, 2) + "\n";
   text += "║ Posiciones Oro: " + IntegerToString(PositionsTotal()) + "\n";
   text += "╚══════════════════════════════════════════════╝\n";
   Comment(text);
}

void OnTick()
{
   ManageBETrailing();
   ManageCortafuegos();
   DrawPanel();

   datetime currentBar = iTime(_Symbol,_Period,0);
   if(currentBar == lastBarTime) return;
   lastBarTime = currentBar;

   if(TimeCurrent() - lastTradeTime < CooldownSeconds) return;

   double ema = GetEMA();
   if(ema <= 0) return;
   
   double priceBID = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double priceASK = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   bool allowBuy = true;
   bool allowSell = true;
   
   if(Usar_Filtro_EMA) {
      if(priceBID < ema) allowBuy = false; // El precio está por debajo de la EMA, no comprar
      if(priceBID > ema) allowSell = false; // El precio está por encima de la EMA, no vender
   }

   double slDist = USDtoPriceDist(StopLoss_USD, Lote_Fijo);
   double tpDist = USDtoPriceDist(TakeProfit_USD, Lote_Fijo);

   // COMPRAS
   if(allowBuy && CheckMomentum(true) && CountTrades(POSITION_TYPE_BUY) < MaxTradesPerSide)
   {
      double sl = NormalizeDouble(priceASK - slDist, _Digits);
      double tp = NormalizeDouble(priceASK + tpDist, _Digits);
      
      if(trade.Buy(Lote_Fijo, _Symbol, priceASK, sl, tp, "COMPRA_MOMENTUM")) {
         lastTradeTime = TimeCurrent();
      }
   }

   // VENTAS
   if(allowSell && CheckMomentum(false) && CountTrades(POSITION_TYPE_SELL) < MaxTradesPerSide)
   {
      double sl = NormalizeDouble(priceBID + slDist, _Digits);
      double tp = NormalizeDouble(priceBID - tpDist, _Digits);
      
      if(trade.Sell(Lote_Fijo, _Symbol, priceBID, sl, tp, "VENTA_MOMENTUM")) {
         lastTradeTime = TimeCurrent();
      }
   }
}
