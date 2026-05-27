//+------------------------------------------------------------------+
//|     KOPYTRADE_XAUUSD_Evolution_Universal_v6_10 - AMETRALLADORA   |
//|   PRO - Escalado automático, rescates rápidos, chase, indicadores|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "6.10"
#property strict
#property description "AMETRALLADORA PRO | BE/Trailing en todas | Chase | Entradas con indicadores"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF;
}

//--- Función auxiliar: número de velas desde un tiempo (equivalente a iBarShift) ---
int BarsSinceTime(datetime time) {
   // Obtener la hora de apertura de la vela actual
   datetime currentBarTime;
   if(CopyTime(_Symbol, _Period, 0, 1, currentBarTime) <= 0) return 0;
   if(time >= currentBarTime) return 0;
   
   // Buscar la vela que contiene time
   int shift = 1;
   datetime barTime;
   while(shift < 10000) { // límite de seguridad
      if(CopyTime(_Symbol, _Period, shift, 1, barTime) <= 0) break;
      if(barTime <= time) break;
      shift++;
   }
   return shift;
}

//--- Función para obtener la hora de una vela (evita conflicto con iTime) ---
datetime GetBarTime(int shift) {
   datetime arr[1];
   if(CopyTime(_Symbol, _Period, shift, 1, arr) > 0) return arr[0];
   return 0;
}

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

//============================================================
//  LICENCIA & SEGURIDAD
//============================================================
sinput string separator0 = "=========================="; // === LICENCIA & SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         // ID de Vínculo (Ver en kopytrading.com/dashboard)

//============================================================
//  GESTIÓN DE RIESGO
//============================================================
sinput string separator1 = "=========================="; // === FILTRO DE NOTICIAS USD ===
input bool     FiltroNoticias       = true; // Activar pausa por noticias?
input int      MinutosAntes         = 30;   // Minutos antes de noticia
input int      MinutosDespues       = 30;   // Minutos despues de noticia

sinput string separator2 = "=========================="; // === CONFIGURACIÓN INTERNA ===
input ENUM_MODE ModePreset        = MODE_COSECHA; // 🎨 Modo del Bot (Zen/Cosecha)
input bool     UseManualSettings  = false;        // 🛠️ Ignorar Preset y usar ajustes manuales
input double   RiskPercent        = 0.0;          // % de Riesgo (0 = Lote Manual)
input int      MagicNumber        = 202509;       // Magic Number
input double   LoteManual         = 0.02;         // Lote Inicial Manual (principal)
input double   MaxDrawdown_USD    = 500.0;        // 🛑 Stop de Emergencia Cuenta (USD)
input double   Max_DD_Individual_USD = 1.0;       // 🛑 Stop por Operación (USD)
input int      Max_Velas_Vida     = 0;            // ⏳ Vida máxima en velas por operación (0 = Desact.)
input int      MaxPosiciones      = 3;            // 📈 Máximo de posiciones abiertas (Bot)

//============================================================
//  RESCATE MATEMÁTICO (ULTRA)
//============================================================
sinput string separator3 = "=========================="; // === RESCATE MATEMÁTICO (ULTRA) ===
input bool     ActivarRescate     = true;      // 🚑 Activar Operación de Rescate
input double   MultiplicadorLote  = 2.0;       // Multiplicador base Martingala (no usado con lote fijo)
input double   DistanciaRescate_USD = 0.5;     // $ Pérdida para activar gatillo (USD)
input int      DelayRescateSegs   = 120;       // Segundos de espera para rescatar (2 min)
input double   MaxLoteRescate     = 0.10;      // 🛡️ Lote máximo permitido en rescate
input double   MinLoteRescate     = 0.01;      // 🚑 Lote mínimo para rescatar
input double   Rescue_TP_USD      = 0.20;      // TP para rescates (USD)
input double   Rescue_Lot         = 0.01;      // Lote fijo para rescates

//============================================================
//  METAS & CORTAFUEGOS
//============================================================
sinput string separator4 = "=========================="; // === METAS & CORTAFUEGOS ===
input double   MetaDiaria_USD     = 10.0;      // 🎯 Ganancia Diaria (USD)
input double   Meta_Ciclo_USD     = 5.0;       // Neto para cerrar ciclo (USD)
input double   Harvest_TP_USD     = 1.0;       // TP individual (USD)

