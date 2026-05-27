//+------------------------------------------------------------------+
//|               UltraFastMartingale_FIXED.mq5                     |
//|               Versión FINAL - Sin errores                       |
//+------------------------------------------------------------------+
#property copyright "Ultra Fast Martingale FIXED"
#property version   "2.0"
#property strict

#include <Trade/Trade.mqh>

// ============ PARÁMETROS AGRESIVOS ============
input double   LotSize      = 0.01;     // Lote inicial
input double   Multiplier   = 1.5;      // Multiplicador
input int      MaxTrades    = 4;        // Máximo operaciones
input int      DistancePips = 3;        // Distancia entre trades (PIPS)
input double   TakeProfit   = 2.5;      // TP en pips
input double   StopLoss     = 10.0;     // SL en pips

// ============ VARIABLES ============
CTrade trade;
double point;
int myMagic = 999000;  // Cambiado para evitar conflictos
int currentLevel = 0;
double basePrice = 0;
int currentDirection = 0;
datetime lastEntryTime = 0;
double totalProfit = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   trade.SetExpertMagicNumber(myMagic);
   
   Print("====================================");
   Print("ULTRA FAST MARTINGALE ACTIVADO");
   Print("Símbolo: ", _Symbol);
   Print("Lote: ", LotSize);
   Print("Multiplicador: ", Multiplier);
   Print("Máx trades: ", MaxTrades);
   Print("====================================");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Si no hay operaciones, buscar señal
   if(currentLevel == 0)
   {
      FindSignal();
   }
   else
   {
      ManageOpenTrades();
   }
}

//+------------------------------------------------------------------+
//| Buscar señal de entrada                                          |
//+------------------------------------------------------------------+
void FindSignal()
{
   // Esperar al menos 10 segundos entre ciclos
   if(TimeCurrent() - lastEntryTime < 10) return;
   
   double maFast = GetMA(5, 0);   // MA rápida
   double maSlow = GetMA(20, 0);  // MA lenta
   double maFastPrev = GetMA(5, 1);
   double maSlowPrev = GetMA(20, 1);
   
   // Señal de COMPRA: MA rápida cruza por encima de MA lenta
   if(maFastPrev <= maSlowPrev && maFast > maSlow)
   {
      StartNewCycle(ORDER_TYPE_BUY);
   }
   // Señal de VENTA: MA rápida cruza por debajo de MA lenta
   else if(maFastPrev >= maSlowPrev && maFast < maSlow)
   {
      StartNewCycle(ORDER_TYPE_SELL);
   }
}

