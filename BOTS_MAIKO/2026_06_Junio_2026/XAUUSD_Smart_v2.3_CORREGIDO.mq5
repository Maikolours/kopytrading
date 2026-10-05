//+------------------------------------------------------------------+
//|                    XAUUSD_Smart_Martingale_v2.mq5                |
//|                MARTINGALA INTELIGENTE CON DETECCIÓN DE TENDENCIA |
//|                  Optimizado para cuenta $500                     |
//+------------------------------------------------------------------+
#property copyright "Smart Martingale v2.0"
#property version   "2.0"
#property description "Sistema adaptativo - Sigue tendencia confirmada"
#property description "Sin bloqueos - Reinicio automático"
#property strict

//+------------------------------------------------------------------+
//| PARÁMETROS PRINCIPALES                                          |
//+------------------------------------------------------------------+
input group "=== CONFIGURACIÓN DE LOTAJE ==="
input double   InitialLot       = 0.01;          // Lotaje inicial (0.01 para $500)
input double   LotIncrement     = 0.01;          // Incremento por nivel
input int      MaxLevels        = 8;             // Máximo niveles (protección)

input group "=== OBJETIVO DE PROFIT ==="
input double   MinProfit        = 1.0;           // Profit mínimo ($)
input double   ProfitMultiplier = 0.5;           // Multiplicador por nivel adicional

input group "=== DETECCIÓN DE TENDENCIA ==="
input int      ADX_Period       = 14;            // Periodo ADX
input double   ADX_Trend        = 25.0;          // ADX > 25 = tendencia fuerte
input double   ADX_Lateral      = 10.0;          // ADX < 10 = lateral (MUY permisivo)
input int      ATR_Period       = 14;            // Periodo ATR
input double   ATR_MinValue     = 0.2;           // ATR mínimo (MUY permisivo)

input group "=== ESTRATEGIA DE GRID ==="
input int      GridDistance     = 35;            // Distancia en pips
input bool     FollowTrend      = true;          // Seguir tendencia confirmada
input int      TrendConfirmBars = 3;             // Velas para confirmar tendencia

input group "=== PROTECCIONES ==="
input double   MaxDrawdownPct   = 35.0;          // Pausa si DD > %
input double   MinMarginLevel   = 120.0;         // Margen mínimo %
input int      MaxSpread        = 150;           // Spread máximo (pips)

input group "=== AVANZADO ==="
input ulong    MagicNumber      = 888999;        // Número mágico
input string   TradeComment     = "SMART_v2";    // Comentario

//+------------------------------------------------------------------+
//| VARIABLES GLOBALES                                              |
//+------------------------------------------------------------------+
int      adxHandle, atrHandle;
double   adxMain[], adxPlus[], adxMinus[];
double   atrValues[];

struct Position
{
   ulong    ticket;
   int      level;
   double   lots;
   double   openPrice;
   ENUM_POSITION_TYPE type;
   datetime openTime;
};

Position positions[];
int      currentLevel = 0;
double   totalProfit = 0.0;
bool     systemPaused = false;
datetime lastCheckTime = 0;
datetime lastTradeTime = 0;

// Variables de tendencia
int      trendDirection = 0;  // 1=alcista, -1=bajista, 0=neutral
int      trendStrength = 0;   // Número de confirmaciones
bool     trendConfirmed = false;

