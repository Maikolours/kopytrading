//+------------------------------------------------------------------+
//|               XAUUSD_Elite_Warrior_Safe_V2                       |
//|      v41.00 - HUD COMPACTO | BAJO RIESGO | PROTECCIÓN SPREAD     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "41.00"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

enum ENUM_PERFIL_ACTIVO { ACTIVO_AUTO, ACTIVO_ORO, ACTIVO_BITCOIN };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_EXEC { EXEC_MARKET, EXEC_LIMIT };
enum ENUM_STATE { STATE_WAIT_BOS, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };
enum ENUM_PRESET { PRESET_DIARIO, PRESET_FINDE };
enum ENUM_PROFUNDIDAD { OTE_382, OTE_618, OTE_MITAD_61_70, OTE_705, OTE_786 };

//============================================================
//  PARÁMETROS DE ENTRADA (TRADUCIDOS PARA CLARIDAD)
//============================================================
input group "=== ⚡ PERFIL DE ACTIVO INTELIGENTE ==="
input ENUM_PERFIL_ACTIVO Perfil_Activo   = ACTIVO_AUTO; // Desplegable: Auto / Oro (XAU) / Bitcoin (BTC)

input group "=== 🎯 CONFIGURACIÓN DASHBOARD ==="
input string   ID_Licencia_Master       = "cmn9hfaxg000lvhbcqidlvvfm";
input bool     Activar_Sincronizacion   = true;

input group "=== 🐺 ESTRATEGIA WARRIOR PREDATOR ==="
input ENUM_PROFUNDIDAD Profundidad_Minima_Entrada = OTE_MITAD_61_70;
input bool            Usar_StopLoss_Estricto = false; // false = SL Estructural con aire (Recomendado anti-mechas)
input ENUM_EXEC       Modo_Ejecucion           = EXEC_MARKET; 
input ENUM_TIMEFRAMES TF_Tendencia_Macro       = PERIOD_H1; 
input ENUM_TIMEFRAMES TF_Tendencia_Media       = PERIOD_M15;
input ENUM_TIMEFRAMES TF_Ejecucion_Gatillo     = PERIOD_M5; 
input int             Periodo_EMA_Filtro       = 200;

input group "=== 🤖 FILTROS SMC (NUEVO) ==="
input bool            Activar_Filtro_RSI       = true;  // Activa filtro para evitar comprar caro o vender barato
input double          RSI_Maximo_Para_Comprar  = 65.0;  // COMPRAS: RSI debe ser MENOR a este valor (evita comprar en sobrecompra)
input double          RSI_Minimo_Para_Vender   = 35.0;  // VENTAS: RSI debe ser MAYOR a este valor (evita vender en sobreventa)
input bool            Bloquear_En_Extremos_H4  = true;  // FRENO H4: Bloquea ventas en soporte D1/H4 o compras en resistencia
input int             Velas_Analisis_H4        = 30;    // Barras de H4 para detectar suelo/techo mayor
input double          Filtro_Cuerpo_Vela_Porcentaje = 25.0; // Mínimo % de cuerpo para que la vela sea válida (anti-Doji)
input bool            Corto_Manda_En_Conflicto    = false; // false = H1 Macro siempre manda (Prohibido ir contra-tendencia)
input int             Max_Operaciones_Por_Fibo = 3;

input group "=== 🕒 HORARIO DE TRADING ==="
input bool            Activar_Horario          = true;
input int             Hora_Inicio              = 1;
input int             Minuto_Inicio            = 0;
input int             Hora_Fin                 = 23;
input int             Minuto_Fin               = 0;

input group "=== 📅 PRESETS (Horas y Protección) ==="
input int             Velas_Analisis_Tendencia = 28;  
input int             Dist_Seguridad_BreakEven_Pts = 150;    // B.E. Rápido (Pts) a los 15 pips
input int             Velas_Analisis_Finde     = 6;  
input int             Dist_Seguridad_Finde_Pts = 100; 

input group "=== 🛡️ GESTIÓN DINÁMICA ==="
input int             Dist_Perseguir_Ganancias = 350; // Inicia el Trailing a los 35 pips (asegura 20)
input int             Dist_Distancia_Trailing  = 150; // Distancia del Trailing 15 pips
input double          Max_Spread_Permitido   = 5.0; // Evita entrar si el broker cobra mucha comision

input group "=== 🎨 ESTILO VISUAL ==="
input color           Color_Fibo            = clrGold;
input bool            Mostrar_Linea_Diagonal= true;        // Muestra la linea de impulso que une max/min
input color           Color_Linea_Diagonal  = clrDarkSlateGray; // Color discreto que no confunde con EMAs ni tapa el HUD
input color           Color_Alcista         = clrCyan;
input color           Color_Bajista         = clrOrangeRed;

input group "=== 💰 RIESGO Y MAGIC ==="
input double          Lote_Fijo_Manual         = 0.0; // Si es > 0, ignora el riesgo % y usa este lote
input double          Riesgo_Porcentaje_Cuenta = 0.05; // Antes 0.5. Ahora es un 90% más seguro.
input int             Magic_Number             = 202900;

#define HUD_PRE "H_"
#define GRAF_PRE "V_"
#define FIBO_NAME "V_FIBO"

//--- GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
ENUM_STATE     state = STATE_WAIT_BOS;
ENUM_MODE      currentMode = MODE_COSECHA;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_EXEC      currentExec = EXEC_MARKET;
ENUM_PRESET    currentPreset = PRESET_DIARIO;

int            hEmaH4, hEmaMacro, hEmaMid, hRSI, hRSI_H4, hADX;
int            hRSI_M1, hRSI_M5;
int            hEmaVisual50, hEmaVisual200, hRsiVisual, hAdxVisual;
int            dirH4=0, dirMacro=0, dirMid=0;
bool           h4_enSoporte = false, h4_enResistencia = false;
string         h4StatusTxt = "H4 NORMAL";
string         adxStatus = "ADX: -- [CALCULANDO]";
double         f100=0, f0=0, f23=0, f38=0, f50=0, f61=0, f70=0, f78=0;
datetime       t100=0, t0=0;
int            balas_gastadas = 0;
datetime       ultimo_fibo_time = 0;
datetime       ultima_vela_operada = 0;
bool           isMinimized=false, isManualMode=false, isBotPaused=false;
bool           p1_pierced=false;
int            curLkb, curBE, curHours;
int            curTrailPts = 350, curTrailDist = 150, curMagic = 202900;
double         curSpreadMax = 5.0;
ENUM_PROFUNDIDAD curProfundidad = OTE_MITAD_61_70;
string         activoNombre = "ORO (XAUUSD)";
string         botStatus = "WARRIOR READY";
string         narrative = "Buscando oportunidad...";
bool           g_bull = true; // Direccion activa del Fibo (true=compras, false=ventas)

