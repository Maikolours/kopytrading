//+------------------------------------------------------------------+
//| EA Scalping Inteligente v5.2 – MT5 (RESCATE MATEMÁTICO 0.02)     |
//+------------------------------------------------------------------+
#property strict
#property version "5.2"
#include <Trade/Trade.mqh>
CTrade trade;

// ================= GESTIÓN DE RIESGO =================
input double RiskPercent        = 0.5;       // % de Riesgo por operación (Calcula lote autom.)
input int    MagicNumber        = 202509;    // Magic Number del bot

// ================= RESCATE MATEMÁTICO (MARTINGALA LEVE) =============
input bool   ActivarRescate     = true;      // 🚑 Activar Operación de Rescate Automática
input double MultiplicadorLote  = 2.0;       // 📦 Multiplicador de lote (ej: 0.01 -> 0.02)
input double DistanciaRescate   = 2.0;       // 📏 Distancia en Dólares ($) para activar el rescate

// ================= META DIARIA =================
input double MetaDiaria_USD      = 25.0;     // 🎯 Ganancia Diaria para apagar el bot ($). 0 = Desactivado.

// ================= FILTRO DE HORARIO =================
input bool   EnableTimeFilter    = true;     // ⏰ Activar filtro de horario
input string Desc1               = "--- MAÑANA ---";
input int    StartHour1          = 9;        // Inicio Mañana (Hora)
input int    StartMinute1        = 0;        // Inicio Mañana (Minuto)
input int    EndHour1            = 14;       // Fin Mañana (Hora)
input int    EndMinute1          = 0;        // Fin Mañana (Minuto)

input string Desc2               = "--- TARDE ---";
input int    StartHour2          = 17;       // Inicio Tarde (Hora)
input int    StartMinute2        = 0;        // Inicio Tarde (Minuto)
input int    EndHour2            = 21;       // Fin Tarde (Hora)
input int    EndMinute2          = 30;       // Fin Tarde (Minuto)

// ================= STOP LOSS Y TAKE PROFIT (ATR) =================
input int    ATR_Period         = 14;        // Periodo del ATR
input double SL_Mult_Forex      = 1.0;       // Stop Loss Forex (Multiplicador ATR)
input double TP_Mult_Forex      = 1.2;       // Take Profit Forex (Multiplicador ATR)
input double SL_Mult_Gold       = 1.3;       // Stop Loss ORO (Multiplicador ATR)
input double TP_Mult_Gold       = 1.0;       // Take Profit ORO (Multiplicador ATR)

// ================= ESTRATEGIA (MOMENTUM) =================
input int    MomentumCandles     = 3;        // Nº Velas a mirar hacia atrás
input int    MomentumRequired    = 2;        // Nº Velas requeridas en la misma dirección
input int    MaxTradesPerSide    = 2;        // Máximo de operaciones a la vez por tipo
input int    CooldownSeconds     = 60;       // Segundos de espera entre operaciones

// ================= CORTAFUEGOS EN DÓLARES =================
input bool   ActivarCortafuegos  = true;     // 🛡️ Activar Cortafuegos en Dólares
input double MaxPerdida_USD      = 6.0;      // 🔴 Cerrar OP si pierde X dólares
input double MaxGanancia_USD     = 6.0;      // 🟢 Cerrar OP si gana X dólares
input int    MaxVelasContra      = 12;       // ⏱️ Cerrar OP estancada si sigue en rojo

// ================= CIERRE POR TIEMPO + BENEFICIO =================
input bool   EnableTimeExit      = true;     // Activar cierre rápido por impaciencia
input int    ExitBars_1          = 3;        // Velas espera 1º cierre
input double ExitProfit_1_EUR    = 1.0;      // Ganancia para 1º cierre ($)
input int    ExitBars_2          = 4;        // Velas espera 2º cierre
input double ExitProfit_2_EUR    = 2.0;      // Ganancia para 2º cierre ($)

// ================= BREAK EVEN Y TRAILING=================
input bool   EnableBE            = true;     // Activar Break Even
input double BE_Trigger_USD      = 2.5;      // Ganancia en dólares para activar BE 
input double BE_Cushion_USD      = 2.0;      // Dólares asegurados en el BE

input bool   EnableTrailing      = true;     // Activar Trailing Stop
input double Trail_Trigger_USD   = 2.5;      // Ganancia en dólares para arrancar Trailing
input double Trail_Distance_USD  = 1.5;      // Distancia de persecución ($)

