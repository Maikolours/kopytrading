//+------------------------------------------------------------------+
//|                                        Analisis_Rachas_Velas.mq5 |
//|                                            KOPYTRADING MAIKO     |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADING"
#property version   "2.10"
#property script_show_inputs

input int DiasAAnalizar = 5; // Días de histórico a analizar

void CreateLabel(string name, int x, int y, string text, int size, color col) {
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Trebuchet MS");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER); // El ancla es la izquierda, dibuja hacia la derecha
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void CreateBackground(string name, int x, int y, int w, int h) {
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); // Distancia desde la derecha hasta el borde derecho de la caja
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void OnStart()
{
    ObjectsDeleteAll(0, "MaikoStats_");

    int minPorVela = PeriodSeconds(_Period) / 60;
    int totalVelas = (DiasAAnalizar * 1440) / minPorVela; 
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    if(CopyRates(_Symbol, _Period, 0, totalVelas, rates) <= 0) {
        MessageBox("Error copiando datos del gráfico.", "Error", MB_ICONERROR);
        return;
    }
    
    int rachasVerdes[20]; ArrayInitialize(rachasVerdes, 0);
    int rachasRojas[20];  ArrayInitialize(rachasRojas, 0);
    
    int currentStreak = 0;
    int currentType = 0; 
    int totalVerdesIniciadas = 0;
    int totalRojasIniciadas = 0;
    
    for(int i = totalVelas - 1; i >= 0; i--) {
        double open = rates[i].open;
        double close = rates[i].close;
        
        int type = 0;
        if(close > open) type = 1;
        else if(close < open) type = -1;
        
        if(type == 0) continue; 
        
        if(type == currentType) {
            currentStreak++;
        } else {
            if(currentType == 1 && currentStreak > 0) {
                totalVerdesIniciadas++;
                if(currentStreak < 20) rachasVerdes[currentStreak]++;
                else rachasVerdes[19]++;
            }
            else if(currentType == -1 && currentStreak > 0) {
                totalRojasIniciadas++;
                if(currentStreak < 20) rachasRojas[currentStreak]++;
                else rachasRojas[19]++;
            }
            currentType = type;
            currentStreak = 1;
        }
    }
    
    int greensSeguidas = 0; for(int i=2; i<20; i++) greensSeguidas += rachasVerdes[i];
    int redsSeguidas = 0;   for(int i=2; i<20; i++) redsSeguidas += rachasRojas[i];
    
    double pctGreen1 = totalVerdesIniciadas > 0 ? (double)rachasVerdes[1]/totalVerdesIniciadas*100 : 0;
    double pctGreen2 = totalVerdesIniciadas > 0 ? (double)greensSeguidas/totalVerdesIniciadas*100 : 0;
    double pctRed1 = totalRojasIniciadas > 0 ? (double)rachasRojas[1]/totalRojasIniciadas*100 : 0;
    double pctRed2 = totalRojasIniciadas > 0 ? (double)redsSeguidas/totalRojasIniciadas*100 : 0;
    
    string sPeriod = EnumToString(_Period);
    StringReplace(sPeriod, "PERIOD_", "");

    // Configuración para la esquina DERECHA
    // La caja medirá 380px de ancho y estará a 10px del borde derecho.
    // Por tanto, el borde izquierdo de la caja estará a 390px del borde derecho.
    int bgRightMargin = 10;
    int bgWidth = 380;
    int bgLeftEdge = bgRightMargin + bgWidth; // 390
    
    int startY = 30;
    
    CreateBackground("MaikoStats_BG", bgRightMargin, startY, bgWidth, 320);
    
    // Los textos se anclan por la izquierda. Para que queden dentro de la caja, 
    // su X_DISTANCE (desde la derecha) debe ser un poco menos que 390, ej. 375.
    int textLeftMargin = bgLeftEdge - 15; // 375
    
    CreateLabel("MaikoStats_T1", textLeftMargin, startY + 15, "📊 ANÁLISIS DE RACHAS (" + sPeriod + " - " + IntegerToString(DiasAAnalizar) + " Días)", 12, clrGold);
    
    int y = startY + 50;
    CreateLabel("MaikoStats_L1", textLeftMargin, y, "🟢 VELAS VERDES TOTAL INICIADAS: " + IntegerToString(totalVerdesIniciadas), 10, clrLimeGreen);
    y += 20;
    CreateLabel("MaikoStats_L2", textLeftMargin - 15, y, "► Mueren solas (1 Vela): " + DoubleToString(pctGreen1, 1) + "%", 10, clrWhite);
    y += 20;
    CreateLabel("MaikoStats_L3", textLeftMargin - 15, y, "► Siguen (2 o más): " + DoubleToString(pctGreen2, 1) + "%", 10, clrLimeGreen);
    y += 20;
    CreateLabel("MaikoStats_L4", textLeftMargin - 30, y, "De ese patrón: 2 seguidas = " + IntegerToString(rachasVerdes[2]), 9, clrLightGray);
    y += 18;
    CreateLabel("MaikoStats_L5", textLeftMargin - 30, y, "                         3 seguidas = " + IntegerToString(rachasVerdes[3]), 9, clrLightGray);
    y += 18;
    CreateLabel("MaikoStats_L6", textLeftMargin - 30, y, "                         4 seguidas = " + IntegerToString(rachasVerdes[4]), 9, clrLightGray);
    
    y += 35;
    CreateLabel("MaikoStats_L7", textLeftMargin, y, "🔴 VELAS ROJAS TOTAL INICIADAS: " + IntegerToString(totalRojasIniciadas), 10, clrRed);
    y += 20;
    CreateLabel("MaikoStats_L8", textLeftMargin - 15, y, "► Mueren solas (1 Vela): " + DoubleToString(pctRed1, 1) + "%", 10, clrWhite);
    y += 20;
    CreateLabel("MaikoStats_L9", textLeftMargin - 15, y, "► Siguen (2 o más): " + DoubleToString(pctRed2, 1) + "%", 10, clrRed);
    y += 20;
    CreateLabel("MaikoStats_L10", textLeftMargin - 30, y, "De ese patrón: 2 seguidas = " + IntegerToString(rachasRojas[2]), 9, clrLightGray);
    y += 18;
    CreateLabel("MaikoStats_L11", textLeftMargin - 30, y, "                         3 seguidas = " + IntegerToString(rachasRojas[3]), 9, clrLightGray);
    y += 18;
    CreateLabel("MaikoStats_L12", textLeftMargin - 30, y, "                         4 seguidas = " + IntegerToString(rachasRojas[4]), 9, clrLightGray);

    y += 35;
    CreateLabel("MaikoStats_L13", textLeftMargin, y, "💡 Info: El análisis lee la temporalidad que tengas abierta.", 8, clrYellow);
    
    ChartRedraw(0);
}