//+------------------------------------------------------------------+
//| INICIALIZACIÓN                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validaciones
   if(InitialLot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
   {
      Print("❌ ERROR: Lotaje inicial muy pequeño");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(_Period != PERIOD_M1)
   {
      Print("⚠️ ADVERTENCIA: Optimizado para M1");
   }
   
   //--- Inicializar indicadores
   adxHandle = iADX(_Symbol, _Period, ADX_Period);
   atrHandle = iATR(_Symbol, _Period, ATR_Period);
   
   if(adxHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
   {
      Print("❌ ERROR: Indicadores no cargados");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(adxMain, true);
   ArraySetAsSeries(adxPlus, true);
   ArraySetAsSeries(adxMinus, true);
   ArraySetAsSeries(atrValues, true);
   
   //--- Banner
   Print("╔════════════════════════════════════════════╗");
   Print("║   SMART MARTINGALE v2.0                    ║");
   Print("╠════════════════════════════════════════════╣");
   Print("║  💰 Optimizado para cuenta $500            ║");
   Print("║  🎯 Sigue tendencia confirmada             ║");
   Print("║  🔄 Sin bloqueos - Reinicio automático     ║");
   Print("╠════════════════════════════════════════════╣");
   Print("║  Lot Inicial: ", InitialLot, "                       ║");
   Print("║  Max Niveles: ", MaxLevels, "                        ║");
   Print("║  Profit Min: $", MinProfit, "                      ║");
   Print("║  Grid: ", GridDistance, " pips                      ║");
   Print("╚════════════════════════════════════════════╝");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DESINICIALIZACIÓN                                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(adxHandle != INVALID_HANDLE) IndicatorRelease(adxHandle);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   Comment("");
}

//+------------------------------------------------------------------+
//| FUNCIÓN PRINCIPAL                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   if(TimeCurrent() - lastCheckTime < 1) return;
   lastCheckTime = TimeCurrent();
   
   //--- Cargar posiciones
   LoadPositions();
   
   //--- Calcular profit
   CalculateTotalProfit();
   
   //--- Verificar si alcanzó profit objetivo
   if(CheckProfitTarget())
   {
      CloseAllPositions("Profit objetivo alcanzado");
      ResetSystem();
      return;
   }
   
   //--- Verificar protecciones
   if(!CheckSafetyLimits())
   {
      if(!systemPaused)
      {
         systemPaused = true;
         Alert("⛔ SISTEMA PAUSADO - Protección activada");
      }
      DisplayInfo();
      return;
   }
   else
   {
      if(systemPaused)
      {
         Print("✅ Sistema reactivado");
         systemPaused = false;
      }
   }
   
   //--- Actualizar análisis de tendencia
   UpdateTrendAnalysis();
   
   //--- Lógica de trading
   if(ArraySize(positions) == 0)
   {
      CheckInitialEntry();
   }
   else
   {
      ManageGrid();
   }
   
   DisplayInfo();
}

//+------------------------------------------------------------------+
//| CARGAR POSICIONES                                               |
//+------------------------------------------------------------------+
void LoadPositions()
{
   ArrayResize(positions, 0);
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      int size = ArraySize(positions);
      ArrayResize(positions, size + 1);
      
      positions[size].ticket = ticket;
      positions[size].lots = PositionGetDouble(POSITION_VOLUME);
      positions[size].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      positions[size].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      positions[size].openTime = (datetime)PositionGetInteger(POSITION_TIME);
      positions[size].level = (int)MathRound((positions[size].lots - InitialLot) / LotIncrement);
   }
   
   currentLevel = ArraySize(positions);
}

//+------------------------------------------------------------------+
//| CALCULAR PROFIT TOTAL                                           |
//+------------------------------------------------------------------+
void CalculateTotalProfit()
{
   totalProfit = 0.0;
   
   for(int i = 0; i < ArraySize(positions); i++)
   {
      if(PositionSelectByTicket(positions[i].ticket))
      {
         totalProfit += PositionGetDouble(POSITION_PROFIT);
         totalProfit += PositionGetDouble(POSITION_SWAP);
      }
   }
}

//+------------------------------------------------------------------+
//| VERIFICAR OBJETIVO DE PROFIT                                    |
//+------------------------------------------------------------------+
bool CheckProfitTarget()
{
   if(ArraySize(positions) == 0) return false;
   
   //--- Profit mínimo + bonus por niveles
   double targetProfit = MinProfit;
   
   if(currentLevel > 3)
   {
      targetProfit += (currentLevel - 3) * ProfitMultiplier;
   }
   
   return (totalProfit >= targetProfit);
}

//+------------------------------------------------------------------+
//| CERRAR TODAS LAS POSICIONES                                     |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   Print("═══════════════════════════════════════");
   Print("🎯 ", reason);
   Print("💰 Profit Total: $", DoubleToString(totalProfit, 2));
   Print("📊 Posiciones: ", ArraySize(positions));
   Print("═══════════════════════════════════════");
   
   int closed = 0;
   
   for(int i = 0; i < ArraySize(positions); i++)
   {
      if(ClosePosition(positions[i].ticket))
         closed++;
   }
   
   Print("✅ Cerradas: ", closed, "/", ArraySize(positions));
}

//+------------------------------------------------------------------+
//| CERRAR POSICIÓN                                                 |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return false;
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = _Symbol;
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (request.type == ORDER_TYPE_SELL) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation = 50;
   request.type_filling = ORDER_FILLING_IOC;
   request.magic = MagicNumber;
   
   return OrderSend(request, result);
}

