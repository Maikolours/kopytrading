//+------------------------------------------------------------------+
//|                                       Cerrar_Analisis_Rachas.mq5 |
//|                                            KOPYTRADING MAIKO     |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADING"
#property version   "1.00"

void OnStart()
{
    ObjectsDeleteAll(0, "MaikoStats_");
    ChartRedraw(0);
}