//+------------------------------------------------------------------+
//| Obtener valor de Media Móvil (CORREGIDO)                        |
//+------------------------------------------------------------------+
double GetMA(int period, int shift)
{
   double maArray[];
   int maHandle = iMA(_Symbol, PERIOD_M1, period, 0, MODE_SMA, PRICE_CLOSE);
   
   if(maHandle != INVALID_HANDLE)
   {
      if(CopyBuffer(maHandle, 0, shift, 1, maArray) > 0)
      {
         return maArray[0];
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Iniciar nuevo ciclo                                              |
//+------------------------------------------------------------------+
void StartNewCycle(ENUM_ORDER_TYPE type)
{
   currentLevel = 1;
   currentDirection = (type == ORDER_TYPE_BUY) ? 1 : -1;
   
   if(type == ORDER_TYPE_BUY)
   {
      basePrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      OpenTrade(type, CalculateLot(currentLevel), currentLevel);
      Print("NUEVO CICLO COMPRA | Precio: ", basePrice);
   }
   else
   {
      basePrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      OpenTrade(type, CalculateLot(currentLevel), currentLevel);
      Print("NUEVO CICLO VENTA | Precio: ", basePrice);
   }
   
   lastEntryTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Calcular lote para nivel                                         |
//+------------------------------------------------------------------+
double CalculateLot(int level)
{
   // Lotes controlados: nivel 1=0.01, nivel 2=0.015, nivel 3=0.02, nivel 4=0.025
   double lot = LotSize * (1 + (level-1) * 0.5);
   lot = NormalizeDouble(lot, 2);
   return lot;
}

//+------------------------------------------------------------------+
//| Gestionar operaciones abiertas                                   |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   // 1. Verificar si necesitamos abrir nueva operación
   double currentPrice;
   if(currentDirection == 1)
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   else
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // Convertir pips a puntos (en XAUUSD: 1 pip = 10 puntos)
   double distancePoints = DistancePips * 10 * currentLevel;
   double actualDistance = MathAbs(currentPrice - basePrice);
   
   if(actualDistance >= distancePoints && currentLevel < MaxTrades)
   {
      // Esperar 3 segundos entre entradas
      if(TimeCurrent() - lastEntryTime >= 3)
      {
         currentLevel++;
         ENUM_ORDER_TYPE type = (currentDirection == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
         OpenTrade(type, CalculateLot(currentLevel), currentLevel);
         lastEntryTime = TimeCurrent();
      }
   }
   
   // 2. Verificar cierres y reversiones
   CheckForClosures();
   CheckForReversal();
}

//+------------------------------------------------------------------+
//| Abrir operación                                                  |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, double lot, int level)
{
   double price, sl, tp;
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   if(type == ORDER_TYPE_BUY)
   {
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl = price - (StopLoss * 10 * point);  // Convertir pips a puntos
      tp = price + (TakeProfit * 10 * point);
      
      sl = NormalizeDouble(sl, digits);
      tp = NormalizeDouble(tp, digits);
      
      if(trade.Buy(lot, _Symbol, price, sl, tp, "Level" + IntegerToString(level)))
      {
         Print("✅ COMPRA Nivel ", level, " | Lote: ", lot);
      }
   }
   else
   {
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl = price + (StopLoss * 10 * point);
      tp = price - (TakeProfit * 10 * point);
      
      sl = NormalizeDouble(sl, digits);
      tp = NormalizeDouble(tp, digits);
      
      if(trade.Sell(lot, _Symbol, price, sl, tp, "Level" + IntegerToString(level)))
      {
         Print("✅ VENTA Nivel ", level, " | Lote: ", lot);
      }
   }
}

//+------------------------------------------------------------------+
//| Verificar cierres                                                |
//+------------------------------------------------------------------+
void CheckForClosures()
{
   int openTrades = 0;
   totalProfit = 0;
   
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != myMagic) continue;
      
      totalProfit += PositionGetDouble(POSITION_PROFIT);
      openTrades++;
   }
   
   // Si no hay operaciones, resetear ciclo
   if(openTrades == 0 && currentLevel > 0)
   {
      Print("Ciclo completado. Profit: $", totalProfit);
      currentLevel = 0;
   }
}

//+------------------------------------------------------------------+
//| Verificar reversión del mercado                                 |
//+------------------------------------------------------------------+
void CheckForReversal()
{
   if(currentLevel == 0) return;
   
   double currentPrice;
   if(currentDirection == 1)
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   else
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // Calcular distancia desde el precio base en pips
   double distancePips = MathAbs(currentPrice - basePrice) / (10 * point);
   
   // Si el mercado se revierte más de 8 pips, cerrar operaciones ganadoras
   if(distancePips >= 8)
   {
      CloseProfitableTrades();
   }
   
   // Si el mercado se revierte más de 15 pips, cerrar TODO
   if(distancePips >= 15)
   {
      CloseAllTrades();
      currentLevel = 0;
      Print("🚨 REVERSIÓN FUERTE - TODO CERRADO");
   }
}

//+------------------------------------------------------------------+
//| Cerrar operaciones ganadoras                                    |
//+------------------------------------------------------------------+
void CloseProfitableTrades()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != myMagic) continue;
      
      double profit = PositionGetDouble(POSITION_PROFIT);
      
      // Cerrar operaciones con ganancia > $1
      if(profit > 1.0)
      {
         trade.PositionClose(ticket);
         Print("💰 Cierre preventivo: $", profit);
      }
   }
}

//+------------------------------------------------------------------+
//| Cerrar todas las operaciones                                     |
//+------------------------------------------------------------------+
void CloseAllTrades()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != myMagic) continue;
      
      trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
//| Función para forzar entrada manual                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_KEYDOWN)
   {
      // Presionar B para forzar compra
      if(lparam == 66) // 'B' key
      {
         if(currentLevel == 0)
            StartNewCycle(ORDER_TYPE_BUY);
      }
      // Presionar S para forzar venta
      else if(lparam == 83) // 'S' key
      {
         if(currentLevel == 0)
            StartNewCycle(ORDER_TYPE_SELL);
      }
      // Presionar C para cerrar todo
      else if(lparam == 67) // 'C' key
      {
         CloseAllTrades();
         currentLevel = 0;
         Print("TODAS LAS OPERACIONES CERRADAS MANUALMENTE");
      }
   }
}