//+------------------------------------------------------------------+
//| RESETEAR SISTEMA                                                |
//+------------------------------------------------------------------+
void ResetSystem()
{
   ArrayResize(positions, 0);
   currentLevel = 0;
   trendDirection = 0;
   trendStrength = 0;
   trendConfirmed = false;
   lastTradeTime = TimeCurrent();
   
   Print("🔄 Sistema reseteado - Listo para nueva serie");
}

//+------------------------------------------------------------------+
//| VERIFICAR PROTECCIONES                                          |
//+------------------------------------------------------------------+
bool CheckSafetyLimits()
{
   //--- Margen
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(marginLevel > 0 && marginLevel < MinMarginLevel)
   {
      Print("⛔ MARGEN CRÍTICO: ", DoubleToString(marginLevel, 1), "%");
      return false;
   }
   
   //--- Drawdown
   if(MaxDrawdownPct > 0)
   {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double ddPct = ((balance - equity) / balance) * 100.0;
      
      if(ddPct > MaxDrawdownPct)
      {
         Print("⛔ DRAWDOWN: ", DoubleToString(ddPct, 2), "%");
         return false;
      }
   }
   
   //--- Niveles
   if(currentLevel >= MaxLevels)
   {
      Print("⛔ MAX NIVELES: ", MaxLevels);
      return false;
   }
   
   //--- Spread
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   if(spread > MaxSpread)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| ACTUALIZAR ANÁLISIS DE TENDENCIA                                |
//+------------------------------------------------------------------+
void UpdateTrendAnalysis()
{
   if(!UpdateIndicators()) return;
   
   //--- Determinar dirección
   int newDirection = 0;
   
   if(adxMain[0] >= ADX_Trend)
   {
      if(adxPlus[0] > adxMinus[0])
         newDirection = 1;  // Alcista
      else
         newDirection = -1; // Bajista
   }
   
   //--- Confirmar tendencia
   if(newDirection == trendDirection && newDirection != 0)
   {
      trendStrength++;
      if(trendStrength >= TrendConfirmBars)
         trendConfirmed = true;
   }
   else
   {
      trendDirection = newDirection;
      trendStrength = 1;
      trendConfirmed = false;
   }
}

//+------------------------------------------------------------------+
//| ACTUALIZAR INDICADORES                                          |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   return (CopyBuffer(adxHandle, 0, 0, 3, adxMain) >= 3 &&
           CopyBuffer(adxHandle, 1, 0, 3, adxPlus) >= 3 &&
           CopyBuffer(adxHandle, 2, 0, 3, adxMinus) >= 3 &&
           CopyBuffer(atrHandle, 0, 0, 3, atrValues) >= 3);
}

//+------------------------------------------------------------------+
//| VERIFICAR ENTRADA INICIAL                                       |
//+------------------------------------------------------------------+
void CheckInitialEntry()
{
   //--- Evitar operar muy seguido
   if(TimeCurrent() - lastTradeTime < 10) // Reducido a 10 segundos
   {
      Comment("⏳ Esperando 10 segundos desde última operación...");
      return;
   }
   
   if(!UpdateIndicators()) 
   {
      Comment("⚠️ Error cargando indicadores...");
      return;
   }
   
   //--- DIAGNÓSTICO DETALLADO
   string diagnosis = "🔍 DIAGNÓSTICO DE ENTRADA:\n";
   diagnosis += "─────────────────────────────\n";
   
   bool canTrade = true;
   
   //--- Check ADX
   diagnosis += "ADX: " + DoubleToString(adxMain[0], 1);
   if(adxMain[0] < ADX_Lateral)
   {
      diagnosis += " ❌ (< " + DoubleToString(ADX_Lateral, 1) + " = LATERAL)\n";
      canTrade = false;
   }
   else
   {
      diagnosis += " ✅ (Tendencia detectada)\n";
   }
   
   //--- Check ATR
   diagnosis += "ATR: " + DoubleToString(atrValues[0], 2);
   if(atrValues[0] < ATR_MinValue)
   {
      diagnosis += " ❌ (< " + DoubleToString(ATR_MinValue, 2) + " = Baja volatilidad)\n";
      canTrade = false;
   }
   else
   {
      diagnosis += " ✅ (Volatilidad suficiente)\n";
   }
   
   //--- Check Spread
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   diagnosis += "Spread: " + IntegerToString((int)spread) + " pips";
   if(spread > MaxSpread)
   {
      diagnosis += " ❌ (> " + IntegerToString(MaxSpread) + ")\n";
      canTrade = false;
   }
   else
   {
      diagnosis += " ✅\n";
   }
   
   //--- Dirección sugerida
   diagnosis += "─────────────────────────────\n";
   if(adxPlus[0] > adxMinus[0])
      diagnosis += "Dirección sugerida: 📈 BUY\n";
   else
      diagnosis += "Dirección sugerida: 📉 SELL\n";
   
   diagnosis += "─────────────────────────────\n";
   
   if(!canTrade)
   {
      diagnosis += "⏸️ ESPERANDO MEJORES CONDICIONES\n";
      Comment(diagnosis);
      return;
   }
   
   diagnosis += "🚀 CONDICIONES ÓPTIMAS - ABRIENDO...\n";
   Comment(diagnosis);
   
   //--- Determinar dirección
   ENUM_ORDER_TYPE direction;
   
   if(adxPlus[0] > adxMinus[0])
      direction = ORDER_TYPE_BUY;
   else
      direction = ORDER_TYPE_SELL;
   
   OpenPosition(direction, InitialLot, 0);
}

