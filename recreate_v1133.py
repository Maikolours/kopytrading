import shutil
import re

file_v1132 = r'C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO.mq5'
file_v1133 = r'C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5'

with open(file_v1132, 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('MAIKO_PRO_GOLD_DEMO | V.11.32', 'MAIKO PRO GOLD DEMO | V.11.33')

bb_inputs = """
// --- FILTRO DE AGOTAMIENTO (BANDS) ---
input group "================= FILTRO BANDS ================="
input bool     UsarFiltroBollinger        = true;        // Activar Bloqueo por Bandas de Bollinger
input int      BollingerPeriod            = 20;          // Periodo Bandas
input double   BollingerDev               = 2.0;         // Desviacion Bandas
"""

hud_idx = code.find('// --- INTERFAZ GRAFICA (HUD) ---')
code = code[:hud_idx] + bb_inputs + '\n' + code[hud_idx:]

global_vars = """
int hBands_v = INVALID_HANDLE;
"""
oninit_idx = code.find('int OnInit() {')
code = code[:oninit_idx] + global_vars + '\n' + code[oninit_idx:]

init_bb = """
    if(UsarFiltroBollinger) {
        hBands_v = iBands(_Symbol, _Period, BollingerPeriod, 0, BollingerDev, PRICE_CLOSE);
        if(hBands_v != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hBands_v);
    }
"""
ema_init = code.find('hEMA_v = iMA(')
if ema_init != -1:
    ema_init_end = code.find(';', ema_init) + 1
    code = code[:ema_init_end] + init_bb + code[ema_init_end:]

release_bb = """
    if(hBands_v != INVALID_HANDLE) IndicatorRelease(hBands_v);
"""
deinit_idx = code.find('if(hEMA_v != INVALID_HANDLE)')
code = code[:deinit_idx] + release_bb + '\n    ' + code[deinit_idx:]

bb_logic = """
    // ADD BOLLINGER BANDS EXHAUSTION FILTER
    if(UsarFiltroBollinger && hBands_v != INVALID_HANDLE) {
        double bb_upper[1], bb_lower[1];
        if(CopyBuffer(hBands_v, 1, 0, 1, bb_upper) > 0 && CopyBuffer(hBands_v, 2, 0, 1, bb_lower) > 0) {
            double current_close = iClose(_Symbol, PERIOD_M1, 0); 
            if(decision == "SELL" && current_close <= bb_lower[0] + (3.0 * _Point * 10)) {
                txtVeredicto = "AGOTAMIENTO BB INFERIOR"; return false;
            }
            if(decision == "BUY" && current_close >= bb_upper[0] - (3.0 * _Point * 10)) {
                txtVeredicto = "AGOTAMIENTO BB SUPERIOR"; return false;
            }
        }
    }
"""

decision_idx = code.find('if(!ValidarTechosSuelos(decision)) return false;')
code = code[:decision_idx] + bb_logic + '\n    ' + code[decision_idx:]

with open(file_v1133, 'w', encoding='utf-8') as f:
    f.write(code)

print('V11.33 Recreated Successfully!')
