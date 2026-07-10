$files = @(
    "private_bots_backup\Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5",
    "private_bots_backup\Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "private_bots_backup\Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5"
)

# 1. Replacement for inputs
$newInputs = '// --- FILTRO DE TECHOS Y SUELOS (SOPORTES Y RESISTENCIAS) ---
input group "===[ 🏛️ FILTRO DE TECHOS Y SUELOS ]====================================="
input bool             UsarFiltroTechosSuelos     = true;        // 🏛️ Activar Filtro Techos y Suelos M15 (S/R)
input ENUM_TIMEFRAMES  TimeframeTechosSuelos      = PERIOD_M15;  // 📅 Temporalidad para Techos/Suelos M15
input int              PeriodoTechosSuelos        = 24;          // 🔢 Período de Velas M15 a Analizar
input double           DistanciaTechoSueloPips    = 15.0;        // 📏 Distancia Mínima M15 para Bloquear (Pips)

// --- FILTROS ADICIONALES MULTI-TEMPORALIDAD (H1 y H4) ---
input bool             UsarFiltroTechosSuelosH1   = true;        // 📊 Activar Filtro S/R en H1
input int              PeriodoTechosSuelosH1      = 24;          // 📅 Período H1 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH1  = 30.0;        // 📅 Distancia Mínima H1 (Pips)

input bool             UsarFiltroTechosSuelosH4   = true;        // 📊 Activar Filtro S/R en H4
input int              PeriodoTechosSuelosH4      = 24;          // 📅 Período H4 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH4  = 50.0;        // 📅 Distancia Mínima H4 (Pips)

// --- FILTRO DE AGOTAMIENTO DE VELAS (RECHAZO DE MECHA M15) ---
input bool             UsarFiltroAgotamientoM15   = true;        // 🕯️ Activar Filtro Agotamiento M15
input double           MinPorcentajeMechaM15      = 40.0;        // 🕯️ % Mínimo Mecha Reversa (40.0 = 40%)'

# 2. Replacement for ValidarTechosSuelos
$newFunction = 'bool ValidarTechosSuelos(string decision) {
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point_pips = _Point * 10;
    int start_bar = 1;

    // --- 1. Filtro original M15 ---
    if(UsarFiltroTechosSuelos) {
        int highest_idx = iHighest(_Symbol, TimeframeTechosSuelos, MODE_HIGH, PeriodoTechosSuelos, start_bar);
        int lowest_idx = iLowest(_Symbol, TimeframeTechosSuelos, MODE_LOW, PeriodoTechosSuelos, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, TimeframeTechosSuelos, highest_idx);
            double lowest_low = iLow(_Symbol, TimeframeTechosSuelos, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling <= DistanciaTechoSueloPips) {
                    txtVeredicto = StringFormat("TECHO M15 CERCANO (%.1f pips)", dist_to_ceiling);
                    return false;
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor <= DistanciaTechoSueloPips) {
                    txtVeredicto = StringFormat("SUELO M15 CERCANO (%.1f pips)", dist_to_floor);
                    return false;
                }
            }
        }
    }

    // --- 2. Filtro H1 ---
    if(UsarFiltroTechosSuelosH1) {
        int highest_idx = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, PeriodoTechosSuelosH1, start_bar);
        int lowest_idx = iLowest(_Symbol, PERIOD_H1, MODE_LOW, PeriodoTechosSuelosH1, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, PERIOD_H1, highest_idx);
            double lowest_low = iLow(_Symbol, PERIOD_H1, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling <= DistanciaTechoSueloPipsH1) {
                    txtVeredicto = StringFormat("TECHO H1 CERCANO (%.1f pips)", dist_to_ceiling);
                    return false;
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor <= DistanciaTechoSueloPipsH1) {
                    txtVeredicto = StringFormat("SUELO H1 CERCANO (%.1f pips)", dist_to_floor);
                    return false;
                }
            }
        }
    }

    // --- 3. Filtro H4 ---
    if(UsarFiltroTechosSuelosH4) {
        int highest_idx = iHighest(_Symbol, PERIOD_H4, MODE_HIGH, PeriodoTechosSuelosH4, start_bar);
        int lowest_idx = iLowest(_Symbol, PERIOD_H4, MODE_LOW, PeriodoTechosSuelosH4, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, PERIOD_H4, highest_idx);
            double lowest_low = iLow(_Symbol, PERIOD_H4, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling <= DistanciaTechoSueloPipsH4) {
                    txtVeredicto = StringFormat("TECHO H4 CERCANO (%.1f pips)", dist_to_ceiling);
                    return false;
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor <= DistanciaTechoSueloPipsH4) {
                    txtVeredicto = StringFormat("SUELO H4 CERCANO (%.1f pips)", dist_to_floor);
                    return false;
                }
            }
        }
    }

    // --- 4. Filtro de Agotamiento de Velas (Rechazo de Mecha M15) ---
    if(UsarFiltroAgotamientoM15) {
        double open15 = iOpen(_Symbol, PERIOD_M15, 1);
        double close15 = iClose(_Symbol, PERIOD_M15, 1);
        double high15 = iHigh(_Symbol, PERIOD_M15, 1);
        double low15 = iLow(_Symbol, PERIOD_M15, 1);
        
        double totalRange = high15 - low15;
        if(totalRange > 0) {
            if(decision == "BUY") {
                double upperWick = high15 - MathMax(open15, close15);
                double wickRatio = (upperWick / totalRange) * 100.0;
                if(wickRatio >= MinPorcentajeMechaM15) {
                    txtVeredicto = StringFormat("MECHA ALTA M15 RECHAZO (%.1f%%)", wickRatio);
                    return false;
                }
            }
            else if(decision == "SELL") {
                double lowerWick = MathMin(open15, close15) - low15;
                double wickRatio = (lowerWick / totalRange) * 100.0;
                if(wickRatio >= MinPorcentajeMechaM15) {
                    txtVeredicto = StringFormat("MECHA BAJA M15 RECHAZO (%.1f%%)", wickRatio);
                    return false;
                }
            }
        }
    }

    return true;
}'

foreach ($file in $files) {
    Write-Host "Modifying file: $file"
    # Load content as string using UTF-8 to preserve Spanish accent characters and emojis
    $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

    # Replace S/R inputs
    $content = $content -replace '(?s)// --- FILTRO DE TECHOS Y SUELOS \(SOPORTES Y RESISTENCIAS\) ---.*?DistanciaTechoSueloPips\s*=\s*15\.0;[^\r\n]*', $newInputs

    # Replace ProfitCosechaIndividual if it was 1.0
    $content = $content -replace 'input double\s+ProfitCosechaIndividual\s*=\s*1\.0;', 'input double   ProfitCosechaIndividual    = 0.75;        // 💵 Beneficio Cierre SOS Individual ($)'

    # Replace ValidarTechosSuelos function body
    $content = $content -replace '(?s)bool\s+ValidarTechosSuelos\(string\s+decision\)\s*\{.*?return\s+true;\s*\}', $newFunction

    # Write content back using UTF-8
    [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Finished modifying: $file"
}