// ================= PANEL VISUAL =================
input bool   ShowPanel           = true;     // Mostrar panel en el gráfico
input bool   EnableDebug         = false;    // Mostrar mensajes en registro Expertos

//---------------- GLOBALS ----------------
datetime lastTradeTime = 0;
datetime lastBarTime   = 0;
int atrHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
{
   atrHandle = iATR(_Symbol,_Period,ATR_Period);
   if(atrHandle==INVALID_HANDLE) return(INIT_FAILED);
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(atrHandle!=INVALID_HANDLE) IndicatorRelease(atrHandle);
   Comment(""); 
}

double GetATR()
{
   if(atrHandle==INVALID_HANDLE) {
      atrHandle = iATR(_Symbol,_Period,ATR_Period);
      if(atrHandle==INVALID_HANDLE) return 0.0;
   }
   double buf[];
   if(CopyBuffer(atrHandle,0,0,1,buf)<=0) return 0.0;
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

double USDtoPrice(double usd, double lot)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue<=0 || lot<=0) return 0;
   return (usd * tickSize) / (tickValue * lot);
}

double CalculateLot(double slPrice)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk = accountBalance * RiskPercent / 100.0;
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickSize  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double distPips = MathAbs(price - slPrice) / tickSize;
   if(distPips <= 0) distPips = 1;
   if(tickValue <= 0) tickValue = 1;
   double lot = risk / (distPips * tickValue);
   double volMin  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double volMax  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   int digits = (volStep>0) ? (int)MathLog10(1/volStep)+1 : 2;
   lot = NormalizeDouble(lot, digits);
   if(lot < volMin) lot = volMin;
   if(volMax>0 && lot > volMax) lot = volMax;
   return lot;
}

bool IsGoldSymbol(string symbol) { return (StringFind(symbol, "XAU")>=0); }

//+------------------------------------------------------------------+
//| SISTEMA DE RESCATE (NUEVA LÓGICA DE AUDIOS)                      |
//+------------------------------------------------------------------+
void ManageRescate()
{
   if(!ActivarRescate) return;
   
   int buyPositions = 0;
   int sellPositions = 0;
   double profitBuy = 0.0;
   double profitSell = 0.0;
   double firstOpenPriceBuy = 0;
   double firstOpenPriceSell = 0;
   double volumeBuy = 0;
   double volumeSell = 0;

   // 1. Analizamos las posiciones abiertas
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      long type = PositionGetInteger(POSITION_TYPE);
      double p  = PositionGetDouble(POSITION_PROFIT);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      double vol = PositionGetDouble(POSITION_VOLUME);

      if(type == POSITION_TYPE_BUY) {
         buyPositions++;
         profitBuy += p;
         if(buyPositions == 1) { firstOpenPriceBuy = price; volumeBuy = vol; }
      }
      else if(type == POSITION_TYPE_SELL) {
         sellPositions++;
         profitSell += p;
         if(sellPositions == 1) { firstOpenPriceSell = price; volumeSell = vol; }
      }
   }

   // 2. Si hay 1 BUY y va perdiendo -$2.0 (DistanciaRescate), abrimos el rescate a favor de la caída
   if(buyPositions == 1 && profitBuy <= -DistanciaRescate)
   {
      if(TimeCurrent() - lastTradeTime >= CooldownSeconds) // Prevenir spam de órdenes
      {
          double currentBID = SymbolInfoDouble(_Symbol, SYMBOL_BID);
          double newLote = NormalizeDouble(volumeBuy * MultiplicadorLote, 2);
          
          double atr = GetATR();
          double tp = 0;
          double sl = 0;
          if(atr > 0) {
             double tpMult = IsGoldSymbol(_Symbol) ? TP_Mult_Gold : TP_Mult_Forex;
             // Como el precio cae y la compra va perdiendo, vendemos a favor de la caída (SELL) para recuperar
             tp = currentBID - atr * tpMult; 
          }
          
          if(trade.Sell(newLote, _Symbol, currentBID, sl, tp, "RESCATE_SELL")) {
             Print("🆘 RESCATE ACTIVADO (SELL): La Compra iba perdiendo -$2.0. Abriendo Venta de ", newLote, " lotes.");
             lastTradeTime = TimeCurrent();
          }
      }
   }

   // 3. Si hay 1 SELL y va perdiendo -$2.0, abrimos el rescate a favor de la subida
   if(sellPositions == 1 && profitSell <= -DistanciaRescate)
   {
      if(TimeCurrent() - lastTradeTime >= CooldownSeconds)
      {
          double currentASK = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
          double newLote = NormalizeDouble(volumeSell * MultiplicadorLote, 2);
          
          double atr = GetATR();
          double tp = 0;
          double sl = 0;
          if(atr > 0) {
             double tpMult = IsGoldSymbol(_Symbol) ? TP_Mult_Gold : TP_Mult_Forex;
             // Como el precio sube y la venta va perdiendo, compramos a favor de la subida (BUY)
             tp = currentASK + atr * tpMult; 
          }
          
          if(trade.Buy(newLote, _Symbol, currentASK, sl, tp, "RESCATE_BUY")) {
             Print("🆘 RESCATE ACTIVADO (BUY): La Venta iba perdiendo -$2.0. Abriendo Compra de ", newLote, " lotes.");
             lastTradeTime = TimeCurrent();
          }
      }
   }
}