//--- EVENTOS PRINCIPALES
int OnInit() {
   hADX = iADX(_Symbol, TF_Tendencia_Media, 14);
   ApplyPreset();
   trade.SetExpertMagicNumber(curMagic);
   hEmaH4 = iMA(_Symbol, PERIOD_H4, Periodo_EMA_Filtro, 0, MODE_EMA, PRICE_CLOSE);
   hEmaMacro = iMA(_Symbol, TF_Tendencia_Macro, Periodo_EMA_Filtro, 0, MODE_EMA, PRICE_CLOSE);
   hEmaMid = iMA(_Symbol, TF_Tendencia_Media, Periodo_EMA_Filtro, 0, MODE_EMA, PRICE_CLOSE);
   hRSI = iRSI(_Symbol, TF_Ejecucion_Gatillo, 14, PRICE_CLOSE);
   hRSI_M1 = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);
   hRSI_M5 = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE);
   hRSI_H4 = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
   ApplyPreset();
   
   // --- AÑADIR INDICADORES VISUALES AL GRÁFICO AUTOMÁTICAMENTE ---
   hEmaVisual50  = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEmaVisual200 = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
   hRsiVisual    = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   hAdxVisual    = iADX(_Symbol, _Period, 14);
   
   if(hEmaVisual50 != INVALID_HANDLE)  ChartIndicatorAdd(0, 0, hEmaVisual50);
   if(hEmaVisual200 != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hEmaVisual200);
   if(hRsiVisual != INVALID_HANDLE)    ChartIndicatorAdd(0, 1, hRsiVisual);
   if(hAdxVisual != INVALID_HANDLE)    ChartIndicatorAdd(0, 2, hAdxVisual);
   
   // Restaurar Fibo si venimos de un cambio de temporalidad o reinicio
   string pfx = "EW_FIBO_" + _Symbol + "_";
   if(GlobalVariableCheck(pfx+"F100") && GlobalVariableCheck(pfx+"F0")) {
      f100 = GlobalVariableGet(pfx+"F100");
      f0   = GlobalVariableGet(pfx+"F0");
      t100 = (datetime)GlobalVariableGet(pfx+"T100");
      t0   = (datetime)GlobalVariableGet(pfx+"T0");
      g_bull = (GlobalVariableGet(pfx+"BULL") > 0.5);
      if(f100 > 0 && f0 > 0) DrawFibo(f100, f0, t100, t0, g_bull);
   }
   
   CrearPanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, HUD_PRE); 
   if(r != REASON_CHARTCHANGE && r != REASON_PARAMETERS) {
      ObjectsDeleteAll(0, GRAF_PRE); 
   }
   if(hEmaH4 != INVALID_HANDLE) IndicatorRelease(hEmaH4);
   if(hEmaMacro != INVALID_HANDLE) IndicatorRelease(hEmaMacro);
   if(hEmaMid != INVALID_HANDLE) IndicatorRelease(hEmaMid);
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hRSI_M1 != INVALID_HANDLE) IndicatorRelease(hRSI_M1);
   if(hRSI_M5 != INVALID_HANDLE) IndicatorRelease(hRSI_M5);
   if(hRSI_H4 != INVALID_HANDLE) IndicatorRelease(hRSI_H4);
   if(hADX != INVALID_HANDLE) IndicatorRelease(hADX);
   if(hEmaVisual50 != INVALID_HANDLE) IndicatorRelease(hEmaVisual50);
   if(hEmaVisual200 != INVALID_HANDLE) IndicatorRelease(hEmaVisual200);
   if(hRsiVisual != INVALID_HANDLE) IndicatorRelease(hRsiVisual);
   if(hAdxVisual != INVALID_HANDLE) IndicatorRelease(hAdxVisual);
   EventKillTimer();
}

void ApplyPreset() {
   bool isBTC = false;
   if(Perfil_Activo == ACTIVO_BITCOIN) isBTC = true;
   else if(Perfil_Activo == ACTIVO_AUTO) {
      string sym = _Symbol;
      StringToUpper(sym);
      if(StringFind(sym, "BTC") >= 0) isBTC = true;
   }
   
   MqlDateTime dt;
   TimeCurrent(dt);
   bool isWeekend = (dt.day_of_week == 0 || dt.day_of_week == 6 || (dt.day_of_week == 5 && dt.hour >= 20));
   if(isWeekend) currentPreset = PRESET_FINDE; else currentPreset = PRESET_DIARIO;
   
   if(isBTC) {
      activoNombre = "BITCOIN (BTCUSD)";
      curMagic = (Magic_Number == 202900) ? 202901 : Magic_Number;
      curSpreadMax = 250.0;
      if(isWeekend) {
         // BTC FIN DE SEMANA (Rangos cortos, OTE 38.2, Trailing rapido y seguro)
         curHours = 12;
         curBE = 350;        // Break-Even a los $3.5 (cubre spread rapido)
         curTrailPts = 700;  // Trailing inicia a los $7.0
         curTrailDist = 350; // Distancia Trailing $3.5
         curProfundidad = OTE_382;
      } else {
         // BTC ENTRE SEMANA (Swings normales, OTE estandar)
         curHours = 36;
         curBE = 1500;
         curTrailPts = 3500;
         curTrailDist = 1500;
         curProfundidad = Profundidad_Minima_Entrada;
      }
   } else {
      activoNombre = "ORO (XAUUSD)";
      curMagic = Magic_Number;
      curSpreadMax = Max_Spread_Permitido;
      curTrailPts = Dist_Perseguir_Ganancias;
      curTrailDist = Dist_Distancia_Trailing;
      curProfundidad = Profundidad_Minima_Entrada;
      if(isWeekend) {
         curHours = Velas_Analisis_Finde;
         curBE = Dist_Seguridad_Finde_Pts;
      } else {
         curHours = Velas_Analisis_Tendencia;
         curBE = Dist_Seguridad_BreakEven_Pts;
      }
   }
   
   double adxVal[1];
   if(CopyBuffer(hADX, 0, 1, 1, adxVal) > 0) {
      double adxNum = adxVal[0];
      if(adxNum >= 22.0) {
         adxStatus = "ADX: " + DoubleToString(adxNum, 1) + " (ALTA VOLATILIDAD 🚀)";
         if(isWeekend && isBTC) {
            curProfundidad = OTE_MITAD_61_70; // Si entra fuerte volumen, protege con OTE 61.8-70.5
         }
      } else {
         adxStatus = "ADX: " + DoubleToString(adxNum, 1) + " (LATERAL / CALMA 💤)";
      }
   }
   
   curLkb = (int)(curHours * 3600 / PeriodSeconds(TF_Tendencia_Media));
   if(curLkb < 10) curLkb = 10;
}

