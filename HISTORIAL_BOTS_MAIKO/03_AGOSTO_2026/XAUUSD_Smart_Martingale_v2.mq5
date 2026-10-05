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
input int      EMA_Period       = 50;            // Periodo EMA Medio Plazo
input ENUM_TIMEFRAMES EMA_Timeframe = PERIOD_H1; // Temporalidad EMA (Medio Plazo)

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
int      adxHandle, atrHandle, emaHandle;
double   adxMain[], adxPlus[], adxMinus[];
double   atrValues[], emaValues[];

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
   emaHandle = iMA(_Symbol, EMA_Timeframe, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   
   if(adxHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE || emaHandle == INVALID_HANDLE)
   {
      Print("❌ ERROR: Indicadores no cargados");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(adxMain, true);
   ArraySetAsSeries(adxPlus, true);
   ArraySetAsSeries(adxMinus, true);
   ArraySetAsSeries(atrValues, true);
   ArraySetAsSeries(emaValues, true);
   
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
   if(emaHandle != INVALID_HANDLE) IndicatorRelease(emaHandle);
   Comment("");
   ObjectsDeleteAll(0, "HUD_");
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
         Print("⛔ SISTEMA PAUSADO - Protección activada");
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
           CopyBuffer(atrHandle, 0, 0, 3, atrValues) >= 3 &&
           CopyBuffer(emaHandle, 0, 0, 3, emaValues) >= 3);
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
   
   //--- Filtro EMA
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool emaBuy = (bid > emaValues[0]);
   bool emaSell = (bid < emaValues[0]);
   
   diagnosis += "EMA " + IntegerToString(EMA_Period) + " (" + EnumToString(EMA_Timeframe) + "): ";
   if(emaBuy) diagnosis += "Alcista\n"; else diagnosis += "Bajista\n";
   
   //--- Dirección sugerida
   diagnosis += "─────────────────────────────\n";
   
   ENUM_ORDER_TYPE direction = ORDER_TYPE_BUY; // Default
   if(adxPlus[0] > adxMinus[0] && emaBuy)
   {
      diagnosis += "Dirección sugerida: 📈 BUY\n";
      direction = ORDER_TYPE_BUY;
   }
   else if(adxPlus[0] < adxMinus[0] && emaSell)
   {
      diagnosis += "Dirección sugerida: 📉 SELL\n";
      direction = ORDER_TYPE_SELL;
   }
   else
   {
      diagnosis += "Dirección sugerida: ⚖️ BLOQUEADO (Tendencia Micro vs Macro choca)\n";
      canTrade = false;
   }
   
   diagnosis += "─────────────────────────────\n";
   
   if(!canTrade)
   {
      diagnosis += "⏸️ ESPERANDO MEJORES CONDICIONES\n";
      // El HUD gráfico lo dibuja DisplayInfo, evitamos usar Comment()
      return;
   }
   
   diagnosis += "🚀 CONDICIONES ÓPTIMAS - ABRIENDO...\n";
   // Comment() evitado
   
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
   ENUM_ORDER_TYPE newType = ORDER_TYPE_BUY; // Corregido: usar ORDER_TYPE
   
   //--- Si la mejor posición está en PROFIT positivo
   if(maxProfit > 0)
   {
      // Convertir POSITION_TYPE a ORDER_TYPE
      newType = (bestType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      
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
//| DIBUJAR ETIQUETA GRAFICA                                        |
//+------------------------------------------------------------------+
void DrawLabel(string name, string text, int x, int y, color c, int size=10, bool bold=false) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Segoe UI Bold" : "Segoe UI");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
}

//+------------------------------------------------------------------+
//| MOSTRAR INFORMACIÓN (HUD GRAFICO)                               |
//+------------------------------------------------------------------+
void DisplayInfo()
{
   Comment(""); // Limpiar comentario antiguo
   int x = 20;
   int y = 20;
   int spacing = 18;
   
   DrawLabel("HUD_Title", "SMART MARTINGALE v2.0", x, y, clrGold, 12, true); y += spacing*2;
   
   if(systemPaused) {
      DrawLabel("HUD_Status", "⛔ PAUSADO - PROTECCIÓN", x, y, clrRed, 11, true); 
   } else {
      DrawLabel("HUD_Status", "✅ SISTEMA ACTIVO", x, y, clrLimeGreen, 11, true); 
   }
   y += spacing*2;
   
   //--- Cuenta
   DrawLabel("HUD_Bal", "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), x, y, clrWhite); y += spacing;
   DrawLabel("HUD_Eq", "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), x, y, clrWhite); y += spacing;
   
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   color mClr = (marginLevel > 200) ? clrLimeGreen : ((marginLevel > 100) ? clrYellow : clrRed);
   DrawLabel("HUD_Marg", "Margen: " + DoubleToString(marginLevel, 1) + "%", x, y, mClr); y += spacing*2;
   
   //--- Posiciones
   DrawLabel("HUD_Pos", "Nivel/Posiciones: " + IntegerToString(currentLevel) + " / " + IntegerToString(MaxLevels), x, y, clrWhite); y += spacing;
   
   color pClr = (totalProfit >= 0) ? clrLimeGreen : clrRed;
   DrawLabel("HUD_Prof", "Profit Flotante: $" + DoubleToString(totalProfit, 2), x, y, pClr, 11, true); y += spacing;
   
   double targetProfit = MinProfit;
   if(currentLevel > 3) targetProfit += (currentLevel - 3) * ProfitMultiplier;
   DrawLabel("HUD_Targ", "Objetivo Escape: $" + DoubleToString(targetProfit, 2), x, y, clrGold); y += spacing*2;
   
   //--- Tendencia
   string trendStr = "Calculando...";
   color tClr = clrGray;
   if(UpdateIndicators()) {
      if(trendConfirmed) {
         trendStr = (trendDirection == 1) ? "📈 ALCISTA CONFIRMADA" : "📉 BAJISTA CONFIRMADA";
         tClr = (trendDirection == 1) ? clrLimeGreen : clrRed;
      } else if(adxMain[0] < ADX_Lateral) {
         trendStr = "⏸️ LATERAL (Esperando)";
         tClr = clrYellow;
      } else {
         trendStr = "⚖️ En confirmación...";
         tClr = clrLightBlue;
      }
      DrawLabel("HUD_ADX", "ADX: " + DoubleToString(adxMain[0], 1) + " | ATR: " + DoubleToString(atrValues[0], 2), x, y, clrSilver); y += spacing;
   }
   DrawLabel("HUD_Trend", "Tendencia: " + trendStr, x, y, tClr, 11, true); y += spacing*2;
   
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   DrawLabel("HUD_Spread", "Spread: " + IntegerToString((int)spread) + " pips", x, y, clrLightGray);
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