//+------------------------------------------------------------------+
//| GESTIONAR GRID                                                  |
//+------------------------------------------------------------------+
void ManageGrid()
{
   if(ArraySize(positions) == 0) return;
   
   //--- Analizar todas las posiciones para encontrar la más rentable
   double maxProfit = -999999;
   int bestPosIndex = -1;
   ENUM_POSITION_TYPE bestType = POSITION_TYPE_BUY; // Inicializar
   double bestOpenPrice = 0;
   
   for(int i = 0; i < ArraySize(positions); i++)
   {
      if(PositionSelectByTicket(positions[i].ticket))
      {
         double posProfit = PositionGetDouble(POSITION_PROFIT);
         if(posProfit > maxProfit)
         {
            maxProfit = posProfit;
            bestPosIndex = i;
            bestType = positions[i].type;
            bestOpenPrice = positions[i].openPrice;
         }
      }
   }
   
   if(bestPosIndex == -1) return;
   
   //--- Obtener precio actual
   double currentPrice = (bestType == POSITION_TYPE_BUY) ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   //--- Calcular distancia desde la última posición abierta
   Position lastPos = positions[ArraySize(positions) - 1];
   double distance = MathAbs(currentPrice - lastPos.openPrice) / _Point;
   
   if(distance < GridDistance) return;
   
   //--- LÓGICA CORRECTA: Reforzar la dirección que está en PROFIT
   bool shouldOpen = false;
   ENUM_ORDER_TYPE newType = POSITION_TYPE_BUY; // Inicializar
   
   //--- Si la mejor posición está en PROFIT positivo
   if(maxProfit > 0)
   {
      newType = bestType; // MISMA dirección que la ganadora
      
      //--- Verificar que el precio se movió favorablemente
      if(bestType == POSITION_TYPE_BUY && currentPrice > bestOpenPrice)
      {
         shouldOpen = true;
         Print("💡 Reforzando BUY (en profit: $", DoubleToString(maxProfit, 2), ")");
      }
      else if(bestType == POSITION_TYPE_SELL && currentPrice < bestOpenPrice)
      {
         shouldOpen = true;
         Print("💡 Reforzando SELL (en profit: $", DoubleToString(maxProfit, 2), ")");
      }
   }
   else
   {
      //--- Si TODAS están en negativo, usar estrategia según tendencia
      if(trendConfirmed && FollowTrend)
      {
         //--- Si hay tendencia confirmada, seguirla
         if(trendDirection == 1) // Alcista
         {
            newType = ORDER_TYPE_BUY;
            if(currentPrice < lastPos.openPrice) // Retroceso
               shouldOpen = true;
         }
         else if(trendDirection == -1) // Bajista
         {
            newType = ORDER_TYPE_SELL;
            if(currentPrice > lastPos.openPrice) // Retroceso
               shouldOpen = true;
         }
      }
      else
      {
         //--- Sin tendencia y en negativo, abrir CONTRARIA (martingala)
         if(lastPos.type == POSITION_TYPE_BUY && currentPrice < lastPos.openPrice)
         {
            newType = ORDER_TYPE_SELL;
            shouldOpen = true;
            Print("⚠️ Martingala: Todas en negativo, abriendo SELL");
         }
         else if(lastPos.type == POSITION_TYPE_SELL && currentPrice > lastPos.openPrice)
         {
            newType = ORDER_TYPE_BUY;
            shouldOpen = true;
            Print("⚠️ Martingala: Todas en negativo, abriendo BUY");
         }
      }
   }
   
   if(shouldOpen)
   {
      int newLevel = currentLevel;
      double newLot = InitialLot + (newLevel * LotIncrement);
      OpenPosition(newType, newLot, newLevel);
   }
}