bool CheckHorario() {
   if(!Activar_Horario) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentMins = dt.hour * 60 + dt.min;
   int startMins = Hora_Inicio * 60 + Minuto_Inicio;
   int endMins = Hora_Fin * 60 + Minuto_Fin;
   if(startMins < endMins) return (currentMins >= startMins && currentMins <= endMins);
   else return (currentMins >= startMins || currentMins <= endMins);
}

void OnTick() {
   if(isBotPaused) {
      narrative = "⏸️ BOT EN PAUSA (Trading temporalmente suspendido)";
      UpdatePanelText();
      return;
   }
   
   if(Activar_Horario && !CheckHorario()) {
      narrative = "💤 FUERA DE HORARIO (" + IntegerToString(Hora_Inicio) + ":" + StringFormat("%02d", Minuto_Inicio) + " a " + IntegerToString(Hora_Fin) + ":" + StringFormat("%02d", Minuto_Fin) + ")";
      UpdatePanelText();
      return;
   }
   
   UpdateTrends();
   if(dirMacro == 0) return;
   
   if(CountActive() == 0) {
      if(!isManualMode) DetectBOS(); else ManualBOSUpdate();
      MonitorRetracement();
   } else {
      // Si el Fibo no esta dibujado en pantalla (por reinicio o cambio de temporalidad), dibujarlo de inmediato
      if(ObjectFind(0, FIBO_NAME) < 0) {
         if(!isManualMode) DetectBOS(); else ManualBOSUpdate();
      }
      narrative = "🛡️ GESTIONANDO OPERACIÓN EN CURSO";
   }
   
   ManageRisk();
   UpdatePanelText();
}

void OnTimer() {
   if(ObjectFind(0, HUD_PRE+"bg") < 0) CrearPanel();
   UpdatePanelText();
}

void UpdateTrends() {
   double bufferH4[1];
   if(CopyBuffer(hEmaH4, 0, 1, 1, bufferH4) > 0) {
      dirH4 = (iClose(_Symbol, PERIOD_H4, 1) > bufferH4[0]) ? 1 : -1;
   }
   double bufferM[1];
   if(CopyBuffer(hEmaMacro, 0, 1, 1, bufferM) > 0) {
      dirMacro = (iClose(_Symbol, TF_Tendencia_Macro, 1) > bufferM[0]) ? 1 : -1;
   }
   double bufferH[1];
   if(CopyBuffer(hEmaMid, 0, 1, 1, bufferH) > 0) {
      dirMid = (iClose(_Symbol, TF_Tendencia_Media, 1) > bufferH[0]) ? 1 : -1;
   }
   
   // Deteccion de Zonas Mayores en H4
   int hh_h4 = iHighest(_Symbol, PERIOD_H4, MODE_HIGH, Velas_Analisis_H4, 1);
   int ll_h4 = iLowest(_Symbol, PERIOD_H4, MODE_LOW, Velas_Analisis_H4, 1);
   double hi_h4 = iHigh(_Symbol, PERIOD_H4, hh_h4);
   double lo_h4 = iLow(_Symbol, PERIOD_H4, ll_h4);
   double rsiH4_buf[1]; double rsiH4_val = 50.0;
   if(CopyBuffer(hRSI_H4, 0, 1, 1, rsiH4_buf) > 0) rsiH4_val = rsiH4_buf[0];
   double curP = iClose(_Symbol, PERIOD_M5, 0);
   double rngH4 = (hi_h4 - lo_h4);
   if(rngH4 <= 0) rngH4 = _Point * 1000;
   
   h4_enSoporte = (curP <= lo_h4 + rngH4 * 0.12) || (rsiH4_val <= 32.0);
   h4_enResistencia = (curP >= hi_h4 - rngH4 * 0.12) || (rsiH4_val >= 68.0);
   
   if(h4_enSoporte) h4StatusTxt = "EN SOPORTE MAYOR (Alerta Rebote)";
   else if(h4_enResistencia) h4StatusTxt = "EN RESISTENCIA MAYOR (Alerta Giro)";
   else h4StatusTxt = (dirH4 == 1 ? "ALCISTA" : "BAJISTA");
}

void DetectBOS() {
   ApplyPreset();
   
   bool bull;
   if(dirMacro == dirMid)  bull = (dirMacro == 1);
   else if(Corto_Manda_En_Conflicto) bull = (dirMid == 1);
   else bull = (dirMacro == 1);
   g_bull = bull;
   
   int hh = 0, ll = 0;
   double hi = 0, lo = 0;
   datetime tHi = 0, tLo = 0;
   
   if(!bull) {
      // TENDENCIA BAJISTA: Techo mayor en el lookback -> Suelo más bajo desde ese techo hasta ahora
      hh = iHighest(_Symbol, TF_Tendencia_Media, MODE_HIGH, curLkb, 0);
      hi = iHigh(_Symbol, TF_Tendencia_Media, hh);
      tHi = iTime(_Symbol, TF_Tendencia_Media, hh);
      
      int barsSincePeak = hh + 1;
      ll = iLowest(_Symbol, TF_Tendencia_Media, MODE_LOW, barsSincePeak, 0);
      lo = iLow(_Symbol, TF_Tendencia_Media, ll);
      tLo = iTime(_Symbol, TF_Tendencia_Media, ll);
   } else {
      // TENDENCIA ALCISTA: Suelo mayor en el lookback -> Techo más alto desde ese suelo hasta ahora
      ll = iLowest(_Symbol, TF_Tendencia_Media, MODE_LOW, curLkb, 0);
      lo = iLow(_Symbol, TF_Tendencia_Media, ll);
      tLo = iTime(_Symbol, TF_Tendencia_Media, ll);
      
      int barsSinceValley = ll + 1;
      hh = iHighest(_Symbol, TF_Tendencia_Media, MODE_HIGH, barsSinceValley, 0);
      hi = iHigh(_Symbol, TF_Tendencia_Media, hh);
      tHi = iTime(_Symbol, TF_Tendencia_Media, hh);
   }
   
   // Invalidar y resetear Fibo viejo si el precio rompió el 100.0 o si hay un nuevo pico dominante
   if(ObjectFind(0, FIBO_NAME) >= 0) {
      double exist_p1 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 0);
      double exist_p2 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 1);
      bool existIsBull = (exist_p1 < exist_p2);
      double curP = iClose(_Symbol, TF_Tendencia_Media, 0);
      
      if(existIsBull != bull) {
         ObjectDelete(0, FIBO_NAME);
         ObjectDelete(0, GRAF_PRE+"WAVE");
      }
      else if(!bull && (curP > exist_p1 || hi > exist_p1 + 20*_Point)) {
         ObjectDelete(0, FIBO_NAME);
         ObjectDelete(0, GRAF_PRE+"WAVE");
      }
      else if(bull && (curP < exist_p1 || lo < exist_p1 - 20*_Point)) {
         ObjectDelete(0, FIBO_NAME);
         ObjectDelete(0, GRAF_PRE+"WAVE");
      }
   }
   
   bool validSwing = (bull && tLo < tHi && (hi - lo) > 50*_Point) || (!bull && tHi < tLo && (hi - lo) > 50*_Point);
   
   if(!validSwing) {
      f61 = 0; f100 = 0; f0 = 0;
      ObjectDelete(0, FIBO_NAME);
      ObjectDelete(0, GRAF_PRE+"WAVE");
      if(CountActive() == 0) narrative = "⏳ ESPERANDO IMPULSO " + (bull ? "ALCISTA" : "BAJISTA") + " VÁLIDO";
      return;
   }
   
   f100 = bull ? lo : hi; t100 = bull ? tLo : tHi;
   f0 = bull ? hi : lo; t0 = bull ? tHi : tLo;
   DrawFibo(f100, f0, t100, t0, bull);
}

