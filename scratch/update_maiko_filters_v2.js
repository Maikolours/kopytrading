const fs = require('fs');

const files = [
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5"
];

const newSRInputs = `// --- FILTRO DE TECHOS Y SUELOS (SOPORTES Y RESISTENCIAS) ---
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
input double           MinPorcentajeMechaM15      = 40.0;        // 🕯️ % Mínimo Mecha Reversa (40.0 = 40%)

// --- CONFIRMACION DE RUPTURA ---
input bool             UsarConfirmacionRuptura    = true;        // 📈 Confirmar Ruptura de S/R con Vela Cerrada
input ENUM_TIMEFRAMES  TimeframeConfirmacion      = PERIOD_M5;   // 📅 Temporalidad de Confirmación (M5/M15)`;

const newFunction = `bool ValidarTechosSuelos(string decision) {
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
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPips) {
                        txtVeredicto = StringFormat("TECHO M15 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO M15";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPips) {
                        txtVeredicto = StringFormat("SUELO M15 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO M15";
                            return false;
                        }
                    }
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
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPipsH1) {
                        txtVeredicto = StringFormat("TECHO H1 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO H1";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPipsH1) {
                        txtVeredicto = StringFormat("SUELO H1 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO H1";
                            return false;
                        }
                    }
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
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPipsH4) {
                        txtVeredicto = StringFormat("TECHO H4 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO H4";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPipsH4) {
                        txtVeredicto = StringFormat("SUELO H4 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO H4";
                            return false;
                        }
                    }
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
}`;

const newHudCheck = `    } else {
        // --- DETECCION CONTINUA DE FILTROS PARA EL HUD ---
        double ema[1];
        if(CopyBuffer(hEMA_v, 0, 1, 1, ema) > 0) {
            double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            string potential_dir = (precio > ema[0]) ? "BUY" : "SELL";
            if(!ValidarTechosSuelos(potential_dir)) {
                txtVoz = "SCHOLAR: " + txtVeredicto;
            } else {
                if(!enFaseAnalisis) {
                    txtVoz = "SCHOLAR: Buscando...";
                    txtVeredicto = "ESPERANDO...";
                }
            }
        } else {
            if(!enFaseAnalisis) {
                txtVoz = "SCHOLAR: Buscando...";
                txtVeredicto = "ESPERANDO...";
            }
        }
    }`;

files.forEach(file => {
    console.log("\nModifying file:", file);
    if (!fs.existsSync(file)) {
        console.error("File not found:", file);
        return;
    }
    let content = fs.readFileSync(file, 'utf8');

    // 1. Remove globals using anchored multiline regexes to prevent partial matching of inputs
    if (file.includes("CLIENT_REAL.mq5")) {
        // CLIENT_REAL needs both globals removed and inputs added.
        content = content.replace(/^double\s+MultiplicadorRefuerzo\s*=\s*3\.0;[^\r\n]*/m, '');
        content = content.replace(/^double\s+ProfitNetoFlush\s*=\s*5\.0;[^\r\n]*/m, '');
        content = content.replace(/^double\s+DistanciaRefuerzoPips\s*=\s*30\.0;[^\r\n]*/m, '');
        content = content.replace(/^double\s+ProfitBreakEven\s*=\s*0\.50;[^\r\n]*/m, '');

        // Add inputs under Configuración Operativa y Lotes (generic match)
        content = content.replace(
            /(input double\s+LoteAtaque\s*=\s*\d+(?:\.\d+)?;\s*\/\/[^\r\n]*)/,
            `$1\r\ninput double   MultiplicadorRefuerzo      = 3.0;         // ✖️ Multiplicador Lote de Rescate (SOS)\r\ninput double   DistanciaRefuerzoPips      = 30.0;        // 📏 Distancia Mínima para Abrir SOS (Pips)`
        );

        // Add inputs under Cobrar Beneficios (generic match for TargetDiario)
        content = content.replace(
            /(input double\s+TargetDiario\s*=\s*\d+(?:\.\d+)?;\s*\/\/[^\r\n]*)/,
            `$1\r\ninput double   ProfitNetoFlush            = 5.0;         // 💵 Beneficio Cierre Total Cesta ($)\r\ninput double   ProfitBreakEven            = 0.50;        // 🛡️ Beneficio Mínimo Break Even Cesta ($)`
        );
        console.log("- Converted globals to inputs in REAL bot successfully");
    } 
    else if (file.includes("CLIENT_TRIAL.mq5")) {
        // CLIENT_TRIAL has inputs already, so we ONLY remove the duplicate globals at the top
        content = content.replace(/^double\s+MultiplicadorRefuerzo\s*=\s*3\.0;[^\r\n]*/m, '');
        content = content.replace(/^double\s+ProfitNetoFlush\s*=\s*5\.0;[^\r\n]*/m, '');
        content = content.replace(/^double\s+DistanciaRefuerzoPips\s*=\s*30\.0;[^\r\n]*/m, '');
        content = content.replace(/^double\s+ProfitBreakEven\s*=\s*0\.50;[^\r\n]*/m, '');
        console.log("- Removed duplicate globals in TRIAL bot successfully");
    }
    else if (file.includes("NORMAL_HISTORICO_CENT.mq5")) {
        // CENT bot only has MultiplicadorRefuerzo as global. The other three are already inputs.
        content = content.replace(/^double\s+MultiplicadorRefuerzo\s*=\s*3\.0;[^\r\n]*/m, '');

        // Add MultiplicadorRefuerzo input under MaxLoteIndividual
        content = content.replace(
            /(input double\s+MaxLoteIndividual\s*=\s*\d+(?:\.\d+)?;\s*\/\/[^\r\n]*)/,
            `$1\r\ninput double   MultiplicadorRefuerzo      = 3.0;         // ✖️ Multiplicador Lote de Rescate (SOS)`
        );
        console.log("- Converted MultiplicadorRefuerzo to input in CENT bot successfully");
    }

    // 2. Replace S/R and mecha inputs (with new breakout confirmation)
    content = content.replace(/\/\/ --- FILTRO DE TECHOS Y SUELOS \(SOPORTES Y RESISTENCIAS\) ---[\s\S]*?MinPorcentajeMechaM15\s*=\s*40\.0;[^\r\n]*/, newSRInputs);

    // 3. Replace ValidarTechosSuelos function body
    content = content.replace(/bool\s+ValidarTechosSuelos\(string\s+decision\)\s*\{[\s\S]*?return\s+true;\s*\}/, newFunction);

    // 4. Replace the else block of ActualizarTextosEstado()
    const elsePattern = /\} else \{\s*if\(!enFaseAnalisis\)\s*\{\s*txtVoz\s*=\s*\"SCHOLAR:\s*Buscando\.\.\.\";\s*txtVeredicto\s*=\s*\"ESPERANDO\.\.\.\";\s*\}\s*\}/;
    if (elsePattern.test(content)) {
        content = content.replace(elsePattern, newHudCheck);
        console.log("- Replaced ActualizarTextosEstado HUD block successfully");
    } else {
        console.log("- Attempting exact text replacement for else block...");
        const exactElseText = `    } else {
        if(!enFaseAnalisis) {
            txtVoz = "SCHOLAR: Buscando...";
            txtVeredicto = "ESPERANDO...";
        }
    }`;
        content = content.replace(exactElseText, newHudCheck);
    }

    fs.writeFileSync(file, content, 'utf8');
    console.log("Successfully modified:", file);
});
