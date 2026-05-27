//+------------------------------------------------------------------+
//|              Bitcoin SCALPER v7.2 - LÓGICA DIRECCIÓN MEJORADA    |
//|          Reset dirección al cerrar todo | Verificación 15s      |
//|          BE más rápido | Trailing optimizado | 2 trades smart   |
//+------------------------------------------------------------------+
#property strict
#property version "7.2"
#property description "Scalping BTC - Dirección inteligente + protección mejorada"

#include <Trade/Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| PARÁMETROS DE RIESGO                                              |
//+------------------------------------------------------------------+
input group "=== GESTIÓN DE RIESGO ==="
input double   RiskPercent        = 0.3;       // Riesgo 0.3% = $2.70
input int      MagicNumber        = 207201;    // Número mágico único
input string   SymbolBTC          = "BTCUSD";  // Símbolo Bitcoin

//+------------------------------------------------------------------+
//| STOP LOSS Y TAKE PROFIT                                           |
//+------------------------------------------------------------------+
input group "=== SL/TP ==="
input int      StopLossPips       = 120;       // SL $120
input int      TakeProfitPips     = 280;       // TP $280
input bool     UseATRMultiplier   = true;      // Usar ATR
input int      ATR_Period         = 8;         // ATR rápido
input double   ATR_SL_Mult        = 1.0;       // SL ajustado
input double   ATR_TP_Mult        = 2.0;       // TP ajustado

//+------------------------------------------------------------------+
//| PROTECCIÓN MEJORADA                                               |
//+------------------------------------------------------------------+
input group "=== PROTECCIÓN (OPTIMIZADA) ==="
input double   MaxLossPerTrade    = 2.10;      // Pérdida máx $2.10 ✅
input bool     UseQuickBreakeven  = true;      // Break-even
input double   QuickBE_Profit     = 1.20;      // BE a $1.20 ✅ MÁS RÁPIDO
input double   BE_SafetyMargin    = 0.50;      // Margen BE +$0.50 ✅
input bool     UseTrailingScalp   = true;      // Trailing
input double   TrailingActivation = 2.00;      // Activar a $2.00 ✅ MÁS RÁPIDO
input double   TrailingDistance   = 1.20;      // Distancia $1.20 ✅
input bool     UseSmartExit       = true;      // Smart exit
input int      SmartExitSeconds   = 40;        // 40s estancado
input double   MinProfitForExit   = 1.20;      // Mín $1.20
input bool     UseTimeExit        = true;      // Time exit
input int      MaxTradeMinutes    = 12;        // Máx 12 min

//+------------------------------------------------------------------+
//| FILTROS                                                            |
//+------------------------------------------------------------------+
input group "=== FILTROS ==="
input int      EMA_Fast           = 8;         // EMA rápida
input int      EMA_Slow           = 21;        // EMA lenta
input int      RSI_Period         = 7;         // RSI rápido
input int      RSI_Oversold       = 43;        // Sobreventa
input int      RSI_Overbought     = 57;        // Sobrecompra
input bool     RequireVolumeSpike = false;     // Volumen opcional
input int      VolumeMultiplier   = 120;       // 120%

//+------------------------------------------------------------------+
//| CONTROL DIRECCIÓN INTELIGENTE                                     |
//+------------------------------------------------------------------+
input group "=== CONTROL DIRECCIÓN (MEJORADO) ==="
input int      MaxTrades          = 2;         // Máx 2 trades
input bool     SmartDirection     = true;      // Dirección inteligente ✅
input int      VerificationTime   = 15;        // Verificación 15s ✅
input double   MinATRForTrade     = 30.0;      // ATR mínimo
input int      MaxSpreadPips      = 100;       // Spread máximo
input bool     OneTradePerBar     = false;     // Varias señales/vela

//+------------------------------------------------------------------+
//| MOMENTUM                                                           |
//+------------------------------------------------------------------+
input group "=== MOMENTUM ==="
input bool     RequireMomentum    = true;      // Momentum obligatorio
input int      MomentumBars       = 3;         // 3 velas
input double   MinMomentumPercent = 0.08;      // 0.08%