void ManualBOSUpdate() {
   if(ObjectFind(0, FIBO_NAME) < 0) return;
   f100 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 0); t100 = (datetime)ObjectGetInteger(0, FIBO_NAME, OBJPROP_TIME, 0);
   f0 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 1); t0 = (datetime)ObjectGetInteger(0, FIBO_NAME, OBJPROP_TIME, 1);
   DrawFibo(f100, f0, t100, t0, (f0 > f100));
}

void DrawFibo(double p100, double p0, datetime tm100, datetime tm0, bool bull) {
   if(ObjectFind(0, FIBO_NAME)<0) {
      ObjectCreate(0, FIBO_NAME, OBJ_FIBO, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_RAY_RIGHT, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_BACK, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELS, 8);
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 0, 0.0);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 0, "0.0 TP ZONE");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 1, 0.236);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 1, "23.6 IMP X");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 2, 0.382);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 2, "38.2 IMP 0");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 3, 0.5);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 3, "50.0");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 4, 0.618);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 4, "61.8 OTE 1");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 5, 0.705);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 5, "70.5 OTE 2");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 6, 0.786);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 6, "78.6 OTE 3");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 7, 1.0);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 7, "100.0 SL HARD");
      for(int l=0; l<8; l++) ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, l, Color_Fibo);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_COLOR, Color_Fibo);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   if(!isManualMode) { ObjectMove(0, FIBO_NAME, 0, tm100, p100); ObjectMove(0, FIBO_NAME, 1, tm0, p0); }
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   
   // Guardar coordenadas en memoria global para que persistan siempre
   string pfx = "EW_FIBO_" + _Symbol + "_";
   GlobalVariableSet(pfx+"F100", p100);
   GlobalVariableSet(pfx+"F0",   p0);
   GlobalVariableSet(pfx+"T100", (double)tm100);
   GlobalVariableSet(pfx+"T0",   (double)tm0);
   GlobalVariableSet(pfx+"BULL", bull ? 1.0 : 0.0);
   f23 = bull ? p0-(p0-p100)*0.236 : p0+(p100-p0)*0.236; 
   f38 = bull?p0-(p0-p100)*0.382:p0+(p100-p0)*0.382; 
   f50 = bull?p0-(p0-p100)*0.550:p0+(p100-p0)*0.550; // Ajustado al 55% para mayor seguridad
   f61 = bull?p0-(p0-p100)*0.618:p0+(p100-p0)*0.618; 
   f70 = bull?p0-(p0-p100)*0.705:p0+(p100-p0)*0.705; 
   f78 = bull?p0-(p0-p100)*0.786:p0+(p100-p0)*0.786;
   
   string wav = GRAF_PRE+"WAVE";
   if(!Mostrar_Linea_Diagonal) {
      ObjectDelete(0, wav);
   } else {
      if(ObjectFind(0,wav)<0) { 
         ObjectCreate(0,wav,OBJ_TREND,0,0,0,0,0); 
         ObjectSetInteger(0,wav,OBJPROP_STYLE,STYLE_DOT); 
         ObjectSetInteger(0,wav,OBJPROP_WIDTH,1);
         ObjectSetInteger(0,wav,OBJPROP_BACK,true); // Al fondo para no atravesar ni tapar el HUD
         ObjectSetInteger(0,wav,OBJPROP_RAY_RIGHT,false);
      }
      ObjectSetInteger(0,wav,OBJPROP_BACK,true);
      ObjectMove(0,wav,0,ObjectGetInteger(0,FIBO_NAME,OBJPROP_TIME,0),p100); 
      ObjectMove(0,wav,1,ObjectGetInteger(0,FIBO_NAME,OBJPROP_TIME,1),p0);
      ObjectSetInteger(0,wav,OBJPROP_COLOR,Color_Linea_Diagonal); 
   }
   ObjectSetInteger(0,FIBO_NAME,OBJPROP_SELECTABLE,isManualMode);
}

ENUM_TIMEFRAMES GetGatilloTF() {
   if(currentPreset == PRESET_FINDE) return PERIOD_M1; // Fin de semana: gatillo ultra rápido en 1 Minuto
   if(dirMacro != dirMid && Corto_Manda_En_Conflicto) return PERIOD_M1;
   return TF_Ejecucion_Gatillo;
}