//+------------------------------------------------------------------+
//| ABRIR POSICIÓN                                                  |
//+------------------------------------------------------------------+
bool OpenPosition(ENUM_ORDER_TYPE type, double lots, int level)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathMax(minLot, MathMin(maxLot, lots));
   lots = MathFloor(lots / lotStep) * lotStep;
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.type = type;
   request.price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.sl = 0;
   request.tp = 0;
   request.deviation = 50;
   request.type_filling = ORDER_FILLING_IOC;
   request.magic = MagicNumber;
   request.comment = TradeComment + "_L" + IntegerToString(level);
   
   bool sent = OrderSend(request, result);
   
   if(sent && result.retcode == TRADE_RETCODE_DONE)
   {
      string typeStr = (type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
      string trendStr = trendConfirmed ? (trendDirection == 1 ? "📈ALCISTA" : "📉BAJISTA") : "⚖️NEUTRAL";
      
      Print("✅ ", typeStr, " L", level, " | ", DoubleToString(lots, 2), " | ", 
            DoubleToString(request.price, 2), " | ", trendStr);
      
      lastTradeTime = TimeCurrent();
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| MOSTRAR INFORMACIÓN                                             |
//+------------------------------------------------------------------+
void DisplayInfo()
{
   string info = "";
   info += "╔════════════════════════════════════════╗\n";
   info += "║   SMART MARTINGALE v2.0                ║\n";
   info += "╠════════════════════════════════════════╣\n";
   
   if(systemPaused)
   {
      info += "║  ⛔ PAUSADO - PROTECCIÓN               ║\n";
      info += "╠════════════════════════════════════════╣\n";
   }
   
   //--- Cuenta
   info += "║  Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
   info += "║  Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
   
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   string marginColor = (marginLevel > 200) ? "🟢" : (marginLevel > 100) ? "🟡" : "🔴";
   info += "║  " + marginColor + " Margen: " + DoubleToString(marginLevel, 1) + "%\n";
   
   info += "╠════════════════════════════════════════╣\n";
   
   //--- Posiciones
   info += "║  Posiciones: " + IntegerToString(currentLevel) + "/" + IntegerToString(MaxLevels) + "\n";
   
   string profitColor = (totalProfit >= 0) ? "🟢" : "🔴";
   info += "║  " + profitColor + " Profit: $" + DoubleToString(totalProfit, 2) + "\n";
   
   double targetProfit = MinProfit;
   if(currentLevel > 3) targetProfit += (currentLevel - 3) * ProfitMultiplier;
   info += "║  Objetivo: $" + DoubleToString(targetProfit, 2) + "\n";
   
   info += "╠════════════════════════════════════════╣\n";
   
   //--- Tendencia
   if(UpdateIndicators())
   {
      string trendStr;
      if(trendConfirmed)
      {
         trendStr = (trendDirection == 1) ? "📈 ALCISTA CONFIRMADA" : "📉 BAJISTA CONFIRMADA";
      }
      else if(adxMain[0] < ADX_Lateral)
      {
         trendStr = "⏸️ LATERAL (Esperando)";
      }
      else
      {
         trendStr = "⚖️ En confirmación...";
      }
      
      info += "║  " + trendStr + "\n";
      info += "║  ADX: " + DoubleToString(adxMain[0], 1) + " | ATR: " + DoubleToString(atrValues[0], 2) + "\n";
   }
   
   info += "╠════════════════════════════════════════╣\n";
   
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   info += "║  Spread: " + IntegerToString((int)spread) + " pips\n";
   info += "║  " + TimeToString(TimeCurrent(), TIME_MINUTES) + "\n";
   info += "╚════════════════════════════════════════╝";
   
   Comment(info);
}

//+------------------------------------------------------------------+
//| TRANSACCIONES                                                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
      
      if(entry == DEAL_ENTRY_OUT)
      {
         double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
         Print("💰 Cierre | $", DoubleToString(profit, 2));
      }
   }
}
//+------------------------------------------------------------------+