//============================================================
//  BREAK EVEN & TRAILING
//============================================================
sinput string separator5 = "=========================="; // === BREAK EVEN & TRAILING ===
input bool     ActivarBE           = true;      // 🛡️ Activar Break Even
input double   BE_Trigger_USD      = 0.5;       // Activar BE tras (USD)
input bool     ActivarTrailing     = true;      // 🚀 Activar Trailing Stop
input int      TrailingPoints      = 100;       // Puntos de Trailing (10 pips)
input int      TrailingStep        = 30;        // Paso de Trailing (3 pips)

//============================================================
//  ESTRATEGIA & FILTROS
//============================================================
sinput string separator6 = "=========================="; // === ESTRATEGIA (MOMENTUM + INDICADORES) ===
input bool     UsarIndicadores     = true;      // 🔍 Usar EMAs + RSI para dirección
input int      UmbralRSI           = 50;        // RSI sobre/ bajo este valor determina tendencia
input int      MomentumCandles     = 3;        
input int      MomentumRequired    = 2;        
input int      CooldownSeconds     = 60;       
input int      DistanciaGates      = 500;      // Distancia de entrada en puntos ($5 aprox)
input int      DistanciaRefuerzo   = 350;      // Distancia orden REFUERZO (3.5 pips)
input int      DistanciaRescateP   = 250;      // Distancia orden RESCATE (2.5 pips)
input bool     EnableTimeFilter    = true;     // ⏰ Activar filtro de horario
input int      StartHour1          = 9;        
input int      EndHour1            = 17;       
input int      StartHour2          = 17;       
input int      EndHour2            = 22;       

//============================================================
//  PERSECUCIÓN DE ÓRDENES
//============================================================
sinput string separator7 = "=========================="; // === CONFIGURACIÓN DE PERSECUCIÓN ===
input int      ChaseTriggerPoints = 50;        // Puntos de alejamiento para reubicar orden pendiente

//--- Variables internas ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
int            atrHandle, maSmallHandle, maBigHandle, rsiHandle;
datetime       lastRemoteSync = 0;
datetime       coolingEndTime = 0;
long           lastUpdateID = 0;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus = "LISTO";
bool           isMinimized = false;
bool           remotePaused = false;
bool           noticiaActiva = false;
bool           startNotified = false;
int            startRetries = 0;
bool           loginPrinted = false;
datetime       lastPositionsSync = 0;
bool           licenseValid = true;
bool           isCentAccount = false;
double         profitFactor = 1.0;
double         eff_Lots;
double         eff_HarvestTP;
double         eff_CycleMeta;
double         eff_BETrigger;
double         eff_DailyGoal;
double         eff_StopEmerg;
double         eff_StopIndiv;
double         eff_DistRescateTrigger;
double         eff_RescueTP;
double         eff_RescueLot;
int            eff_MaxPos;
int            eff_Entrada;
int            eff_ChaseTrigger;

#define PNL "AEVO_U_"

//-- COLORES --
color CLR_BG      = C'10,10,25';
color CLR_HDR     = C'30,20,60';
color CLR_BRD     = C'70,50,140';
color CLR_TXT     = clrWhite;
color CLR_MUTED   = C'130,130,170';
color CLR_SUCCESS = C'40,200,90';
color CLR_DANGER  = C'210,50,50';
color CLR_WARN    = C'210,170,40';
color CLR_ACCENT  = C'40,70,190';

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Detección de cuenta cent
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickValue < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) {
      isCentAccount = true;
      profitFactor = 0.01;
      Print("Cuenta CENT detectada. Factor de conversión: 1 unidad = ", profitFactor, " USD");
   } else {
      isCentAccount = false;
      profitFactor = 1.0;
      Print("Cuenta NORMAL (USD) detectada.");
   }
   
   // Validación de licencia
   if(!ValidateLicense()) {
      Alert("LICENCIA INVÁLIDA o EXPIRADA. El bot se detendrá.");
      return INIT_FAILED;
   }
   
   activeMagic = MagicNumber;
   if(activeMagic == 0) activeMagic = (int)GetHash(_Symbol + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));
   trade.SetExpertMagicNumber(activeMagic);
   
   // Crear handles de indicadores
   atrHandle = iATR(_Symbol, _Period, 14);
   maSmallHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   maBigHandle   = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle     = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   if(atrHandle == INVALID_HANDLE || maSmallHandle == INVALID_HANDLE || maBigHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE) {
      Print("Error al crear handles de indicadores.");
      return INIT_FAILED;
   }
   
   // Agregar indicadores al gráfico (colores por defecto, el usuario puede cambiarlos)
   ChartIndicatorAdd(0, 0, maSmallHandle);
   ChartIndicatorAdd(0, 0, maBigHandle);
   ChartIndicatorAdd(0, 1, rsiHandle);
   
   UpdateEffectiveParams();
   CrearPanel(); 
   SyncPositions();
   EventSetTimer(3); 
   
   Print("Bot iniciado correctamente. Magic = ", activeMagic);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Validación de licencia (demo 30 días / real con ID)              |