void MonitorRetracement() {
   ENUM_TIMEFRAMES curGatillo = GetGatilloTF();
   string tfGatilloStr = (curGatillo == PERIOD_M1) ? "M1" : "M5";
   if(f61==0) return; double cp = iClose(_Symbol, curGatillo, 0); bool bull = (f0 > f100); 
   double ps = _Point;
   
   if(t100 != ultimo_fibo_time) {
      ultimo_fibo_time = t100;
      string gv = "EW_BALAS_" + _Symbol + "_" + IntegerToString((int)t100);
      if(GlobalVariableCheck(gv)) balas_gastadas = (int)GlobalVariableGet(gv);
      else { balas_gastadas = 0; GlobalVariableSet(gv, 0); }
   }
   
   if(balas_gastadas >= Max_Operaciones_Por_Fibo) {
      narrative = "⛔ BALAS AGOTADAS (" + IntegerToString(Max_Operaciones_Por_Fibo) + "/" + IntegerToString(Max_Operaciones_Por_Fibo) + "). Esperando Fibo.";
      return;
   }
   
   // Filtro de Spread
   double spr = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0;
   if(spr > curSpreadMax) {
      narrative = "⚠️ SPREAD ALTO: " + DoubleToString(spr, 1) + " > " + DoubleToString(curSpreadMax, 1);
      return;
   }
   
   double rsiBuffer[1];
   double rsiVal = 50.0;
   int curRsiHandle = (curGatillo == PERIOD_M1) ? hRSI_M1 : hRSI_M5;
   if(Activar_Filtro_RSI && CopyBuffer(curRsiHandle, 0, 1, 1, rsiBuffer) > 0) {
      rsiVal = rsiBuffer[0];
   }
   
   // Filtro de ADX (Evitar entrar si el mercado está completamente muerto / sin volumen)
   double adxBuf[1];
   if(CopyBuffer(hADX, 0, 1, 1, adxBuf) > 0) {
      if(adxBuf[0] < 14.0) {
         narrative = "💤 ADX MUY BAJO (" + DoubleToString(adxBuf[0],1) + " < 14): MERCADO SIN VOLUMEN";
         return;
      }
   }
   
   string balasTxt = " [BALAS: " + IntegerToString(balas_gastadas) + "/" + IntegerToString(Max_Operaciones_Por_Fibo) + "]";
   datetime velaActual = iTime(_Symbol, curGatillo, 0);
   bool cooldownOk = (velaActual != ultima_vela_operada);
   double limitEntryBull = f61; double limitEntryBear = f61;
   if(curProfundidad == OTE_382)         { limitEntryBull = f38; limitEntryBear = f38; }
   else if(curProfundidad == OTE_MITAD_61_70) { limitEntryBull = (f61+f70)/2.0; limitEntryBear = (f61+f70)/2.0; }
   else if(curProfundidad == OTE_705)   { limitEntryBull = f70; limitEntryBear = f70; }
   else if(curProfundidad == OTE_786)   { limitEntryBull = f78; limitEntryBear = f78; }
   // Umbral de confirmacion: para OTE_382 se confirma en 23.6%, para el resto en 38.2%
   double umbralConfirmBull = (curProfundidad == OTE_382) ? f23 : f38;
   double umbralConfirmBear = (curProfundidad == OTE_382) ? f23 : f38;
   double op1 = iOpen(_Symbol,curGatillo,1);
   double cl1 = iClose(_Symbol,curGatillo,1);
   double hi1 = iHigh(_Symbol,curGatillo,1);
   double lo1 = iLow(_Symbol,curGatillo,1);
   double bodySize = MathAbs(cl1 - op1);
   double candleSize = hi1 - lo1;
   bool isDoji = (candleSize > 0) ? ((bodySize / candleSize * 100.0) < Filtro_Cuerpo_Vela_Porcentaje) : true;

   if(bull) {
      if(Bloquear_En_Extremos_H4 && h4_enResistencia) {
         narrative = "🛑 FRENO H4: EN RESISTENCIA MAYOR (Peligro caída)";
         return;
      }
      if(cp <= umbralConfirmBull + 150*ps) p1_pierced = true;
      if(!cooldownOk) narrative = "⏳ ENFRIANDO VELA...";
      else if(p1_pierced || (balas_gastadas > 0 && CountActive() == 0)) {
         bool rsiOk = (!Activar_Filtro_RSI || rsiVal <= RSI_Maximo_Para_Comprar);
         string rsiTxt = Activar_Filtro_RSI ? (" [RSI: " + DoubleToString(rsiVal, 0) + (rsiOk ? " OK]" : " > " + DoubleToString(RSI_Maximo_Para_Comprar,0) + " SOBRECOMPRA]")) : "";
         narrative = "🎯 GATILLO LISTO (" + tfGatilloStr + " Alcista en " + DoubleToString(limitEntryBull,_Digits) + ")" + balasTxt + rsiTxt;
         
         bool candleOk = (cl1 > op1) && !isDoji;
         if(cp <= limitEntryBull && cp >= f100 && candleOk && rsiOk) ExecuteMarket(true);
      } else narrative = "🔎 CAZANDO RETROCESO A " + DoubleToString(f38,_Digits) + balasTxt;
   } else {
      if(Bloquear_En_Extremos_H4 && h4_enSoporte) {
         narrative = "🛑 FRENO H4: EN SOPORTE MAYOR (Peligro rebote alcista)";
         return;
      }
      if(cp >= umbralConfirmBear - 150*ps) p1_pierced = true;
      if(!cooldownOk) narrative = "⏳ ENFRIANDO VELA...";
      else if(p1_pierced || (balas_gastadas > 0 && CountActive() == 0)) {
         bool rsiOk = (!Activar_Filtro_RSI || rsiVal >= RSI_Minimo_Para_Vender);
         string rsiTxt = Activar_Filtro_RSI ? (" [RSI: " + DoubleToString(rsiVal, 0) + (rsiOk ? " OK]" : " < " + DoubleToString(RSI_Minimo_Para_Vender,0) + " SOBREVENTA]")) : "";
         narrative = "🎯 GATILLO LISTO (" + tfGatilloStr + " Bajista en " + DoubleToString(limitEntryBear,_Digits) + ")" + balasTxt + rsiTxt;
         
         bool candleOk = (cl1 < op1) && !isDoji;
         if(cp >= limitEntryBear && cp <= f100 && candleOk && rsiOk) ExecuteMarket(false);
      } else narrative = "🔎 CAZANDO RETROCESO A " + DoubleToString(f38,_Digits) + balasTxt;
   }
}