//+------------------------------------------------------------------+
double GetDailyProfit()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime startOfDay = StructToTime(dt);

   HistorySelect(startOfDay, TimeCurrent());
   
   double totalProfit = 0.0;
   int deals = HistoryDealsTotal();
   for(int i=0; i<deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber &&
            HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
         {
            totalProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            totalProfit += HistoryDealGetDouble(ticket, DEAL_SWAP);
            totalProfit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         }
      }
   }
   
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong posTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(posTicket)) {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol) {
            totalProfit += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
   
   return totalProfit;
}

//+------------------------------------------------------------------+
bool IsTradingTime()
{
   if(!EnableTimeFilter) return true;
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentMinutes = dt.hour * 60 + dt.min;
   
   int start1 = StartHour1 * 60 + StartMinute1;
   int end1   = EndHour1 * 60 + EndMinute1;
   
   int start2 = StartHour2 * 60 + StartMinute2;
   int end2   = EndHour2 * 60 + EndMinute2;
   
   if(currentMinutes >= start1 && currentMinutes < end1) return true;
   if(currentMinutes >= start2 && currentMinutes < end2) return true;
   
   return false;
}

//+------------------------------------------------------------------+
void ManageCortafuegos()
{
   if(!ActivarCortafuegos) return;
   
   // Primero, vamos a sumar el beneficio global de TODAS las posiciones de este bot
   // para cerrarlas en bloque si el ESCUDO global o el TP global se alcanza,
   // ideal para cuando tenemos operaciones normales + operaciones de rescate.
   double globalProfit = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      globalProfit += PositionGetDouble(POSITION_PROFIT);
   }
   
   // Si el conjunto de operaciones pierde 6$ (o lo configurado), cerramos todo
   if(MaxPerdida_USD > 0 && globalProfit <= -MaxPerdida_USD) 
   {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket)) continue;
         if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
         trade.PositionClose(ticket);
      }
      return;
   }

   // Si el conjunto de operaciones (original + rescate) llega a ganar 6$, cerramos todo
   if(MaxGanancia_USD > 0 && globalProfit >= MaxGanancia_USD) 
   {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket)) continue;
         if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
         trade.PositionClose(ticket);
      }
      return;
   }
   
   // Limpieza individual por estancamiento de velas
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
            newSL = openPrice + USDtoPrice(BE_Cushion_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if(newSL > currentSL && newSL <= (bid - stopLevel)) modifyObj = true;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            newSL = openPrice - USDtoPrice(BE_Cushion_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if((currentSL==0 || newSL < currentSL) && newSL >= (ask + stopLevel)) modifyObj = true;
         }
         if(modifyObj && trade.PositionModify(ticket, newSL, currentTP)) {
             if(EnableDebug) Print("=== BREAK EVEN APLICADO === -> ", newSL);
         }
      }

      if(EnableTrailing && profit >= Trail_Trigger_USD)
      {
         bool modifyObj = false;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = bid - USDtoPrice(Trail_Distance_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if(newSL > currentSL && newSL > openPrice && newSL <= (bid - stopLevel)) modifyObj = true;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            newSL = ask + USDtoPrice(Trail_Distance_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if((currentSL==0 || newSL < currentSL) && newSL < openPrice && newSL >= (ask + stopLevel)) modifyObj = true;
         }
         if(modifyObj && trade.PositionModify(ticket, newSL, currentTP)) {
             if(EnableDebug) Print("=== TRAILING MOVIDO === -> ", newSL);
         }
      }
   }
}