//+------------------------------------------------------------------+
//| VARIABLES GLOBALES                                                |
//+------------------------------------------------------------------+
datetime lastTradeTime      = 0;
datetime lastCloseTime      = 0;
datetime allClosedTime      = 0;     // ✅ NUEVO: cuando cerró TODO
datetime lastBarTime        = 0;
int      lastTradeDirection = 0;
int      verifiedDirection  = 0;     // ✅ NUEVO: dirección verificada
bool     directionVerified  = false; // ✅ NUEVO: si verificó dirección
int      atrHandle          = INVALID_HANDLE;
int      rsiHandle          = INVALID_HANDLE;
int      emaFastHandle      = INVALID_HANDLE;
int      emaSlowHandle      = INVALID_HANDLE;

struct ScalpStats {
   int totalTrades;
   int wins;
   int losses;
   int breakevens;
   double totalProfit;
   double totalLoss;
   double bestTrade;
   double worstTrade;
   int beActivations;
   int trailingActivations;
   int smartExits;
   int maxLossHits;
   int directionResets;      // ✅ NUEVO: resets de dirección
   int directionVerifications; // ✅ NUEVO: verificaciones
   int buyTrades;
   int sellTrades;
   double avgWinSize;
   double avgLossSize;
} stats;

ulong    posTickets[10];
datetime posOpenTimes[10];
double   posOpenPrices[10];
int      posDirections[10];
double   posHighestProfits[10];
datetime posLastCheckTimes[10];
double   posLastCheckPrices[10];
bool     posBreakevenSet[10];
bool     posTrailingActive[10];
int      positionCount = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   if(!SymbolInfoInteger(SymbolBTC, SYMBOL_TRADE_MODE))
   {
      Alert("❌ Símbolo ", SymbolBTC, " no disponible");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(50);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   atrHandle = iATR(SymbolBTC, PERIOD_CURRENT, ATR_Period);
   rsiHandle = iRSI(SymbolBTC, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
   emaFastHandle = iMA(SymbolBTC, PERIOD_CURRENT, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   emaSlowHandle = iMA(SymbolBTC, PERIOD_CURRENT, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);

   if(atrHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE ||
      emaFastHandle == INVALID_HANDLE || emaSlowHandle == INVALID_HANDLE)
   {
      Print("❌ Error inicializando indicadores");
      return INIT_FAILED;
   }

   ZeroMemory(stats);
   ArrayInitialize(posTickets, 0);
   ArrayInitialize(posOpenTimes, 0);
   ArrayInitialize(posOpenPrices, 0.0);
   ArrayInitialize(posDirections, 0);
   ArrayInitialize(posHighestProfits, 0.0);
   ArrayInitialize(posLastCheckTimes, 0);
   ArrayInitialize(posLastCheckPrices, 0.0);
   ArrayInitialize(posBreakevenSet, false);
   ArrayInitialize(posTrailingActive, false);
   
   // Configurar display visible
   ChartSetInteger(0, CHART_FOREGROUND, false);
   ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, true);

   Print("╔═══════════════════════════════════════════╗");
   Print("║   BITCOIN SCALPER v7.2 - DIRECCIÓN SMART ║");
   Print("╠═══════════════════════════════════════════╣");
   Print("║ 🧠 LÓGICA DIRECCIÓN MEJORADA:             ║");
   Print("║    • Reset al cerrar TODO                 ║");
   Print("║    • Verificación ", VerificationTime, "s obligatoria          ║");
   Print("║    • 1ª op: dirección verificada          ║");
   Print("║    • 2ª op: misma dirección               ║");
   Print("║ 🛡️ PROTECCIÓN OPTIMIZADA:                 ║");
   Print("║    • Pérdida máx: $", MaxLossPerTrade, "                  ║");
   Print("║    • BE: $", QuickBE_Profit, " (margen +$", BE_SafetyMargin, ")             ║");
   Print("║    • Trailing: $", TrailingActivation, " (dist $", TrailingDistance, ")           ║");
   Print("╚═══════════════════════════════════════════╝");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Limpiar objeto de display
   ObjectDelete(0, "BTC_SCALPER_INFO");
   
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
   if(emaFastHandle != INVALID_HANDLE) IndicatorRelease(emaFastHandle);
   if(emaSlowHandle != INVALID_HANDLE) IndicatorRelease(emaSlowHandle);

   double winRate = (stats.totalTrades > 0) ? (double)stats.wins/stats.totalTrades*100 : 0;
   stats.avgWinSize = (stats.wins > 0) ? stats.totalProfit/stats.wins : 0;
   stats.avgLossSize = (stats.losses > 0) ? stats.totalLoss/stats.losses : 0;
   
   double buyPercent = (stats.totalTrades > 0) ? (double)stats.buyTrades/stats.totalTrades*100 : 0;
   double sellPercent = (stats.totalTrades > 0) ? (double)stats.sellTrades/stats.totalTrades*100 : 0;

   Print("╔═══════════════════════════════════════════╗");
   Print("║   ESTADÍSTICAS FINALES v7.2               ║");
   Print("╠═══════════════════════════════════════════╣");
   Print("║ Total trades: ", stats.totalTrades, "                         ║");
   Print("║ ✅ Ganados: ", stats.wins, " (", DoubleToString(winRate,1), "%)              ║");
   Print("║ ❌ Perdidos: ", stats.losses, "                           ║");
   Print("║ 📈 BUY: ", stats.buyTrades, " (", DoubleToString(buyPercent,1), "%)                  ║");
   Print("║ 📉 SELL: ", stats.sellTrades, " (", DoubleToString(sellPercent,1), "%)                 ║");
   Print("║ 💰 Avg win: $", DoubleToString(stats.avgWinSize,2), "                   ║");
   Print("║ 💸 Avg loss: $", DoubleToString(stats.avgLossSize,2), "                  ║");
   Print("╠═══════════════════════════════════════════╣");
   Print("║ 🧠 Dirección resets: ", stats.directionResets, "                ║");
   Print("║ ✅ Verificaciones: ", stats.directionVerifications, "                  ║");
   Print("║ 🛡️ BE activados: ", stats.beActivations, "                      ║");
   Print("║ 📈 Trailing activados: ", stats.trailingActivations, "                 ║");
   Print("║ 🚨 Pérdida máx hits: ", stats.maxLossHits, "                  ║");
   Print("╚═══════════════════════════════════════════╝");
}

//+------------------------------------------------------------------+
double GetATR()
{
   double buf[1];
   if(CopyBuffer(atrHandle, 0, 0, 1, buf) <= 0) return 0.0;
   return buf[0];
}

double GetRSI()
{
   double buf[1];
   if(CopyBuffer(rsiHandle, 0, 0, 1, buf) <= 0) return 50.0;
   return buf[0];
}

bool GetEMAs(double &fast, double &slow)
{
   double bufF[2], bufS[2];
   if(CopyBuffer(emaFastHandle, 0, 0, 2, bufF) < 2) return false;
   if(CopyBuffer(emaSlowHandle, 0, 0, 2, bufS) < 2) return false;
   
   fast = bufF[0];
   slow = bufS[0];
   return true;
}

//+------------------------------------------------------------------+
bool CheckMomentum(bool forBuy)
{
   if(!RequireMomentum) return true;

   double prices[];
   ArraySetAsSeries(prices, true);
   
   if(CopyClose(SymbolBTC, PERIOD_CURRENT, 0, MomentumBars + 1, prices) < MomentumBars + 1)
      return false;

   double movePercent = MathAbs(prices[0] - prices[MomentumBars]) / prices[MomentumBars] * 100;

   if(movePercent < MinMomentumPercent) return false;

   if(forBuy)
      return (prices[0] > prices[MomentumBars]);
   else
      return (prices[0] < prices[MomentumBars]);
}

//+------------------------------------------------------------------+
bool CheckVolumeSpike()
{
   if(!RequireVolumeSpike) return true;

   long volumes[];
   ArraySetAsSeries(volumes, true);
   
   if(CopyTickVolume(SymbolBTC, PERIOD_CURRENT, 0, 20, volumes) < 20)
      return false;

   long avgVolume = 0;
   for(int i = 1; i < 20; i++)
      avgVolume += volumes[i];
   avgVolume /= 19;

   return (volumes[0] > avgVolume * VolumeMultiplier / 100);
}

//+------------------------------------------------------------------+
bool CheckSpread()
{
   double spread = SymbolInfoInteger(SymbolBTC, SYMBOL_SPREAD) * SymbolInfoDouble(SymbolBTC, SYMBOL_POINT);
   return (spread <= MaxSpreadPips);
}

//+------------------------------------------------------------------+
//| VERIFICAR DIRECCIÓN DEL MERCADO                                   |
//+------------------------------------------------------------------+
int GetMarketDirection()
{
   double emaFast, emaSlow;
   if(!GetEMAs(emaFast, emaSlow)) return 0;

   double rsi = GetRSI();
   
   // Dirección alcista clara
   if(emaFast > emaSlow && rsi > 50)
      return 1;
   
   // Dirección bajista clara
   if(emaFast < emaSlow && rsi < 50)
      return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
int GetOpenPositionsDirection()
{
   if(positionCount == 0) return 0;
   return posDirections[0];
}

//+------------------------------------------------------------------+
bool CheckScalpSignal(bool &isBuySignal)
{
   double atr = GetATR();
   if(atr < MinATRForTrade) return false;

   if(!CheckSpread()) return false;

   double emaFast, emaSlow;
   if(!GetEMAs(emaFast, emaSlow)) return false;

   double rsi = GetRSI();

   // COMPRA
   bool buyConditions = true;
   buyConditions = buyConditions && (emaFast > emaSlow);
   buyConditions = buyConditions && (rsi > RSI_Oversold);
   buyConditions = buyConditions && CheckVolumeSpike();
   buyConditions = buyConditions && CheckMomentum(true);

   // VENTA
   bool sellConditions = true;
   sellConditions = sellConditions && (emaFast < emaSlow);
   sellConditions = sellConditions && (rsi < RSI_Overbought);
   sellConditions = sellConditions && CheckVolumeSpike();
   sellConditions = sellConditions && CheckMomentum(false);

   //=== LÓGICA DIRECCIÓN INTELIGENTE ===
   if(SmartDirection)
   {
      int openDir = GetOpenPositionsDirection();
      
      if(positionCount == 0)
      {
         // NO hay posiciones: verificar si pasó tiempo desde cierre
         if(allClosedTime > 0)
         {
            int timeSinceClose = (int)(TimeCurrent() - allClosedTime);
            
            if(timeSinceClose < VerificationTime)
            {
               // Aún en periodo de verificación
               return false;
            }
            
            // Ya pasaron 15s: verificar dirección si no se ha hecho
            if(!directionVerified)
            {
               verifiedDirection = GetMarketDirection();
               if(verifiedDirection != 0)
               {
                  directionVerified = true;
                  stats.directionVerifications++;
                  Print("✅ Dirección verificada después ", VerificationTime, "s: ", 
                        (verifiedDirection == 1 ? "ALCISTA" : "BAJISTA"));
               }
               else
               {
                  Print("⏳ Sin dirección clara, esperando...");
                  return false;
               }
            }
            
            // Permitir solo señales en dirección verificada
            if(verifiedDirection == 1 && !buyConditions)
            {
               Print("🚫 Solo se permiten BUYs (dirección verificada)");
               return false;
            }
            if(verifiedDirection == -1 && !sellConditions)
            {
               Print("🚫 Solo se permiten SELLs (dirección verificada)");
               return false;
            }
         }
      }
      else if(positionCount == 1)
      {
         // YA hay 1 posición: segunda debe ser MISMA dirección
         if(openDir == 1) // Hay BUY
         {
            if(sellConditions)
            {
               Print("🚫 SELL bloqueada - Ya hay BUY abierta");
            }
            sellConditions = false;
         }
         else if(openDir == -1) // Hay SELL
         {
            if(buyConditions)
            {
               Print("🚫 BUY bloqueada - Ya hay SELL abierta");
            }
            buyConditions = false;
         }
      }
      else if(positionCount >= 2)
      {
         // Ya hay 2 posiciones: no abrir más
         return false;
      }
   }

   if(buyConditions && !sellConditions)
   {
      isBuySignal = true;
      return true;
   }
   else if(sellConditions && !buyConditions)
   {
      isBuySignal = false;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
double CalculateLot(double entryPrice, double slPrice)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0) return 0.01;

   double risk = balance * RiskPercent / 100.0;
   double tickSize = SymbolInfoDouble(SymbolBTC, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(SymbolBTC, SYMBOL_TRADE_TICK_VALUE);
   
   if(tickSize <= 0 || tickValue <= 0) return 0.01;

   double ticks = MathAbs(entryPrice - slPrice) / tickSize;
   if(ticks <= 0) ticks = 1;

   double lot = risk / (ticks * tickValue);

   double minLot = SymbolInfoDouble(SymbolBTC, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(SymbolBTC, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(SymbolBTC, SYMBOL_VOLUME_STEP);

   lot = MathMax(minLot, MathMin(lot, maxLot));
   if(step > 0) lot = MathRound(lot / step) * step;

   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
bool ExecuteScalpTrade(bool isBuy)
{
   double atr = GetATR();
   double price, sl, tp;
   
   if(isBuy)
   {
      price = SymbolInfoDouble(SymbolBTC, SYMBOL_ASK);
      
      if(UseATRMultiplier)
      {
         sl = price - atr * ATR_SL_Mult;
         tp = price + atr * ATR_TP_Mult;
      }
      else
      {
         sl = price - StopLossPips;
         tp = price + TakeProfitPips;
      }
   }
   else
   {
      price = SymbolInfoDouble(SymbolBTC, SYMBOL_BID);
      
      if(UseATRMultiplier)
      {
         sl = price + atr * ATR_SL_Mult;
         tp = price - atr * ATR_TP_Mult;
      }
      else
      {
         sl = price + StopLossPips;
         tp = price - TakeProfitPips;
      }
   }

   double lot = CalculateLot(price, sl);
   
   Print("⚡ SCALP ", (isBuy?"BUY":"SELL"), " #", stats.totalTrades+1);
   Print("   Entry: $", DoubleToString(price,2));
   Print("   SL: $", DoubleToString(sl,2), " | TP: $", DoubleToString(tp,2));

   bool result = isBuy ? trade.Buy(lot, SymbolBTC, price, sl, tp, "Scalp BUY v7.2")
                       : trade.Sell(lot, SymbolBTC, price, sl, tp, "Scalp SELL v7.2");

   if(result)
   {
      if(positionCount < 10)
      {
         posTickets[positionCount] = trade.ResultOrder();
         posOpenTimes[positionCount] = TimeCurrent();
         posOpenPrices[positionCount] = price;
         posDirections[positionCount] = isBuy ? 1 : -1;
         posHighestProfits[positionCount] = 0;
         posLastCheckTimes[positionCount] = TimeCurrent();
         posLastCheckPrices[positionCount] = price;
         posBreakevenSet[positionCount] = false;
         posTrailingActive[positionCount] = false;
         positionCount++;
      }
      
      stats.totalTrades++;
      if(isBuy) stats.buyTrades++;
      else stats.sellTrades++;
      
      lastTradeTime = TimeCurrent();
      lastTradeDirection = isBuy ? 1 : -1;
      Print("✅ Ejecutado - Ticket #", trade.ResultOrder());
      return true;
   }
   else
   {
      Print("❌ Error: ", GetLastError());
      return false;
   }
}

//+------------------------------------------------------------------+
void ManageScalpPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != SymbolBTC) continue;

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double profit = PositionGetDouble(POSITION_PROFIT);
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);

      double currentPrice = (type == POSITION_TYPE_BUY) ? 
                           SymbolInfoDouble(SymbolBTC, SYMBOL_BID) :
                           SymbolInfoDouble(SymbolBTC, SYMBOL_ASK);

      int holdTime = (int)(TimeCurrent() - openTime);
      bool shouldClose = false;
      string closeReason = "";

      int posIdx = -1;
      for(int j = 0; j < positionCount; j++)
      {
         if(posTickets[j] == ticket)
         {
            posIdx = j;
            break;
         }
      }

      if(posIdx < 0) continue;

      //--- PÉRDIDA MÁXIMA $2.10
      if(profit <= -MaxLossPerTrade)
      {
         shouldClose = true;
         closeReason = StringFormat("PÉRDIDA MÁX -$%.2f", MaxLossPerTrade);
         stats.maxLossHits++;
      }

      //--- BREAK-EVEN $1.20 CON MARGEN $0.50
      if(!shouldClose && UseQuickBreakeven && profit >= QuickBE_Profit && !posBreakevenSet[posIdx])
      {
         if(type == POSITION_TYPE_BUY && sl < entry)
         {
            double newSL = entry + BE_SafetyMargin;
            if(trade.PositionModify(ticket, newSL, tp))
            {
               Print("🛡️ BE #", ticket, " | $", DoubleToString(profit,2), " → SL +$", BE_SafetyMargin);
               posBreakevenSet[posIdx] = true;
               stats.beActivations++;
            }
         }
         else if(type == POSITION_TYPE_SELL && (sl > entry || sl == 0))
         {
            double newSL = entry - BE_SafetyMargin;
            if(trade.PositionModify(ticket, newSL, tp))
            {
               Print("🛡️ BE #", ticket, " | $", DoubleToString(profit,2), " → SL -$", BE_SafetyMargin);
               posBreakevenSet[posIdx] = true;
               stats.beActivations++;
            }
         }
      }

      //--- TRAILING $2.00
      if(!shouldClose && UseTrailingScalp && profit >= TrailingActivation)
      {
         double newSL = 0;
         bool shouldModify = false;

         if(type == POSITION_TYPE_BUY)
         {
            newSL = currentPrice - TrailingDistance;
            if(newSL > sl && newSL > entry)
               shouldModify = true;
         }
         else
         {
            newSL = currentPrice + TrailingDistance;
            if(newSL < sl || sl == 0)
               shouldModify = true;
         }

         if(shouldModify)
         {
            if(trade.PositionModify(ticket, newSL, tp))
            {
               if(!posTrailingActive[posIdx])
               {
                  Print("📈 Trailing #", ticket, " | $", DoubleToString(profit,2));
                  posTrailingActive[posIdx] = true;
                  stats.trailingActivations++;
               }
            }
         }
      }

      //--- SMART EXIT
      if(!shouldClose && UseSmartExit && profit >= MinProfitForExit)
      {
         int timeSinceCheck = (int)(TimeCurrent() - posLastCheckTimes[posIdx]);
         double priceMove = MathAbs(currentPrice - posLastCheckPrices[posIdx]);

         if(timeSinceCheck >= SmartExitSeconds && priceMove < 10)
         {
            shouldClose = true;
            closeReason = "Smart Exit";
            stats.smartExits++;
         }

         if(timeSinceCheck >= SmartExitSeconds)
         {
            posLastCheckTimes[posIdx] = TimeCurrent();
            posLastCheckPrices[posIdx] = currentPrice;
         }
      }

      //--- TIME EXIT
      if(!shouldClose && UseTimeExit && holdTime >= MaxTradeMinutes * 60)
      {
         if(profit > 0)
         {
            shouldClose = true;
            closeReason = "Time Exit";
         }
      }

      //--- CERRAR
      if(shouldClose)
      {
         if(trade.PositionClose(ticket))
         {
            Print("🚪 ", closeReason, " #", ticket, " | $", DoubleToString(profit,2), " | ", holdTime/60, "min");
            
            if(profit > 0)
            {
               stats.wins++;
               stats.totalProfit += profit;
               if(profit > stats.bestTrade) stats.bestTrade = profit;
            }
            else if(profit < 0)
            {
               stats.losses++;
               stats.totalLoss += MathAbs(profit);
               if(profit < stats.worstTrade) stats.worstTrade = profit;
            }
            else
               stats.breakevens++;

            lastCloseTime = TimeCurrent();

            // Remover de arrays
            for(int k = posIdx; k < positionCount - 1; k++)
            {
               posTickets[k] = posTickets[k + 1];
               posOpenTimes[k] = posOpenTimes[k + 1];
               posOpenPrices[k] = posOpenPrices[k + 1];
               posDirections[k] = posDirections[k + 1];
               posHighestProfits[k] = posHighestProfits[k + 1];
               posLastCheckTimes[k] = posLastCheckTimes[k + 1];
               posLastCheckPrices[k] = posLastCheckPrices[k + 1];
               posBreakevenSet[k] = posBreakevenSet[k + 1];
               posTrailingActive[k] = posTrailingActive[k + 1];
            }
            positionCount--;
            
            //=== RESET DIRECCIÓN SI CERRÓ TODO ===
            if(positionCount == 0)
            {
               allClosedTime = TimeCurrent();
               verifiedDirection = 0;
               directionVerified = false;
               stats.directionResets++;
               Print("🔄 RESET dirección - Todas posiciones cerradas");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
int CountPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == SymbolBTC)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(_Symbol != SymbolBTC) return;

   ManageScalpPositions();

   if(CountPositions() >= MaxTrades) return;

   if(OneTradePerBar)
   {
      datetime currentBar = iTime(SymbolBTC, PERIOD_CURRENT, 0);
      if(currentBar == lastBarTime) return;
   }

   bool isBuySignal = false;
   if(CheckScalpSignal(isBuySignal))
   {
      if(ExecuteScalpTrade(isBuySignal))
      {
         if(OneTradePerBar)
            lastBarTime = iTime(SymbolBTC, PERIOD_CURRENT, 0);
      }
   }

   // Display
   int openPos = CountPositions();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double pnl = equity - balance;

   string display = "🧠 BTC SCALPER v7.2 DIRECCIÓN SMART\n";
   display += "═══════════════════════════════\n";
   display += "📊 Posiciones: " + IntegerToString(openPos) + "/" + IntegerToString(MaxTrades);
   if(openPos > 0)
   {
      int dir = GetOpenPositionsDirection();
      display += " (" + (dir == 1 ? "BUY" : dir == -1 ? "SELL" : "?") + ")";
   }
   else if(directionVerified)
   {
      display += " [✅" + (verifiedDirection == 1 ? "↗️" : "↘️") + "]";
   }
   else if(allClosedTime > 0 && (TimeCurrent() - allClosedTime) < VerificationTime)
   {
      int remaining = VerificationTime - (int)(TimeCurrent() - allClosedTime);
      display += " [⏳" + IntegerToString(remaining) + "s]";
   }
   display += "\n💰 Balance: $" + DoubleToString(balance, 2) + "\n";
   display += "📈 P&L: $" + DoubleToString(pnl, 2) + "\n";
   display += "───────────────────────────────\n";
   display += "🎯 Trades: " + IntegerToString(stats.totalTrades);
   if(stats.totalTrades > 0)
   {
      display += " (📈" + IntegerToString(stats.buyTrades) + " 📉" + IntegerToString(stats.sellTrades) + ")";
   }
   display += "\n";
   display += "W:" + IntegerToString(stats.wins) + " L:" + IntegerToString(stats.losses);
   if(stats.totalTrades > 0)
   {
      double wr = (double)stats.wins/stats.totalTrades*100;
      display += " (" + DoubleToString(wr, 1) + "%)";
   }
   display += "\n";
   display += "🔄 Resets:" + IntegerToString(stats.directionResets);
   display += " | 🛡️BE:" + IntegerToString(stats.beActivations);
   display += " | 📈Trail:" + IntegerToString(stats.trailingActivations) + "\n";
   display += "───────────────────────────────\n";
   display += "ATR: " + DoubleToString(GetATR(), 2) + " | RSI: " + DoubleToString(GetRSI(), 1);

   // Display usando label visible
   string labelName = "BTC_SCALPER_INFO";
   
   if(ObjectFind(0, labelName) < 0)
   {
      ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, labelName, OBJPROP_FONT, "Courier New");
   }
   
   ObjectSetString(0, labelName, OBJPROP_TEXT, display);
   ChartRedraw();
}
//+------------------------------------------------------------------+
