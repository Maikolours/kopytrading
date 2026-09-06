import re

file_path = r'C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

with open(r'C:\proyectos\APP KOPYTRADING\techos_suelos.txt', 'r', encoding='utf-8') as f:
    ts_logic = f.read()

start_ts = code.find('bool ValidarTechosSuelos')
end_ts = code.find('bool EvaluarTurbulenciaM5')

if start_ts != -1 and end_ts != -1:
    code = code[:start_ts] + ts_logic + '\n\n' + code[end_ts:]

bb_logic = """
    // BOLLINGER BANDS EXHAUSTION FILTER
    if(hBands_v != INVALID_HANDLE) {
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

insertion_point = code.find('if(!ValidarTechosSuelos(decision)) return false;')
if insertion_point != -1:
    code = code[:insertion_point] + bb_logic + '    ' + code[insertion_point:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched!")
