import os

files_to_fix = [
    r"c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_OCTUBRE\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5",
    r"c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5"
]

for file_path in files_to_fix:
    if not os.path.exists(file_path):
        print("File not found:", file_path)
        continue

    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # Replacement 1: OnInit hRSI creation
    old_oninit = """    // Handles de Indicadores Técnicos
    hSlowEMA = iMA(_Symbol, InpTimeframeRef, 200, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_Chart = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
    hATR = iATR(_Symbol, _Period, 14);
    hFractals = iFractals(_Symbol, _Period);

    if (hRSI == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE || hEMA_Chart == INVALID_HANDLE || hFractals == INVALID_HANDLE)"""

    new_oninit = """    // Handles de Indicadores Técnicos
    hSlowEMA = iMA(_Symbol, InpTimeframeRef, 200, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_Chart = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
    hATR = iATR(_Symbol, _Period, 14);
    hFractals = iFractals(_Symbol, _Period);
    if (hRSI == INVALID_HANDLE || hRSI == 0)
    {
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
    }

    if (hRSI == INVALID_HANDLE || hRSI == 0 || hSlowEMA == INVALID_HANDLE || hEMA_Chart == INVALID_HANDLE || hFractals == INVALID_HANDLE)"""

    if old_oninit in content:
        content = content.replace(old_oninit, new_oninit)
        print(f"Patched OnInit in {file_path}")
    else:
        print(f"old_oninit not found in {file_path}")

    # Replacement 2: SincronizarIndicadoresEnGrafico and AsegurarIndicadoresEnGrafico
    old_sync = """//+------------------------------------------------------------------+
//| Sincronizar e Insertar Indicadores Oficiales (RSI + EMA 200 H1) |
//+------------------------------------------------------------------+
void SincronizarIndicadoresEnGrafico()
{
    int totalVentanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);

    // 1. Eliminar cualquier RSI previo en subventanas para evitar duplicados
    for (int w = 0; w < totalVentanas; w++)
    {
        int totalInd = ChartIndicatorsTotal(0, w);
        for (int i = totalInd - 1; i >= 0; i--)
        {
            string name = ChartIndicatorName(0, w, i);
            if (StringFind(name, "RSI") >= 0 || StringFind(name, "Relative Strength Index") >= 0)
            {
                ChartIndicatorDelete(0, w, name);
            }
        }
    }

    // 2. Insertar RSI oficial en Subventana (Usar subventana 1 si existe, o -1 para crear nueva subventana)
    if (hRSI != INVALID_HANDLE)
    {
        int subWinRSI = (ChartGetInteger(0, CHART_WINDOWS_TOTAL) > 1) ? 1 : -1;
        ChartIndicatorAdd(0, subWinRSI, hRSI);
    }

    // 3. Eliminar EMAs previas en Ventana Principal (Subventana 0) para forzar la EMA 200 H1 del bot
    int totalMain = ChartIndicatorsTotal(0, 0);
    for (int i = totalMain - 1; i >= 0; i--)
    {
        string name = ChartIndicatorName(0, 0, i);
        if (StringFind(name, "Moving Average") >= 0 || StringFind(name, "MA") >= 0)
        {
            ChartIndicatorDelete(0, 0, name);
        }
    }

    // 4. Insertar EMA 200 oficial en Ventana Principal (Subventana 0) solo si el filtro de tendencia está activado
    if (InpFiltroTendencia == TENDENCIA_EMA200_STRICT)
    {
        int handleParaGrafico = (InpTimeframeRef == _Period) ? hSlowEMA : hEMA_Chart;
        if (handleParaGrafico != INVALID_HANDLE)
        {
            ChartIndicatorAdd(0, 0, handleParaGrafico);
        }
        else if (hEMA_Chart != INVALID_HANDLE)
        {
            ChartIndicatorAdd(0, 0, hEMA_Chart);
        }
    }

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Asegurar visualización de indicadores                            |
//+------------------------------------------------------------------+
void AsegurarIndicadoresEnGrafico()
{
    static int ultimoPeriodoRSI = -1;
    static int ultimoFiltroTendencia = -1;
    static bool indicadoresCargados = false;

    bool filtroActivo = (InpFiltroTendencia == TENDENCIA_EMA200_STRICT);
    int totalWins = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);

    if (!indicadoresCargados || 
        ultimoPeriodoRSI != rsiPeriodEfectivo || 
        ultimoFiltroTendencia != (int)InpFiltroTendencia || 
        totalWins < 2 || 
        (filtroActivo && ChartIndicatorsTotal(0, 0) < 1))
    {
        ultimoPeriodoRSI = rsiPeriodEfectivo;
        ultimoFiltroTendencia = (int)InpFiltroTendencia;
        indicadoresCargados = true;
        SincronizarIndicadoresEnGrafico();
    }
}"""

    new_sync = """//+------------------------------------------------------------------+
//| Sincronizar e Insertar Indicadores Oficiales (RSI + EMA 200 H1) |
//+------------------------------------------------------------------+
void SincronizarIndicadoresEnGrafico()
{
    int totalVentanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    bool tieneRSI = false;

    // 1. Verificar si ya existe RSI en el gráfico
    for (int w = 0; w < totalVentanas; w++)
    {
        int totalInd = ChartIndicatorsTotal(0, w);
        for (int i = 0; i < totalInd; i++)
        {
            string name = ChartIndicatorName(0, w, i);
            if (StringFind(name, "RSI") >= 0 || StringFind(name, "Relative Strength Index") >= 0)
            {
                tieneRSI = true;
                break;
            }
        }
    }

    // 2. Insertar RSI oficial en una subventana si no está presente
    if (!tieneRSI)
    {
        if (hRSI == INVALID_HANDLE || hRSI == 0)
        {
            hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
        }
        if (hRSI != INVALID_HANDLE && hRSI != 0)
        {
            ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI);
        }
    }

    // 3. Eliminar EMAs previas en Ventana Principal (Subventana 0) para forzar la EMA 200 H1 del bot
    int totalMain = ChartIndicatorsTotal(0, 0);
    for (int i = totalMain - 1; i >= 0; i--)
    {
        string name = ChartIndicatorName(0, 0, i);
        if (StringFind(name, "Moving Average") >= 0 || StringFind(name, "MA") >= 0)
        {
            ChartIndicatorDelete(0, 0, name);
        }
    }

    // 4. Insertar EMA 200 oficial en Ventana Principal (Subventana 0) solo si el filtro de tendencia está activado
    if (InpFiltroTendencia == TENDENCIA_EMA200_STRICT)
    {
        int handleParaGrafico = (InpTimeframeRef == _Period) ? hSlowEMA : hEMA_Chart;
        if (handleParaGrafico != INVALID_HANDLE && handleParaGrafico != 0)
        {
            ChartIndicatorAdd(0, 0, handleParaGrafico);
        }
        else if (hEMA_Chart != INVALID_HANDLE && hEMA_Chart != 0)
        {
            ChartIndicatorAdd(0, 0, hEMA_Chart);
        }
    }

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Asegurar visualización de indicadores                            |
//+------------------------------------------------------------------+
void AsegurarIndicadoresEnGrafico()
{
    static int ultimoPeriodoRSI = -1;
    static int ultimoFiltroTendencia = -1;
    static bool indicadoresCargados = false;

    bool filtroActivo = (InpFiltroTendencia == TENDENCIA_EMA200_STRICT);

    if (!indicadoresCargados || 
        ultimoPeriodoRSI != rsiPeriodEfectivo || 
        ultimoFiltroTendencia != (int)InpFiltroTendencia || 
        (filtroActivo && ChartIndicatorsTotal(0, 0) < 1))
    {
        ultimoPeriodoRSI = rsiPeriodEfectivo;
        ultimoFiltroTendencia = (int)InpFiltroTendencia;
        indicadoresCargados = true;
        SincronizarIndicadoresEnGrafico();
    }
}"""

    if old_sync in content:
        content = content.replace(old_sync, new_sync)
        print(f"Patched Sync logic in {file_path}")
    else:
        print(f"old_sync not found in {file_path}")

    # Replacement 3: OnTick RSI CopyBuffer validation
    old_tick_rsi = """    // Actualizar valor en vivo del RSI
    double rsiLive[];
    ArraySetAsSeries(rsiLive, true);
    if (CopyBuffer(hRSI, 0, 0, 1, rsiLive) > 0)
    {
        rsiActualVal = rsiLive[0];
    }"""

    new_tick_rsi = """    // Actualizar valor en vivo del RSI con validación estricta (0.0 - 100.0)
    if (hRSI == INVALID_HANDLE || hRSI == 0)
    {
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
    }
    if (hRSI != INVALID_HANDLE && hRSI != 0)
    {
        double rsiLive[];
        ArraySetAsSeries(rsiLive, true);
        if (CopyBuffer(hRSI, 0, 0, 1, rsiLive) > 0)
        {
            if (rsiLive[0] >= 0.0 && rsiLive[0] <= 100.0)
            {
                rsiActualVal = rsiLive[0];
            }
        }
    }"""

    if old_tick_rsi in content:
        content = content.replace(old_tick_rsi, new_tick_rsi)
        print(f"Patched OnTick RSI in {file_path}")
    else:
        print(f"old_tick_rsi not found in {file_path}")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Saved updated file:", file_path)