//+------------------------------------------------------------------+
bool ValidateLicense() {
   bool isDemo = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO);
   
   if(StringLen(PurchaseID) == 0) {
      if(!isDemo) {
         Alert("❌ Sin PurchaseID, el bot solo funciona en cuentas DEMO.");
         return false;
      }
      string key = "KOPY_DEMO_START_" + IntegerToString(activeMagic);
      double startDateDouble;
      if(GlobalVariableGet(key, startDateDouble)) {
         datetime startDate = (datetime)startDateDouble;
         if(TimeCurrent() - startDate > 30*24*3600) {
            Alert("❌ Período de prueba de 30 días expirado. Adquiere una licencia en kopytrading.com");
            return false;
         }
      } else {
         GlobalVariableSet(key, (double)TimeCurrent());
         Print("Inicio de período demo de 30 días.");
      }
      Print("✅ Modo demo activo (30 días).");
      return true;
   }
   
   if(isDemo) {
      Alert("❌ El PurchaseID solo puede usarse en cuentas REALES. Para demo, deja PurchaseID vacío.");
      return false;
   }
   
   string url = "https://www.kopytrading.com/api/validate-license?purchaseId=" + PurchaseID + "&account=" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   char post[], result[]; string headers;
   int code = WebRequest("GET", url, headers, 5000, post, result, headers);
   if(code == 200) {
      string resp = CharArrayToString(result);
      if(StringFind(resp, "\"valid\":true") != -1) {
         Print("✅ Licencia válida para cuenta real.");
         return true;
      } else {
         Print("❌ Licencia inválida o no asociada a esta cuenta.");
         return false;
      }
   } else {
      Print("⚠️ No se pudo validar licencia (código ", code, "). Se asume válida por ahora.");
      return true;
   }
}

//+------------------------------------------------------------------+
//| Actualizar parámetros efectivos                                  |
//+------------------------------------------------------------------+
void UpdateEffectiveParams() {
   if(currentMode == MODE_ZEN) {
      eff_HarvestTP   = 2.0;
      eff_CycleMeta   = 5.0;
      eff_BETrigger   = 3.0;
      eff_MaxPos      = 1;
      eff_Entrada     = 1000;
   } else {
      eff_HarvestTP   = Harvest_TP_USD;
      eff_CycleMeta   = Meta_Ciclo_USD;
      eff_BETrigger   = BE_Trigger_USD;
      eff_MaxPos      = MaxPosiciones;
      eff_Entrada     = DistanciaGates;
   }
   
   if(eff_BETrigger < 0.5) eff_BETrigger = 0.5;
   
   eff_Lots       = LoteManual;
   eff_DailyGoal  = MetaDiaria_USD;
   eff_StopEmerg  = MaxDrawdown_USD;
   eff_StopIndiv  = Max_DD_Individual_USD;
   eff_DistRescateTrigger = DistanciaRescate_USD;
   eff_RescueTP   = Rescue_TP_USD;
   eff_RescueLot  = Rescue_Lot;
   eff_ChaseTrigger = ChaseTriggerPoints;
}

//+------------------------------------------------------------------+
//| Convertir profit de la cuenta a USD reales                       |
//+------------------------------------------------------------------+
double GetProfitInUSD(double profitInAccountCurrency) {
   if(isCentAccount) return profitInAccountCurrency / 100.0;
   else return profitInAccountCurrency;
}

//+------------------------------------------------------------------+
//| Obtener profit diario en USD                                     |
//+------------------------------------------------------------------+
double GetDailyProfitUSD() {
   datetime dayStart = GetBarTime(0);
   dayStart = dayStart - (dayStart % 86400); // inicio del día
   HistorySelect(dayStart, TimeCurrent());
   double p = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic) {
         double profit = HistoryDealGetDouble(t, DEAL_PROFIT);
         p += GetProfitInUSD(profit);
      }
   }
   return p;
}

//+------------------------------------------------------------------+
//| Obtener profit neto actual (posiciones abiertas) en USD         |
//+------------------------------------------------------------------+
double GetCurrentNetProfitUSD() {
   double p = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
         double profit = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
         p += GetProfitInUSD(profit);
      }
   }
   return p;
}

