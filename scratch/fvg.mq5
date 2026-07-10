//+------------------------------------------------------------------+
//|                                     Maiko_Opening_Range_FVG.mq5 |
//|                                  Copyright 2026, KOPYTRADING       |
//|                                       https://www.kopytrading.com |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADING"
#property link      "https://www.kopytrading.com"
#property version   "1.00"
#property description "Bot para MT5 que opera rupturas del rango de 5M de NY con confirmacion de FVG en 1M."
#property strict

// Incluir libreria oficial de trading de MetaTrader 5
#include <Trade\Trade.mqh>

//--- Grupos de Inputs en MetaTrader 5
input group "=== 🛡️ CONTROL DE SEGURIDAD ==="
input long     AllowedAccount       = 0;         // Cuenta de MT5 autorizada

input group "=== ⏰ ZONA HORARIA (HORA BROKER) ==="
input int      BrokerNYOpenHour     = 16;        // Hora del servidor del broker para las 9:30 AM NY
input int      BrokerNYOpenMinute   = 30;        // Minuto del servidor del broker para las 9:30 AM NY
input int      MaxOpenHour          = 18;        // Hora broker limite para buscar entradas (luego se cancela)

input group "=== 📈 CONFIGURACION DE TRADING ==="
input double   LoteInicial          = 0.01;      // Volumen de la posicion
input double   RiskRewardRatio      = 2.0;       // Ratio Riesgo:Beneficio para el Take Profit (1:2 por defecto)
input double   MaxSpreadPips        = 5.0;       // Spread maximo permitido en pips para evitar deslizamiento
input long     MagicNumber          = 990012;    // ID unico del bot para sus operaciones

//--- Variables globales de control de estado
CTrade   trade;
double   rangeHigh            = 0.0;
double   rangeLow             = 0.0;
bool     rangeMeasured        = false;
bool     tradeExecutedToday   = false;
datetime currentDay           = 0;
datetime lastProcessedBarTime = 0;

//+------------------------------------------------------------------+
//| OnInit: Inicializacion del EA                                     |
//+------------------------------------------------------------------+
int OnInit() {
   // 1. Validar cuenta autorizada
   long currentAccount = AccountInfoInteger(ACCOUNT_LOGIN);
   if(AllowedAccount > 0 && currentAccount != AllowedAccount) {
      Alert("❌ CUENTA NO AUTORIZADA: #", currentAccount, ". El bot se detendra por seguridad. Configura AllowedAccount o ponlo en 0.");
      return INIT_FAILED;
   }

   // 2. Configurar Magic Number
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   // 3. Reiniciar estado temporal
   rangeHigh            = 0.0;
   rangeLow             = 0.0;
   rangeMeasured        = false;
   tradeExecutedToday   = false;
   currentDay           = 0;
   lastProcessedBarTime = 0;

   // 4. Dibujar aviso inicial en el grafico
   DrawHUD("Esperando a la sesion de Nueva York a las " + IntegerToString(BrokerNYOpenHour) + ":" + IntegerToString(BrokerNYOpenMinute, 2, '0') + " hora Broker...");

   Print("✅ Maiko Opening Range FVG inicializado correctamente.");
   Print("   Cuenta autorizada: #", AllowedAccount);
   Print("   Sesion NY programada a las: ", BrokerNYOpenHour, ":", BrokerNYOpenMinute, " (Hora Broker)");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit: Desinicializacion del EA                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Borrar objetos del grafico al quitar el bot
   ObjectDelete(0, "ORB_High");
   ObjectDelete(0, "ORB_Low");
   ObjectDelete(0, "ORB_HUD");
   Comment("");
}