void ExecuteMarket(bool bull) {
   double lot = Lote_Fijo_Manual;
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double stepL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(lot <= 0.0) {
      double riskVal = AccountInfoDouble(ACCOUNT_BALANCE) * (Riesgo_Porcentaje_Cuenta/100.0);
      double swingDist = MathAbs(f0 - f100);
      if(swingDist <= 0) swingDist = 100 * _Point;
      lot = riskVal / (swingDist * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
      
      // Topes de seguridad para evitar lotajes desproporcionados
      double maxLotCap = 0.50; 
      if(lot > maxLotCap) lot = maxLotCap;
   }
   if(stepL > 0) lot = MathFloor(lot / stepL) * stepL;
   lot = MathMax(minL, lot);
   
   string comment = "Elite_V2_Auto";
   bool result = false;
   
   // SL Estructural con colchón de seguridad del 10% más allá del swing real
   double sl_buffer = MathAbs(f0 - f100) * 0.10;
   double stopLoss = bull ? (f100 - sl_buffer) : (f100 + sl_buffer);
   
   if(Usar_StopLoss_Estricto) {
      double sl_dist = MathAbs(f100 - f78);
      double currentPrice = bull ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      stopLoss = bull ? (currentPrice - sl_dist) : (currentPrice + sl_dist);
   }
   
   double takeProfit = f0;
   
   if(bull) result = trade.Buy(lot,_Symbol,0,stopLoss,takeProfit,comment); 
   else result = trade.Sell(lot,_Symbol,0,stopLoss,takeProfit,comment); 
   if(result) {
      balas_gastadas++;
      string gv = "EW_BALAS_" + _Symbol + "_" + IntegerToString((int)ultimo_fibo_time);
      GlobalVariableSet(gv, balas_gastadas);
      ultima_vela_operada = iTime(_Symbol, GetGatilloTF(), 0);
   }
   p1_pierced=false;
}

void ManageRisk() {
   double ps = _Point;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC)==curMagic && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         double op=PositionGetDouble(POSITION_PRICE_OPEN), cur=PositionGetDouble(POSITION_PRICE_CURRENT), sl=PositionGetDouble(POSITION_SL), tp=PositionGetDouble(POSITION_TP); 
         bool buy=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
         double pnl = buy ? (cur-op)/_Point : (op-cur)/_Point;
         if(pnl >= curBE && (sl==0 || (buy && sl<op) || (!buy && sl>op))) {
            double nsl_be = NormalizeDouble(op + (buy?10:-10)*ps, _Digits);
            trade.PositionModify(ticket, nsl_be, tp);
         }
         if(pnl >= (curBE*1.6) && (buy ? (sl < op + 90*ps) : (sl == 0 || sl > op - 90*ps))) {
            double nsl_be2 = NormalizeDouble(op + (buy?100:-100)*ps, _Digits);
            trade.PositionModify(ticket, nsl_be2, tp);
         }
         if(pnl >= curTrailPts) {
            double nsl = buy ? cur-curTrailDist*ps : cur+curTrailDist*ps;
            nsl = NormalizeDouble(nsl, _Digits);
            if((buy && nsl > sl + 20*ps) || (!buy && (nsl < sl - 20*ps || (sl==0)))) trade.PositionModify(ticket, nsl, tp);
         }
      }
   }
}

void CloseHalfPosition() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC)==curMagic && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         double vol = PositionGetDouble(POSITION_VOLUME);
         double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         double half = MathFloor((vol / 2.0) / step) * step;
         if(half >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) trade.PositionClosePartial(ticket, half);
      }
   }
}

void CloseAllPositions() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC)==curMagic && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         trade.PositionClose(ticket);
      }
   }
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd=clrGray) { ObjectCreate(0,HUD_PRE+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,10); }
void CrLabel(string n, int x, int y, string t, color c, int s) { ObjectCreate(0,HUD_PRE+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,c); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_FONTSIZE,s); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,15); }
void CrBtn(string n, int x, int y, int w, int h, string t, color bg) { ObjectCreate(0,HUD_PRE+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,12); }

//--- PANEL VISUAL COMPACTO
void CrearPanel() {
   ObjectsDeleteAll(0, HUD_PRE); 
   int x = 15, y = 30, w = 370;
   int h = isMinimized ? 40 : 490;
   
   CrRect("bg", x, y, w, h, C'18,10,10', clrMaroon); 
   CrRect("hdr", x+2, y+2, w-4, 36, clrMaroon, clrRed);
   string profileLabel = activoNombre + (currentPreset == PRESET_FINDE ? " [FINDE 🏖️]" : " [DIARIO 💼]");
   CrLabel("ttl", x+15, y+10, profileLabel, clrWhite, 9);
   CrLabel("clk", x+w-100, y+10, "[00:00]", clrGold, 10);
   CrBtn("b_min", x+w-30, y+5, 20, 20, isMinimized ? "+" : "-", clrMaroon);
   
   if(!isMinimized) {
      y += 45;
      string modoTxt   = g_bull ? "BUSCANDO: COMPRAS  (precio sube)" : "BUSCANDO: VENTAS  (precio baja)";
      color  modoColor = g_bull ? clrLime : clrOrangeRed;
      string motivoTxt = (dirMacro == dirMid) ? "H1 + M15 alineados" : (Corto_Manda_En_Conflicto ? "Conflicto: manda M15" : "Conflicto: manda H1");
      double sprActual   = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0;
      string sprColor_txt = sprActual > curSpreadMax ? "ALTO" : "OK";
      color  sprColor_col = sprActual > curSpreadMax ? clrOrangeRed : clrGray;
      CrRect("pl_bg", x+10, y, w-20, 80, clrBlack, modoColor);
      CrLabel("modo_l", x+20, y+5,  modoTxt,   modoColor, 9);
      CrLabel("motivo", x+20, y+20, motivoTxt, clrGray,   8);
      CrLabel("planA",  x+20, y+35, narrative, clrWhite,  8);
      CrLabel("vis",    x+20, y+52, "B.E.: " + (string)curBE + " pts  |  TRAILING: " + (string)curTrailPts + " pts", clrGray, 7);
      CrLabel("spr",    x+20, y+64, "Spread: " + DoubleToString(sprActual,1) + " (max " + DoubleToString(curSpreadMax,1) + ") " + sprColor_txt, sprColor_col, 7);
      y += 90;
      CrBtn("b_mod_a", x+15, y, 105, 30, "MODO AUTO",   !isManualMode?clrCyan:clrCrimson);
      CrBtn("b_mod_m", x+125, y, 105, 30, "MANUAL", isManualMode?clrCyan:clrCrimson);
      CrBtn("b_pause", x+235, y, 110, 30, isBotPaused ? "🔴 PAUSA" : "🟢 ACTIVO", isBotPaused ? clrCrimson : clrSeaGreen);
      
      y += 40;
      string oteTitle = g_bull ? "ZONAS COMPRA (precio cae hasta aqui):" : "ZONAS VENTA (precio sube hasta aqui):";
      color  oteColor = g_bull ? clrLime : clrOrangeRed;
      CrRect("ote_bg", x+10, y, w-20, 120, clrBlack, oteColor);
      CrLabel("ote_t",  x+20, y+5,  oteTitle, oteColor, 8);
      
      if(curProfundidad == OTE_382) {
         CrLabel("oteX",   x+25, y+25, "Pre-aviso (23.6%):     " + DoubleToString(f23,_Digits) + "  <- confirmación", clrGray, 8);
         CrLabel("ote1",   x+25, y+45, "Entrada Finde (38.2%): " + DoubleToString(f38,_Digits) + "  <- ZONA ACTIVA", clrGold, 8);
         CrLabel("ote2",   x+25, y+65, "Nivel Medio   (50.0%): " + DoubleToString(f50,_Digits), clrWhite, 8);
         CrLabel("ote3",   x+25, y+85, "Zona Límite  (61.8%): " + DoubleToString(f61,_Digits), clrOrangeRed, 8);
      } else {
         CrLabel("oteX",   x+25, y+25, "Impulso (23.6%): " + DoubleToString(f23,_Digits) + "  <- entrada rápida", clrGray, 8);
         CrLabel("ote1",   x+25, y+45, "OTE 1  (61.8%): " + DoubleToString(f61,_Digits), clrWhite, 8);
         CrLabel("ote2",   x+25, y+65, "OTE 2  (70.5%): " + DoubleToString(f70,_Digits) + "  <- zona óptima", clrGold, 8);
         CrLabel("ote3",   x+25, y+85, "OTE 3  (78.6%): " + DoubleToString(f78,_Digits) + "  <- límite", clrOrangeRed, 8);
      }
      CrLabel("ote100", x+25, y+105,"Stop Loss:       " + DoubleToString(f100,_Digits) + "  <- invalida Fibo", clrRed, 8);
      
      y += 130;
      CrLabel("stV", x+15, y, (CountActive()>0?"ESTADO: PROTEGIENDO":"WARRIOR READY"), clrWhite, 9);
      CrLabel("ind_line", x+15, y+16, "📊 " + adxStatus, clrGold, 8);
      CrLabel("trH4",x+15, y+30, "MACRO (H4): " + h4StatusTxt, (h4_enSoporte||h4_enResistencia?clrGold:(dirH4==1?clrCyan:clrOrangeRed)), 7);
      CrLabel("tr4", x+15, y+44, "BIAS (1H): " + (dirMacro==1?"ALCISTA":"BAJISTA"), (dirMacro==1?clrCyan:clrOrangeRed), 7);
      CrLabel("tr1", x+15, y+58, "ESTRUCTURA (M15): " + (dirMid==1?"ALCISTA":"BAJISTA"), (dirMid==1?clrCyan:clrOrangeRed), 7);
      
      y += 75;
      CrLabel("pl_prof", x+15, y,    "BENEFICIO HOY: $0.00", clrLime, 9);
      CrLabel("pl_flot", x+15, y+18, "FLOTANTE: $0.00", clrGold, 9);
      
      y += 45;
      CrBtn("b_half", x+15,  y, 160, 35, "CERRAR 50%",   clrGreen);
      CrBtn("b_cl",   x+185, y, 160, 35, "CERRAR TODO",  clrRed);
   }
}