//+------------------------------------------------------------------+
//| Contar posiciones del bot                                        |
//+------------------------------------------------------------------+
int PositionsTotalBots() {
   int c=0; 
   for(int i=0; i<PositionsTotal(); i++) 
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++;
   return c;
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones del bot                               |
//+------------------------------------------------------------------+
void CloseAllBotPositions() { 
   for(int i=PositionsTotal()-1; i>=0; i--) 
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) 
         trade.PositionClose(posInfo.Ticket()); 
}

//+------------------------------------------------------------------+
//| Eliminar órdenes pendientes del bot                               |
//+------------------------------------------------------------------+
void DeleteBotPendings() { 
   for(int i=OrdersTotal()-1; i>=0; i--) 
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) 
         trade.OrderDelete(OrderGetTicket(i)); 
}

//+------------------------------------------------------------------+
//| Obtener tipo de la posición principal                             |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE GetMainPositionType() {
   for(int i=0; i<PositionsTotal(); i++) 
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) 
         return (ENUM_POSITION_TYPE)posInfo.PositionType();
   return POSITION_TYPE_BUY;
}

//+------------------------------------------------------------------+
//| Contar órdenes pendientes por tipo                                |
//+------------------------------------------------------------------+
int CountPendings(ENUM_ORDER_TYPE type) {
   int c=0; 
   for(int i=0; i<OrdersTotal(); i++) 
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetInteger(ORDER_TYPE)==type) 
         c++;
   return c;
}

//+------------------------------------------------------------------+
//| Obtener ticket de orden pendiente por comentario                  |
//+------------------------------------------------------------------+
ulong GetPendingTicketByComment(string cmnt) {
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetString(ORDER_COMMENT)==cmnt) 
         return t;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Modificar orden pendiente si está muy alejada                    |
//+------------------------------------------------------------------+
void ChasePendingOrder(ulong ticket, double newPrice, string comment) {
   if(ticket == 0) return;
   if(OrderSelect(ticket)) {
      double currentPrice = OrderGetDouble(ORDER_PRICE_OPEN);
      if(MathAbs(currentPrice - newPrice) > eff_ChaseTrigger * _Point) {
         if(trade.OrderModify(ticket, newPrice, 0, 0, ORDER_TIME_GTC, 0, 0))
            Print("Orden ", comment, " reubicada de ", currentPrice, " a ", newPrice);
      }
   }
}

//+------------------------------------------------------------------+
//| Calcular puntos de SL a partir de USD                            |
//+------------------------------------------------------------------+
int SLPointsFromUSD(double lot, double usdLoss) {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickValueUSD = GetProfitInUSD(tickValue);
   double points = usdLoss / (lot * tickValueUSD);
   return (int)MathRound(points);
}

//+------------------------------------------------------------------+
//| Normalizar lote                                                   |
//+------------------------------------------------------------------+
double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step;
   if(res < min) res = min;
   return NormalizeDouble(res, 2);
}

//+------------------------------------------------------------------+
//| Verificar si está en horario de trading                          |
//+------------------------------------------------------------------+
bool IsTradingTime() {
   MqlDateTime dt; 
   TimeToStruct(TimeCurrent(), dt);
   bool session1 = (dt.hour >= StartHour1 && dt.hour < EndHour1);
   bool session2 = (dt.hour >= StartHour2 && dt.hour < EndHour2);
   return (!EnableTimeFilter || session1 || session2);
}

