//+------------------------------------------------------------------+
//|                        MAIKO_PRO_GOLD_DEMO_V11.34_FrancotiradorM5.mq5 |
//|                                            KOPYTRADING MAIKO     |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADING MAIKO"
#property link      "https://kopytrading.com"
#property version   "11.34"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\DealInfo.mqh>

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
CAccountInfo   accInfo;
CHistoryOrderInfo orderInfo;
CDealInfo      dealInfo;

//--- INPUT PARAMETERS ---
input group "=== GESTION DE RIESGO ==="
input double   InpLotSize        = 0.01;     // Lotes Fijos (Por defecto 0.01)

input group "=== TRAILING STOP (PUNTOS) ==="
input int      InpTrailingStart  = 200;      // Puntos a favor para activar Trailing
input int      InpTrailingStep   = 100;      // Distancia del Trailing detrás del precio

input group "=== HORARIO DE OPERATIVA ==="
input int      InpStartHour      = 0;        // Hora de Inicio (0 a 23)
input int      InpEndHour        = 24;       // Hora de Fin (1 a 24)

input group "=== FILTROS DE ESTRATEGIA ==="
input int      InpEmaPeriod      = 50;       // Periodo EMA

//--- GLOBAL VARIABLES ---
int emaHandle;
ulong MagicNumber = 113400;
string BotStatus = "INICIANDO...";

//+------------------------------------------------------------------+
//| Graficos HUD                                                     |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, int size, color col) {
    if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Trebuchet MS");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void CreatePanelBG(string name, int x, int y, int w, int h) {
    if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

double GetDailyProfit() {
    double profit = 0;
    datetime startOfDay = iTime(_Symbol, PERIOD_D1, 0);
    if(HistorySelect(startOfDay, TimeCurrent())) {
        int deals = HistoryDealsTotal();
        for(int i = 0; i < deals; i++) {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(dealInfo.SelectByIndex(i)) {
                if(dealInfo.Symbol() == _Symbol && dealInfo.Magic() == MagicNumber) {
                    profit += dealInfo.Profit() + dealInfo.Commission() + dealInfo.Swap();
                }
            }
        }
    }
    return profit;
}