//+------------------------------------------------------------------+
//| OnTick: Ejecucion principal del bot                              |
//+------------------------------------------------------------------+
void OnTick() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // 1. Reset diario al cambiar de dia
   if(dt.day_of_year != currentDay) {
      currentDay = dt.day_of_year;
      rangeMeasured = false;
      tradeExecutedToday = false;
      
      // Borrar lineas del dia anterior
      ObjectDelete(0, "ORB_High");
      ObjectDelete(0, "ORB_Low");
      Print("🔄 Nuevo dia detectado. Reiniciando rangos y filtros diarios.");
   }

   // Construir la hora de inicio de la vela 5M de NY de hoy
   MqlDateTime targetDt = dt;
   targetDt.hour = BrokerNYOpenHour;
   targetDt.min = BrokerNYOpenMinute;
   targetDt.sec = 0;
   datetime openTime = StructToTime(targetDt);

   // 2. Medir Rango de Apertura 5M
   if(!rangeMeasured) {
      // Esperamos a que la vela de 5 minutos que abre a las 9:30 NY este cerrada (es decir, +5 minutos = +300 segundos)
      if(TimeCurrent() >= openTime + 300) {
         MqlRates rates[];
         // Copiamos la vela de 5M que inicio a la hora exacta configurada
         if(CopyRates(_Symbol, PERIOD_M5, openTime, 1, rates) == 1) {
            rangeHigh = rates[0].high;
            rangeLow = rates[0].low;
            rangeMeasured = true;
            
            // Dibujar lineas de soporte/resistencia del rango
            DrawHorizontalLine("ORB_High", rangeHigh, clrGreen, STYLE_SOLID, 2);
            DrawHorizontalLine("ORB_Low", rangeLow, clrRed, STYLE_SOLID, 2);
            
            Print("📊 Rango 5M NY Medido de forma exitosa:");
            Print("   Máximo: ", DoubleToString(rangeHigh, _Digits));
            Print("   Mínimo: ", DoubleToString(rangeLow, _Digits));
         } else {
            DrawHUD("⚠️ Error al obtener datos M5 de la apertura. Reintentando...");
            return;
         }
      } else {
         // Mostrar cuenta regresiva o estado en pantalla
         DrawHUD("Esperando a la sesion de Nueva York a las " + IntegerToString(BrokerNYOpenHour) + ":" + IntegerToString(BrokerNYOpenMinute, 2, '0') + " hora Broker...");
         return;
      }
   }

   // 3. Gestionar entrada despues de medir el rango
   if(rangeMeasured && !tradeExecutedToday) {
      // Verificar si ya pasamos la hora limite de operacion
      if(dt.hour >= MaxOpenHour) {
         DrawHUD("⌛ Sesión operativa terminada. Sin gatillo antes de las " + IntegerToString(MaxOpenHour) + ":00.");
         return;
      }

      // Actualizar HUD visual de busqueda activa
      DrawHUD("🔍 BUSCANDO RUPTURA (1M) | Rango: " + DoubleToString(rangeLow, _Digits) + " - " + DoubleToString(rangeHigh, _Digits));

      // Leer las ultimas 4 velas en el grafico de 1 minuto
      // m1Rates[3] = vela actual 1M (incompleta, abierta)
      // m1Rates[2] = vela que acaba de cerrar (completa, Vela 1 del patron)
      // m1Rates[1] = vela anterior (completa, Vela 2 - explosiva)
      // m1Rates[0] = vela previa (completa, Vela 3 - origen)
      MqlRates m1Rates[];
      if(CopyRates(_Symbol, PERIOD_M1, 0, 4, m1Rates) == 4) {
         // Validar que entremos solo cuando abre una nueva vela de 1M (para evitar doble ejecucion por ticks)
         if(m1Rates[3].time != lastProcessedBarTime) {
            lastProcessedBarTime = m1Rates[3].time;

            // --- ESCENARIO ALCISTA (COMPRA) ---
            // 1. Confirmacion de FVG alcista: El minimo de Vela 1 es mayor al maximo de Vela 3
            bool isBullishFVG = (m1Rates[2].low > m1Rates[0].high);
            // 2. Ruptura: Vela 2 o Vela 1 han cerrado por encima del rango maximo de 5M
            bool breaksHigh = (m1Rates[1].close > rangeHigh || m1Rates[2].close > rangeHigh);

            if(isBullishFVG && breaksHigh) {
               // Encontrar la primera vela que cerro fuera del rango para colocar el Stop Loss
               double sl = 0.0;
               if(m1Rates[0].close > rangeHigh) sl = m1Rates[0].low;
               else if(m1Rates[1].close > rangeHigh) sl = m1Rates[1].low;
               else sl = m1Rates[2].low;

               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               if(sl < ask) {
                  double risk = ask - sl;
                  double tp = ask + (risk * RiskRewardRatio);

                  // Validar filtro de spread
                  if(CheckSpread()) {
                     // Ejecutar Compra a Mercado
                     if(trade.Buy(LoteInicial, _Symbol, ask, NormalizePrice(sl), NormalizePrice(tp), "ORB FVG BUY")) {
                        tradeExecutedToday = true;
                        DrawHUD("🚀 COMPRA EJECUTADA en " + DoubleToString(ask, _Digits));
                        Print("🔥 ORB FVG COMPRA ABIERTA: Entrada: ", ask, " SL: ", sl, " TP: ", tp);
                     }
                  }
               }
            }

            // --- ESCENARIO BAJISTA (VENTA) ---
            // 1. Confirmacion de FVG bajista: El maximo de Vela 1 es menor al minimo de Vela 3
            bool isBearishFVG = (m1Rates[2].high < m1Rates[0].low);
            // 2. Ruptura: Vela 2 o Vela 1 han cerrado por debajo del rango minimo de 5M
            bool breaksLow = (m1Rates[1].close < rangeLow || m1Rates[2].close < rangeLow);

            if(isBearishFVG && breaksLow) {
               // Encontrar la primera vela que cerro fuera del rango para colocar el Stop Loss
               double sl = 0.0;
               if(m1Rates[0].close < rangeLow) sl = m1Rates[0].high;
               else if(m1Rates[1].close < rangeLow) sl = m1Rates[1].high;
               else sl = m1Rates[2].high;

               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               if(sl > bid) {
                  double risk = sl - bid;
                  double tp = bid - (risk * RiskRewardRatio);

                  // Validar filtro de spread
                  if(CheckSpread()) {
                     // Ejecutar Venta a Mercado
                     if(trade.Sell(LoteInicial, _Symbol, bid, NormalizePrice(sl), NormalizePrice(tp), "ORB FVG SELL")) {
                        tradeExecutedToday = true;
                        DrawHUD("🚀 VENTA EJECUTADA en " + DoubleToString(bid, _Digits));
                        Print("🔥 ORB FVG VENTA ABIERTA: Entrada: ", bid, " SL: ", sl, " TP: ", tp);
                     }
                  }
               }
            }
         }
      }
   }

   // 4. Si ya opero hoy, actualizar estado
   if(tradeExecutedToday) {
      DrawHUD("✅ OPERACIÓN DEL DÍA EJECUTADA. Esperando mañana...");
   }
}