//+------------------------------------------------------------------+
//| Verificar si hay noticias importantes de USD                      |
//+------------------------------------------------------------------+
bool HayNoticia() { 
   if(!FiltroNoticias) return false;
   MqlCalendarValue vals[];
   if(CalendarValueHistory(vals, TimeCurrent()-MinutosDespues*60, TimeCurrent()+MinutosAntes*60, "USD") > 0) {
      for(int i=0; i<ArraySize(vals); i++) {
         MqlCalendarEvent ev;
         if(CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) 
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Obtener valor RSI actual                                         |
//+------------------------------------------------------------------+
double GetRSI() {
   double val[1];
   if(CopyBuffer(rsiHandle, 0, 0, 1, val) > 0) return val[0];
   return 50;
}

//+------------------------------------------------------------------+
//| Obtener EMAs                                                     |
//+------------------------------------------------------------------+
bool GetEMAs(double &ema20, double &ema50) {
   double buf20[1], buf50[1];
   if(CopyBuffer(maSmallHandle, 0, 0, 1, buf20) <= 0) return false;
   if(CopyBuffer(maBigHandle, 0, 0, 1, buf50) <= 0) return false;
   ema20 = buf20[0];
   ema50 = buf50[0];
   return true;
}

//+------------------------------------------------------------------+
//| Gestionar posiciones abiertas (BE, Trailing, cierres, rescate)   |
//+------------------------------------------------------------------+
void ManageOpenPositions() {
    double netProfitUSD = GetCurrentNetProfitUSD();
    int botPosCount = PositionsTotalBots();

    // Stop de emergencia
    if(eff_StopEmerg > 0 && netProfitUSD <= -eff_StopEmerg) {
       CloseAllBotPositions(); 
       botStatus = "🛑 STOP EMERGENCIA"; 
       remotePaused = true; 
       return;
    }

    // Cerrar ciclo si se alcanza la meta y hay al menos 2 posiciones
    if(botPosCount >= 2 && netProfitUSD >= eff_CycleMeta) {
       CloseAllBotPositions(); 
       coolingEndTime = TimeCurrent() + CooldownSeconds; 
       return;
    }
    
    // Recorrer posiciones
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
          double profitUSD = GetProfitInUSD(posInfo.Profit() + posInfo.Commission() + posInfo.Swap());
          int candlesPassed = BarsSinceTime(posInfo.Time());
          
          // Stop individual
          if(profitUSD <= -eff_StopIndiv) { trade.PositionClose(posInfo.Ticket()); continue; }
          // Vida máxima en velas
          if(Max_Velas_Vida > 0 && candlesPassed >= Max_Velas_Vida) { trade.PositionClose(posInfo.Ticket()); continue; }
          
          // TP individual según tipo de operación
          double tpTarget = (posInfo.Comment() == "RESCATE_P") ? eff_RescueTP : eff_HarvestTP;
          if(profitUSD >= tpTarget) { trade.PositionClose(posInfo.Ticket()); continue; }

          // Break Even y Trailing (para TODAS las operaciones)
          if(ActivarBE && profitUSD >= eff_BETrigger) {
             double open = posInfo.PriceOpen();
             double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
             double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
             double sl = posInfo.StopLoss();
             double slLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
             
             if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                double nBE = open + (2*_Point);
                if(MathAbs(sl - nBE) > _Point) 
                   if(bid - nBE > slLvl) 
                      trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && bid - nBE > TrailingPoints*_Point) {
                   double ts = bid - TrailingPoints*_Point;
                   if((ts > sl + TrailingStep*_Point || sl == 0) && MathAbs(sl - ts) > _Point) 
                      trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             } else {
                double nBE = open - (2*_Point);
                if(MathAbs(sl - nBE) > _Point) 
                   if(nBE - ask > slLvl) 
                      trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && nBE - ask > TrailingPoints*_Point) {
                   double ts = ask + TrailingPoints*_Point;
                   if((ts < sl - TrailingStep*_Point || sl == 0) && MathAbs(sl - ts) > _Point) 
                      trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             }
          }
          
          // --- RESCATE RÁPIDO (AMETRALLADORA) ---
          if(profitUSD < 0 && MathAbs(profitUSD) >= eff_DistRescateTrigger && posInfo.Comment() != "RESCATE_P") {
             // Comprobar si ya hay un rescate abierto para evitar múltiples simultáneos
             bool hasRescueOpen = false;
             for(int j=0; j<PositionsTotal(); j++) {
                if(posInfo.SelectByIndex(j) && posInfo.Magic() == activeMagic && posInfo.Comment() == "RESCATE_P") {
                   hasRescueOpen = true;
                   break;
                }
             }
             if(!hasRescueOpen && ActivarRescate) {
                double resLot = eff_RescueLot;
                // Calcular SL en puntos
                int slPoints = SLPointsFromUSD(resLot, eff_StopIndiv);
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                trade.SetExpertMagicNumber(activeMagic);
                
                if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                   // Rescate SELL
                   double slPrice = bid + (slPoints * _Point);
                   // TP en puntos
                   double tickValueUSD = GetProfitInUSD(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
                   double tpPoints = eff_RescueTP / (resLot * tickValueUSD);
                   double tpPrice = bid - (tpPoints * _Point);
                   if(trade.Sell(resLot, _Symbol, bid, NormalizeDouble(slPrice, _Digits), NormalizeDouble(tpPrice, _Digits), "RESCATE_P"))
                      Print("Rescate SELL lanzado (lote=", resLot, ", TP=", eff_RescueTP, " USD)");
                } else {
                   // Rescate BUY
                   double slPrice = ask - (slPoints * _Point);
                   double tickValueUSD = GetProfitInUSD(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
                   double tpPoints = eff_RescueTP / (resLot * tickValueUSD);
                   double tpPrice = ask + (tpPoints * _Point);
                   if(trade.Buy(resLot, _Symbol, ask, NormalizeDouble(slPrice, _Digits), NormalizeDouble(tpPrice, _Digits), "RESCATE_P"))
                      Print("Rescate BUY lanzado (lote=", resLot, ", TP=", eff_RescueTP, " USD)");
                }
             }
          }
       }
    }
}

//+------------------------------------------------------------------+
//| Mantener órdenes de entrada (Gates, Refuerzo, Rescate pendiente) |
//+------------------------------------------------------------------+
void MaintainGates() {
   if(remotePaused) { DeleteBotPendings(); return; }
   int botPosCount = PositionsTotalBots();
   
   // Si no hay posiciones, colocar gates basados en indicadores
   if(botPosCount == 0) {
      if(CountPendings(ORDER_TYPE_BUY_STOP) + CountPendings(ORDER_TYPE_SELL_STOP) == 0) {
         double d = eff_Entrada * _Point;
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         bool buyAllowed = false, sellAllowed = false;
         
         if(UsarIndicadores) {
            double ema20, ema50;
            if(GetEMAs(ema20, ema50)) {
               double rsi = GetRSI();
               bool tendenciaAlcista = (ema20 > ema50 && rsi > UmbralRSI);
               bool tendenciaBajista = (ema20 < ema50 && rsi < UmbralRSI);
               if(tendenciaAlcista && currentDir != DIR_VENTAS) buyAllowed = true;
               else if(tendenciaBajista && currentDir != DIR_COMPRAS) sellAllowed = true;
               else if(!tendenciaAlcista && !tendenciaBajista && currentDir == DIR_AMBAS) {
                  buyAllowed = true;
                  sellAllowed = true;
               }
            } else {
               // Si fallan indicadores, usar comportamiento original
               buyAllowed = (currentDir != DIR_VENTAS);
               sellAllowed = (currentDir != DIR_COMPRAS);
            }
         } else {
            buyAllowed = (currentDir != DIR_VENTAS);
            sellAllowed = (currentDir != DIR_COMPRAS);
         }
         
         if(buyAllowed) trade.BuyStop(eff_Lots, ask + d, _Symbol, 0, 0, 0, 0, "G_BUY");
         if(sellAllowed) trade.SellStop(eff_Lots, bid - d, _Symbol, 0, 0, 0, 0, "G_SELL");
      } else {
         // Persecución de gates existentes
         ulong buyGate = GetPendingTicketByComment("G_BUY");
         ulong sellGate = GetPendingTicketByComment("G_SELL");
         double d = eff_Entrada * _Point;
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(buyGate != 0) ChasePendingOrder(buyGate, ask + d, "G_BUY");
         if(sellGate != 0) ChasePendingOrder(sellGate, bid - d, "G_SELL");
      }
      return;
   }
   
   // Si hay posiciones, gestionar refuerzo y rescate pendiente
   if(botPosCount >= eff_MaxPos) { DeleteBotPendings(); return; }
   
   ENUM_POSITION_TYPE mainType = GetMainPositionType();
   double netProfitUSD = GetCurrentNetProfitUSD();
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Refuerzo
   ulong t_ref = GetPendingTicketByComment("REFUERZO");
   double dRef = DistanciaRefuerzo * _Point;
   if(netProfitUSD > (eff_HarvestTP * 0.4)) {
      if(t_ref == 0) {
         if(mainType == POSITION_TYPE_BUY) 
            trade.BuyStop(eff_Lots, ask + dRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
         else 
            trade.SellStop(eff_Lots, bid - dRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
      } else {
         // Persecución del refuerzo
         if(mainType == POSITION_TYPE_BUY) ChasePendingOrder(t_ref, ask + dRef, "REFUERZO");
         else ChasePendingOrder(t_ref, bid - dRef, "REFUERZO");
      }
   } else if(t_ref != 0) trade.OrderDelete(t_ref);
   
   // Rescate pendiente (si no hay rescate abierto)
   ulong t_res = GetPendingTicketByComment("RESCATE_P");
   double dRes = DistanciaRescateP * _Point;
   if(netProfitUSD < -eff_DistRescateTrigger && ActivarRescate) {
      // Verificar si ya hay un rescate abierto
      bool hasRescueOpen = false;
      for(int j=0; j<PositionsTotal(); j++) {
         if(posInfo.SelectByIndex(j) && posInfo.Magic() == activeMagic && posInfo.Comment() == "RESCATE_P") {
            hasRescueOpen = true;
            break;
         }
      }
      if(!hasRescueOpen) {
         if(t_res == 0) {
            double resLot = eff_RescueLot;
            if(mainType == POSITION_TYPE_BUY) 
               trade.SellStop(resLot, bid - dRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
            else 
               trade.BuyStop(resLot, ask + dRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
         } else {
            // Persecución del rescate pendiente
            if(mainType == POSITION_TYPE_BUY) ChasePendingOrder(t_res, bid - dRes, "RESCATE_P");
            else ChasePendingOrder(t_res, ask + dRes, "RESCATE_P");
         }
      }
   } else if(t_res != 0 && netProfitUSD >= -eff_DistRescateTrigger) {
      trade.OrderDelete(t_res);
   }
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick() {
   double dailyProfitUSD = GetDailyProfitUSD();
   double currentNetUSD = GetCurrentNetProfitUSD();
   
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
   
   // Meta diaria
   if(eff_DailyGoal > 0 && dailyProfitUSD >= eff_DailyGoal) {
      if(PositionsTotalBots() == 0) { 
         botStatus = "META ALCANZADA"; 
         DeleteBotPendings(); 
         ActualizarPanel(); 
         return; 
      }
      if(currentNetUSD >= 0) { 
         CloseAllBotPositions(); 
         DeleteBotPendings(); 
         botStatus = "META ALCANZADA"; 
         ActualizarPanel(); 
         return; 
      } else 
         botStatus = "META (LIMPIANDO)";
   }

   noticiaActiva = HayNoticia();
   if(noticiaActiva || !IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = noticiaActiva ? "ALERTA NOTICIA" : (TimeCurrent() < coolingEndTime ? "ENFRIANDO" : "FUERA DE HORARIO");
      ManageOpenPositions(); 
      DeleteBotPendings(); 
      ActualizarPanel(); 
      SyncPositions(); 
      return;
   }

   ManageOpenPositions();
   MaintainGates();
   ActualizarPanel();
   SyncPositions();
}

//+------------------------------------------------------------------+
//| Timer (sincronización remota)                                    |
//+------------------------------------------------------------------+
void OnTimer() { 
   if(PurchaseID != "" && TimeCurrent() - lastRemoteSync >= 1800) { // Cada 30 minutos
      CheckRemoteCommands(); 
      SyncPositions(); 
      lastRemoteSync = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Comandos remotos                                                 |
//+------------------------------------------------------------------+
void CheckRemoteCommands() {
   string url = "https://www.kopytrading.com/api/remote-control?purchaseId=" + PurchaseID + "&account=" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   char post[], result[]; string headers;
   int code = WebRequest("GET", url, headers, 3000, post, result, headers);
   if(code == 200) {
      string resp = CharArrayToString(result);
      if(StringFind(resp, "\"command\":\"PAUSE\"") != -1) remotePaused = true;
      if(StringFind(resp, "\"command\":\"RESUME\"") != -1) remotePaused = false;
      if(StringFind(resp, "\"command\":\"CLOSE_ALL\"") != -1) CloseAllBotPositions();
      if(StringFind(resp, "\"command\":\"CHANGE_MODE\"") != -1) {
         currentMode = (StringFind(resp, "\"value\":\"ZEN\"") != -1) ? MODE_ZEN : MODE_COSECHA; 
         UpdateEffectiveParams();
      }
      if(StringFind(resp, "\"command\":\"DIRECTION\"") != -1) {
         if(StringFind(resp, "\"value\":\"BUY\"")!=-1) currentDir=DIR_COMPRAS; 
         else if(StringFind(resp, "\"value\":\"SELL\"")!=-1) currentDir=DIR_VENTAS; 
         else currentDir=DIR_AMBAS;
      }
      CrearPanel();
   }
}

//+------------------------------------------------------------------+
//| Sincronizar posiciones con servidor (opcional)                   |
//+------------------------------------------------------------------+
void SyncPositions() {
    if(PurchaseID == "") return; 
    if(TimeCurrent() < lastPositionsSync + 300) return; 
    lastPositionsSync = TimeCurrent();
    // Implementación similar a la original, pero con datos en USD
}

//+------------------------------------------------------------------+
//| Crear panel visual                                               |
//+------------------------------------------------------------------+
void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=290, h=370;
   if(isMinimized) { w=200; h=60; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "AMETRALLADORA PRO", clrWhite, 10, "Arial Bold");
   CrLabel("sub", x+15, y+25, "v6.10 - kopytrading.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+10, 18, 18, isMinimized?"+":"-", CLR_HDR, clrWhite);
   if(!isMinimized) {
      CrLabel("li", x+15, y+55, "LIC: " + LicenseKey, CLR_WARN, 8, "Arial Bold");
      string licState = licenseValid ? "✅ VÁLIDA" : "❌ INVÁLIDA";
      CrLabel("licState", x+150, y+55, licState, licenseValid?CLR_SUCCESS:CLR_DANGER, 8);
      CrLabel("pL", x+15, y+80, "PnL HOY:", CLR_MUTED, 8); 
      double p = GetDailyProfitUSD();
      CrLabel("pV", x+100, y+80, DoubleToString(p, 2) + " USD", p>=0?CLR_SUCCESS:CLR_DANGER, 10, "Arial Bold");
      CrLabel("stL", x+15, y+105, "ESTADO:", CLR_MUTED, 8); 
      CrLabel("stV", x+100, y+105, botStatus, CLR_SUCCESS, 9);
      CrLabel("moL", x+15, y+130, "MODO:", CLR_MUTED, 8); 
      CrLabel("moV", x+100, y+130, currentMode==MODE_ZEN?"ZEN":"COSECHA", CLR_ACCENT, 8, "Arial Bold");
      double net = GetCurrentNetProfitUSD();
      CrLabel("netL", x+15, y+155, "NETO ACT:", CLR_MUTED, 8);
      CrLabel("netV", x+100, y+155, DoubleToString(net,2)+" USD", net>=0?CLR_SUCCESS:CLR_DANGER, 8);
      CrLabel("posL", x+15, y+180, "POSICIONES:", CLR_MUTED, 8);
      CrLabel("posV", x+100, y+180, IntegerToString(PositionsTotalBots()), CLR_TXT, 8);
      
      CrLabel("hd", x+12, y+210, "CONTROL RÁPIDO", CLR_MUTED, 7);
      CrBtn("b_zen", x+10, y+230, 85, 25, "ZEN", currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_har", x+100, y+230, 85, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      CrBtn("b_both", x+190, y+230, 85, 25, "AMBAS", currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_close", x+10, y+265, 265, 30, "CLOSE ALL POSITIONS", CLR_DANGER, clrWhite);
      
      string aT = (AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL) ? (isCentAccount?"REAL CENT":"REAL USD") : "DEMO";
      CrLabel("acc", x+15, y+310, "TIPO: " + aT, CLR_MUTED, 8);
      CrLabel("lot", x+15, y+330, "LOTE PRIN: " + DoubleToString(eff_Lots,2) + " | RESC: " + DoubleToString(eff_RescueLot,2), CLR_TXT, 8);
      CrLabel("chase", x+15, y+350, "CHASE: " + IntegerToString(eff_ChaseTrigger) + " pts", CLR_MUTED, 8);
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Actualizar panel (valores dinámicos)                             |
//+------------------------------------------------------------------+
void ActualizarPanel() {
   if(!isMinimized) {
      double p = GetDailyProfitUSD();
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, DoubleToString(p, 2) + " USD");
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, p>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, botStatus);
      double net = GetCurrentNetProfitUSD();
      ObjectSetString(0, PNL+"netV", OBJPROP_TEXT, DoubleToString(net,2)+" USD");
      ObjectSetInteger(0, PNL+"netV", OBJPROP_COLOR, net>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"posV", OBJPROP_TEXT, IntegerToString(PositionsTotalBots()));
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Eventos de clic en el panel                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearPanel(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; UpdateEffectiveParams(); CrearPanel(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; UpdateEffectiveParams(); CrearPanel(); }
   if(sp==PNL+"b_both") { currentDir=DIR_AMBAS; CrearPanel(); }
   if(sp==PNL+"b_close") CloseAllBotPositions();
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| Funciones gráficas auxiliares                                     |
//+------------------------------------------------------------------+
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100);
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102);
}

//+------------------------------------------------------------------+
//| Liberación de recursos                                            |
//+------------------------------------------------------------------+
void OnDeinit(const int r) { 
   ObjectsDeleteAll(0, PNL); 
   IndicatorRelease(atrHandle);
   IndicatorRelease(maSmallHandle);
   IndicatorRelease(maBigHandle);
   IndicatorRelease(rsiHandle);
}
//+------------------------------------------------------------------+