void UpdateHUD() {
    CreatePanelBG("HUD_BG", 20, 20, 480, 165);
    
    CreateLabel("HUD_TITLE", 35, 30, "MAIKO PRO | CAZADOR + TRAILING STOP CLASICO", 11, clrGold);
    
    double dailyProfit = GetDailyProfit();
    color profitCol = (dailyProfit >= 0) ? clrLimeGreen : clrRed;
    string prefix = (dailyProfit >= 0) ? "+$" : "-$";
    
    CreateLabel("HUD_PROFIT_LBL", 35, 60, "GANADO HOY:", 12, clrLightGray);
    CreateLabel("HUD_PROFIT_VAL", 135, 60, prefix + DoubleToString(MathAbs(dailyProfit), 2), 12, profitCol);
    
    CreateLabel("HUD_STATUS_LBL", 35, 90, "ESTADO:", 9, clrGray);
    CreateLabel("HUD_STATUS_VAL", 90, 90, BotStatus, 9, clrCyan);
    
    MqlDateTime dt;
    TimeCurrent(dt);
    string dateStr = StringFormat("Fecha actual: %02d/%02d/%04d", dt.day, dt.mon, dt.year);
    CreateLabel("HUD_DATE", 35, 110, dateStr, 9, clrOrange);
    
    string schedText = "Trailing: Activa a los " + IntegerToString(InpTrailingStart) + " pts | Persigue a " + IntegerToString(InpTrailingStep) + " pts";
    CreateLabel("HUD_SCHED", 35, 125, schedText, 8, clrWhite);
    
    CreateLabel("HUD_LOTS", 35, 140, "Lotaje Fijo: " + DoubleToString(InpLotSize, 2), 8, clrDarkGray);
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   symInfo.Name(_Symbol);
   symInfo.Refresh();

   emaHandle = iMA(_Symbol, PERIOD_CURRENT, InpEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   if(emaHandle == INVALID_HANDLE) {
      Print("Error al crear handle de EMA.");
      return INIT_FAILED;
   }
   
   BotStatus = "INICIADO. ESPERANDO VELA...";
   UpdateHUD();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(emaHandle != INVALID_HANDLE) IndicatorRelease(emaHandle);
   ObjectsDeleteAll(0, "HUD_");
   ChartRedraw(0);
  }

bool IsNewBar() {
    static datetime last_time = 0;
    datetime time[1];
    if(CopyTime(_Symbol, PERIOD_CURRENT, 0, 1, time) <= 0) return false;
    if(time[0] != last_time) {
        if(last_time != 0) { last_time = time[0]; return true; }
        last_time = time[0];
    }
    return false;
}

//+------------------------------------------------------------------+
//| Trailing Stop Clasico por Puntos                                 |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(posInfo.SelectByIndex(i)) {
            if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber) {
                
                double currentSL = posInfo.StopLoss();
                double openPrice = posInfo.PriceOpen();
                
                if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                    double currentPrice = symInfo.Bid();
                    
                    // Si ya llevamos X puntos a favor...
                    if(currentPrice - openPrice >= InpTrailingStart * _Point) {
                        double newSL = currentPrice - (InpTrailingStep * _Point);
                        
                        // Solo lo movemos si el nuevo SL asegura mas ganancia que el anterior
                        if(currentSL == 0 || newSL > currentSL) {
                            trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
                            BotStatus = "¡TRAILING STOP SUBIENDO!";
                        }
                    }
                }
                else if(posInfo.PositionType() == POSITION_TYPE_SELL) {
                    double currentPrice = symInfo.Ask();
                    
                    if(openPrice - currentPrice >= InpTrailingStart * _Point) {
                        double newSL = currentPrice + (InpTrailingStep * _Point);
                        
                        if(currentSL == 0 || newSL < currentSL) {
                            trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
                            BotStatus = "¡TRAILING STOP BAJANDO!";
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Lógica Principal (Entradas Puras sin RSI)                        |
//+------------------------------------------------------------------+
void ProcessTradingLogic()
{
    if(!IsNewBar()) return; 

    bool hasBuy = false, hasSell = false;
    ulong buyTicket = 0, sellTicket = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(posInfo.SelectByIndex(i)) {
            if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber) {
                if(posInfo.PositionType() == POSITION_TYPE_BUY) { hasBuy = true; buyTicket = posInfo.Ticket(); }
                if(posInfo.PositionType() == POSITION_TYPE_SELL) { hasSell = true; sellTicket = posInfo.Ticket(); }
            }
        }
    }
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 2, rates) < 2) return;
    
    bool isCandle_Green = (rates[1].close > rates[1].open);
    bool isCandle_Red   = (rates[1].close < rates[1].open);
    
    // --- 1. SALIDA ESTRUCTURAL DE EMERGENCIA ---
    if(hasBuy && isCandle_Red) {
        trade.PositionClose(buyTicket);
        BotStatus = "SALIDA: VELA ROJA.";
        hasBuy = false; 
    }
    
    if(hasSell && isCandle_Green) {
        trade.PositionClose(sellTicket);
        BotStatus = "SALIDA: VELA VERDE.";
        hasSell = false; 
    }
    
    // --- 2. HORARIO OPERATIVO ---
    MqlDateTime dt;
    TimeCurrent(dt);
    if(dt.hour < InpStartHour || dt.hour >= InpEndHour) {
        if(!hasBuy && !hasSell) BotStatus = "FUERA DE HORARIO";
        return;
    }
    
    // --- 3. ENTRADAS PURAS ---
    double emaVal[1];
    if(CopyBuffer(emaHandle, 0, 1, 1, emaVal) < 1) return;
    double currentEma = emaVal[0];
    
    // COMPRA: Vela Verde + Por encima de la EMA. 
    if(!hasBuy && !hasSell && isCandle_Green && rates[1].close > currentEma) {
        trade.Buy(InpLotSize, _Symbol, 0, rates[1].low, 0, "Tendencia Buy");
        BotStatus = "¡COMPRA! SURFEANDO TENDENCIA...";
    }
    
    // VENTA: Vela Roja + Por debajo de la EMA.
    if(!hasBuy && !hasSell && isCandle_Red && rates[1].close < currentEma) {
        trade.Sell(InpLotSize, _Symbol, 0, rates[1].high, 0, "Tendencia Sell");
        BotStatus = "¡VENTA! SURFEANDO TENDENCIA...";
    }
}

void OnTick()
  {
   symInfo.RefreshRates();
   ManageTrailingStop(); // El Trailing stop actúa tick a tick
   ProcessTradingLogic(); // Las velas se leen una vez por barra
   UpdateHUD();
  }