void UpdatePanelText() {
   if(isMinimized) return;
   ENUM_TIMEFRAMES curGatillo = GetGatilloTF();
   long periodSec = PeriodSeconds(curGatillo);
   long currentSec = (long)TimeCurrent();
   long sec = periodSec - (currentSec % periodSec);
   if(sec < 0) sec = 0;
   
   string profileLabel = activoNombre + (currentPreset == PRESET_FINDE ? " [FINDE 🏖️]" : " [DIARIO 💼]");
   ObjectSetString(0,HUD_PRE+"ttl",OBJPROP_TEXT,profileLabel);
   ObjectSetString(0,HUD_PRE+"clk",OBJPROP_TEXT,StringFormat("[%02d:%02d]", sec/60, sec%60));
   string modoTxtU = g_bull ? "BUSCANDO: COMPRAS  (precio sube)" : "BUSCANDO: VENTAS  (precio baja)";
   color modoColorU = g_bull ? clrLime : clrOrangeRed;
   string motivoTxtU = (dirMacro==dirMid) ? "H1 + M15 alineados" : (Corto_Manda_En_Conflicto ? "Conflicto: manda M15" : "Conflicto: manda H1");
   ObjectSetString(0,HUD_PRE+"modo_l",OBJPROP_TEXT,modoTxtU);
   ObjectSetInteger(0,HUD_PRE+"modo_l",OBJPROP_COLOR,modoColorU);
   ObjectSetString(0,HUD_PRE+"motivo",OBJPROP_TEXT,motivoTxtU);
   ObjectSetString(0,HUD_PRE+"planA",OBJPROP_TEXT,narrative);
   double sprNow = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0;
   ObjectSetString(0,HUD_PRE+"spr",OBJPROP_TEXT,"Spread: " + DoubleToString(sprNow,1) + " (max " + DoubleToString(curSpreadMax,1) + ") " + (sprNow>curSpreadMax?"ALTO":"OK"));
   ObjectSetInteger(0,HUD_PRE+"spr",OBJPROP_COLOR,(sprNow>curSpreadMax?clrOrangeRed:clrGray));
   string oteTitle = g_bull ? "ZONAS COMPRA (precio cae hasta aqui):" : "ZONAS VENTA (precio sube hasta aqui):";
   color oteColorU = g_bull ? clrLime : clrOrangeRed;
   ObjectSetString(0,HUD_PRE+"ote_t",OBJPROP_TEXT,oteTitle);
   ObjectSetInteger(0,HUD_PRE+"ote_t",OBJPROP_COLOR,oteColorU);
   
   if(curProfundidad == OTE_382) {
      ObjectSetString(0,HUD_PRE+"oteX",OBJPROP_TEXT,"Pre-aviso (23.6%):     " + DoubleToString(f23,_Digits) + "  <- confirmación");
      ObjectSetString(0,HUD_PRE+"ote1",OBJPROP_TEXT,"Entrada Finde (38.2%): " + DoubleToString(f38,_Digits) + "  <- ZONA ACTIVA");
      ObjectSetInteger(0,HUD_PRE+"ote1",OBJPROP_COLOR,clrGold);
      ObjectSetString(0,HUD_PRE+"ote2",OBJPROP_TEXT,"Nivel Medio   (50.0%): " + DoubleToString(f50,_Digits));
      ObjectSetInteger(0,HUD_PRE+"ote2",OBJPROP_COLOR,clrWhite);
      ObjectSetString(0,HUD_PRE+"ote3",OBJPROP_TEXT,"Zona Límite  (61.8%): " + DoubleToString(f61,_Digits));
   } else {
      ObjectSetString(0,HUD_PRE+"oteX",OBJPROP_TEXT,"Impulso (23.6%): " + DoubleToString(f23,_Digits) + "  <- entrada rápida");
      ObjectSetString(0,HUD_PRE+"ote1",OBJPROP_TEXT,"OTE 1  (61.8%): " + DoubleToString(f61,_Digits));
      ObjectSetInteger(0,HUD_PRE+"ote1",OBJPROP_COLOR,clrWhite);
      ObjectSetString(0,HUD_PRE+"ote2",OBJPROP_TEXT,"OTE 2  (70.5%): " + DoubleToString(f70,_Digits) + "  <- zona óptima");
      ObjectSetInteger(0,HUD_PRE+"ote2",OBJPROP_COLOR,clrGold);
      ObjectSetString(0,HUD_PRE+"ote3",OBJPROP_TEXT,"OTE 3  (78.6%): " + DoubleToString(f78,_Digits) + "  <- límite");
   }
   ObjectSetString(0,HUD_PRE+"ote100",OBJPROP_TEXT,"Stop Loss:       " + DoubleToString(f100,_Digits) + "  <- invalida Fibo");
   
   double rsiBufNow[1]; double rsiValNow = 50.0;
   if(CopyBuffer(hRSI, 0, 1, 1, rsiBufNow) > 0) rsiValNow = rsiBufNow[0];
   ObjectSetString(0,HUD_PRE+"ind_line",OBJPROP_TEXT,"📊 " + adxStatus + " | RSI(M5): " + DoubleToString(rsiValNow,0));
   
   ObjectSetString(0,HUD_PRE+"trH4",OBJPROP_TEXT,"MACRO (H4): " + h4StatusTxt);
   ObjectSetInteger(0,HUD_PRE+"trH4",OBJPROP_COLOR,(h4_enSoporte||h4_enResistencia?clrGold:(dirH4==1?clrCyan:clrOrangeRed)));
   ObjectSetString(0,HUD_PRE+"tr4",OBJPROP_TEXT,"BIAS (1H): " + (dirMacro==1?"ALCISTA  ":"BAJISTA  "));
   ObjectSetInteger(0,HUD_PRE+"tr4",OBJPROP_COLOR,(dirMacro==1?clrCyan:clrOrangeRed));
   ObjectSetString(0,HUD_PRE+"tr1",OBJPROP_TEXT,"ESTRUCTURA (M15): " + (dirMid==1?"ALCISTA  ":"BAJISTA  "));
   ObjectSetInteger(0,HUD_PRE+"tr1",OBJPROP_COLOR,(dirMid==1?clrCyan:clrOrangeRed));
   
   double profitHoy = 0;
   datetime inicioDia = iTime(_Symbol, PERIOD_D1, 0);
   if(HistorySelect(inicioDia, TimeCurrent())) {
      for(int i=0; i<HistoryDealsTotal(); i++) {
         ulong t = HistoryDealGetTicket(i);
         if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol) continue;
         long pos_id = HistoryDealGetInteger(t, DEAL_POSITION_ID);
         if(pos_id == 0) continue;
         
         long deal_magic = HistoryDealGetInteger(t, DEAL_MAGIC);
         if(deal_magic == curMagic) {
            profitHoy += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
         } else if (deal_magic == 0 && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            if(HistorySelectByPosition(pos_id)) {
               for(int j=0; j<HistoryDealsTotal(); j++) {
                  ulong in_deal = HistoryDealGetTicket(j);
                  if(HistoryDealGetInteger(in_deal, DEAL_ENTRY) == DEAL_ENTRY_IN && HistoryDealGetInteger(in_deal, DEAL_MAGIC) == curMagic) {
                     profitHoy += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
                     break;
                  }
               }
               HistorySelect(inicioDia, TimeCurrent());
            }
         }
      }
   }
   
   double flotante = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionGetTicket(i) > 0 && PositionGetInteger(POSITION_MAGIC) == curMagic && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         flotante += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      }
   }
   
   ObjectSetString(0,HUD_PRE+"pl_prof",OBJPROP_TEXT,"BENEFICIO HOY: $" + DoubleToString(profitHoy, 2));
   ObjectSetString(0,HUD_PRE+"pl_flot",OBJPROP_TEXT,"FLOTANTE: $" + DoubleToString(flotante, 2));
   ObjectSetInteger(0,HUD_PRE+"pl_prof",OBJPROP_COLOR,(profitHoy>=0?clrLime:clrRed));
   ObjectSetInteger(0,HUD_PRE+"pl_flot",OBJPROP_COLOR,(flotante>=0?clrGold:clrRed));
   
   ObjectSetString(0,HUD_PRE+"stV",OBJPROP_TEXT,(CountActive()>0?"ESTADO: PROTEGIENDO 🛡️":"WARRIOR READY"));
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sp == HUD_PRE+"b_min") { isMinimized = !isMinimized; CrearPanel(); }
      if(sp == HUD_PRE+"b_mod_a") { isManualMode = false; ApplyPreset(); DetectBOS(); CrearPanel(); }
      if(sp == HUD_PRE+"b_mod_m") { isManualMode=true; ObjectSetInteger(0, FIBO_NAME, OBJPROP_SELECTABLE, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_SELECTED, true); CrearPanel(); ChartRedraw(); }
      if(sp == HUD_PRE+"b_pause") {
         isBotPaused = !isBotPaused;
         ObjectSetString(0, HUD_PRE+"b_pause", OBJPROP_TEXT, isBotPaused ? "🔴 PAUSA" : "🟢 ACTIVO");
         ObjectSetInteger(0, HUD_PRE+"b_pause", OBJPROP_BGCOLOR, isBotPaused ? clrCrimson : clrSeaGreen);
         ObjectSetInteger(0, sp, OBJPROP_STATE, false);
         ChartRedraw();
      }
      
      // Acciones de Botones de Cierre
      if(sp == HUD_PRE+"b_half") { CloseHalfPosition(); ObjectSetInteger(0, sp, OBJPROP_STATE, false); }
      if(sp == HUD_PRE+"b_cl") { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==curMagic) trade.PositionClose(posInfo.Ticket()); ObjectSetInteger(0, sp, OBJPROP_STATE, false); }
   }
   if(id == CHARTEVENT_OBJECT_DRAG && (sp == FIBO_NAME) && isManualMode) { ManualBOSUpdate(); }
}

int CountActive() {
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetTicket(i) > 0 && PositionGetInteger(POSITION_MAGIC) == curMagic && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         c++;
      }
   }
   return c;
}

int CountOrders() { int c=0; for(int i=OrdersTotal()-1; i>=0; i--) { ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==curMagic) c++; } return c; }