//+------------------------------------------------------------------+
//| Funciones Auxiliares y Graficas                                  |
//+------------------------------------------------------------------+

// Normalizar precios para cumplir con las reglas del broker (tick size)
double NormalizePrice(double price) {
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
}

// Validar si el spread actual es menor o igual al maximo configurado
bool CheckSpread() {
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double maxSpread = MaxSpreadPips * 10 * SymbolInfoDouble(_Symbol, SYMBOL_POINT); // pips a puntos
   
   if(spread <= maxSpread) return true;
   
   Print("⚠️ Entrada cancelada. Spread demasiado alto: ", spread, " (Max: ", maxSpread, ")");
   return false;
}

// Dibujar lineas horizontales de soporte y resistencia en el grafico
void DrawHorizontalLine(string name, double price, color col, ENUM_LINE_STYLE style, int width) {
   ObjectDelete(0, name);
   if(ObjectCreate(0, name, OBJ_HLINE, 0, 0, price)) {
      ObjectSetInteger(0, name, OBJPROP_COLOR, col);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   }
}

// Dibujar HUD informativo en la esquina superior izquierda
void DrawHUD(string text) {
   string objName = "ORB_HUD";
   if(ObjectFind(0, objName) < 0) {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 50);
      ObjectSetString(0, objName, OBJPROP_FONT, "Impact");
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   }
   ObjectSetString(0, objName, OBJPROP_TEXT, "MAIKO ORB FVG | " + text);
}
