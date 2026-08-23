//+------------------------------------------------------------------+
//|                    XAUUSD_Zone_Recovery_PRO.mq5                  |
//|               ESCALPER DE ALTA FRECUENCIA (ZONE RECOVERY)        |
//+------------------------------------------------------------------+
#property copyright "Zone Recovery Scalper"
#property version   "1.0"
#property description "Escalpeo rápido con giros agresivos (Hedging de Recuperación)"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
CAccountInfo   accInfo;

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
input group "=== GESTIÓN DE CAPITAL ==="
input double   LotajeInicial      = 0.01;       // Lotaje de la primera entrada
input double   MultiplicadorGiro  = 3.0;        // Multiplicador al darse la vuelta (ej. 0.01 -> 0.03)
input double   ProfitObjetivoUSD  = 1.00;       // Beneficio neto para cerrar TODO ($)
input double   MaxDrawdownPct     = 10.0;       // Stop Loss de Equidad (%) -> Cierra todo si se alcanza

input group "=== ZONA DE RECUPERACIÓN ==="
input double   ZonaGiroPips       = 15.0;       // Pips en contra para darse la vuelta
input int      MaxGiros           = 5;          // Límite de giros permitidos

input group "=== AVANZADO ==="
input ulong    MagicNumber        = 999111;     // Número mágico único

// Variables globales
int ema9Handle, ema21Handle;
double ema9[], ema21[];
datetime ultimaVela = 0;

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION FUNCTION                                   |
//+------------------------------------------------------------------+
int OnInit() {
    trade.SetExpertMagicNumber(MagicNumber);
    
    ema9Handle = iMA(_Symbol, PERIOD_M1, 9, 0, MODE_EMA, PRICE_CLOSE);
    ema21Handle = iMA(_Symbol, PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE);
    
    ArraySetAsSeries(ema9, true);
    ArraySetAsSeries(ema21, true);
    
    ChartIndicatorAdd(0, 0, ema9Handle);
    ChartIndicatorAdd(0, 0, ema21Handle);
    
    Comment("--- KAMIKAZE ZONE RECOVERY ---\nIniciando sistema... esperando tick.");
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    IndicatorRelease(ema9Handle);
    IndicatorRelease(ema21Handle);
    ChartIndicatorDelete(0, 0, "Moving Average(9,0,Exponential,Close)");
    ChartIndicatorDelete(0, 0, "Moving Average(21,0,Exponential,Close)");
    Comment("");
}

//+------------------------------------------------------------------+
//| EXPERT TICK FUNCTION                                             |
//+------------------------------------------------------------------+
void OnTick() {
    double equity = accInfo.Equity();
    double balance = accInfo.Balance();
    
    // 2. CONTABILIZAR POSICIONES ACTUALES
    int numPos = 0;
    double flotanteTotal = 0;
    double lotesUltimaPos = 0;
    double precioUltimaPos = 0;
    ENUM_POSITION_TYPE tipoUltimaPos = -1;

    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(posInfo.SelectByIndex(i)) {
            if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber) {
                numPos++;
                flotanteTotal += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
                // Como leemos de arriba a abajo, la posicion en index 0 suele ser la primera, 
                // pero guardamos la "ultima" como la más reciente para el Zone Recovery.
                if(numPos == 1) { 
                    lotesUltimaPos = posInfo.Volume();
                    precioUltimaPos = posInfo.PriceOpen();
                    tipoUltimaPos = posInfo.PositionType();
                }
            }
        }
    }

    // 1. CONTROL DE RIESGO (Stop Loss de Equidad)
    double drawdown = ((balance - equity) / balance) * 100.0;
    if(drawdown >= MaxDrawdownPct && balance > 0 && numPos > 0) {
        CerrarTodasLasPosiciones("STOP LOSS EQUIDAD ALCANZADO");
        return;
    }

    // 3. CERRAR SI LLEGAMOS AL OBJETIVO (Salida en segundos)
    if(numPos > 0 && flotanteTotal >= ProfitObjetivoUSD) {
        CerrarTodasLasPosiciones("PROFIT OBJETIVO ALCANZADO");
        return;
    }

    // Mostrar info en pantalla
    string info = StringFormat("--- KAMIKAZE ZONE RECOVERY ---\nPosiciones: %d\nFlotante: $%.2f\nObjetivo: $%.2f", numPos, flotanteTotal, ProfitObjetivoUSD);
    Comment(info);

    // 4. LÓGICA DE ENTRADA Y GESTIÓN
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    if(numPos == 0) {
        // ENTRADA INICIAL: Cruce de EMAs en M1 (Muy rápido)
        datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
        if(tiempoActual != ultimaVela) {
            CopyBuffer(ema9Handle, 0, 1, 2, ema9);
            CopyBuffer(ema21Handle, 0, 1, 2, ema21);
            
            bool cruceAlcista = (ema9[1] > ema21[1] && ema9[0] <= ema21[0]); // vela 1 cruzó hacia arriba de vela 0 (series)
            bool cruceBajista = (ema9[1] < ema21[1] && ema9[0] >= ema21[0]);

            if(cruceAlcista) {
                trade.Buy(LotajeInicial, _Symbol, 0, 0, 0, "ZR_INICIO");
                ultimaVela = tiempoActual;
            } else if(cruceBajista) {
                trade.Sell(LotajeInicial, _Symbol, 0, 0, 0, "ZR_INICIO");
                ultimaVela = tiempoActual;
            }
        }
    } 
    else if(numPos > 0 && numPos < MaxGiros) {
        // ZONE RECOVERY: Si se va en contra, abrimos la contraria multiplicada
        double distanciaPips = 0;
        
        if(tipoUltimaPos == POSITION_TYPE_BUY) {
            distanciaPips = (precioUltimaPos - bid) / (point * 10);
            if(distanciaPips >= ZonaGiroPips) {
                double lotesNuevos = NormalizeDouble(lotesUltimaPos * MultiplicadorGiro, 2);
                trade.Sell(lotesNuevos, _Symbol, 0, 0, 0, "ZR_GIRO_BAJISTA");
            }
        } 
        else if(tipoUltimaPos == POSITION_TYPE_SELL) {
            distanciaPips = (ask - precioUltimaPos) / (point * 10);
            if(distanciaPips >= ZonaGiroPips) {
                double lotesNuevos = NormalizeDouble(lotesUltimaPos * MultiplicadorGiro, 2);
                trade.Buy(lotesNuevos, _Symbol, 0, 0, 0, "ZR_GIRO_ALCISTA");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| FUNCION PARA CERRAR TODO                                         |
//+------------------------------------------------------------------+
void CerrarTodasLasPosiciones(string razon) {
    Print("CERRANDO TODO: ", razon);
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(posInfo.SelectByIndex(i)) {
            if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber) {
                if(posInfo.PositionType() == POSITION_TYPE_BUY) trade.PositionClose(posInfo.Ticket());
                else if(posInfo.PositionType() == POSITION_TYPE_SELL) trade.PositionClose(posInfo.Ticket());
            }
        }
    }
}