void ManageTimeExit()
{
   if(!EnableTimeExit) return;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int barsOpen = iBarShift(_Symbol,_Period,openTime,false); 
      double profit = PositionGetDouble(POSITION_PROFIT);

      if(profit <= 0) continue;
      if(barsOpen >= ExitBars_1 && profit >= ExitProfit_1_EUR) { trade.PositionClose(ticket); continue; }
      if(barsOpen >= ExitBars_2 && profit >= ExitProfit_2_EUR) { trade.PositionClose(ticket); continue; }
   }
}

void DrawPanel(double dailyProfit)
{
   if(!ShowPanel) {
      Comment("");
      return;
   }
   
   string timeStatus = IsTradingTime() ? "✅ ACTIVO (En Horario)" : "⏸️ PAUSA (Fuera de Horas)";
   if(!EnableTimeFilter) timeStatus = "✅ HORARIO 24/7";
   
   string dailyStatus = "";
   if(MetaDiaria_USD > 0) {
      if(dailyProfit >= MetaDiaria_USD) dailyStatus = " (🛑 CERRADO POR META DIARIA)";
      else dailyStatus = " / Meta: $" + DoubleToString(MetaDiaria_USD, 2);
   }
   
   string text = "╔══════════════════════════════════════════════╗\n";
   text += "║  EA Scalping v5.2 [Rescate Matemático 🚑] \n";
   text += "╠══════════════════════════════════════════════╣\n";
   text += "║ Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " USD\n";
   text += "║ Beneficio Hoy: $" + DoubleToString(dailyProfit, 2) + dailyStatus + "\n";
   text += "║ Posiciones Oro: " + IntegerToString(PositionsTotal()) + "\n";
   text += "║ Horario: " + timeStatus + "\n";
   text += "╚══════════════════════════════════════════════╝\n";
   Comment(text);
}

void OnTick()
{
   // Primero gestionamos posibles rescates antes que nada
   ManageRescate();

   ManageBETrailing();
   ManageTimeExit(); 
   ManageCortafuegos(); // Ahora el cortafuegos cierra en bloque si se llega a +$6 o -$6
   
   double dailyProfit = GetDailyProfit();
   DrawPanel(dailyProfit);

   datetime currentBar = iTime(_Symbol,_Period,0);
   if(currentBar == lastBarTime) return;
   lastBarTime = currentBar;

   if(MetaDiaria_USD > 0 && dailyProfit >= MetaDiaria_USD) return;
   if(!IsTradingTime()) return; 

   if(TimeCurrent() - lastTradeTime < CooldownSeconds) return;

   double atr = GetATR();
   if(atr <= 0.0) return;
   if(atr < SymbolInfoDouble(_Symbol, SYMBOL_POINT)*50.0) return;

   bool isGold = IsGoldSymbol(_Symbol);
   double slMult = isGold ? SL_Mult_Gold : SL_Mult_Forex;
   double tpMult = isGold ? TP_Mult_Gold : TP_Mult_Forex;
   double price, sl, tp, lot;

   // ENTRADA INICIAL: SI HAY CERO POSICIONES (Si hay alguna, no abrimos entradas normales, dejamos que trabaje el rescate)
   if(PositionsTotal() == 0)
   {
       if(CheckMomentum(true))
       {
          price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
          sl = price - atr * slMult;
          tp = price + atr * tpMult; 
          
          lot = CalculateLot(sl);
          if(lot>0 && trade.Buy(lot, _Symbol, price, sl, tp, "ENTRADA_NORMAL_BUY")) {
             lastTradeTime = TimeCurrent();
          }
       }
       else if(CheckMomentum(false))
       {
          price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
          sl = price + atr * slMult;
          tp = price - atr * tpMult; 
          
          lot = CalculateLot(sl);
          if(lot>0 && trade.Sell(lot, _Symbol, price, sl, tp, "ENTRADA_NORMAL_SELL")) {
             lastTradeTime = TimeCurrent();
          }
       }
   }
}
