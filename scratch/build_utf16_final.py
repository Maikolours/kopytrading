import os
import re
import subprocess
import shutil

original_file = r"C:\proyectos\APP KOPYTRADING\scratch\MAIKO_PERFECT.mq5"

try:
    with open(original_file, 'r', encoding='utf-16') as f:
        code = f.read()
except UnicodeError:
    with open(original_file, 'r', encoding='utf-8') as f:
        code = f.read()

if code.startswith('\ufeff'):
    code = code[1:]

code = re.sub(r'#property version\s+"11\.32"', '#property version   "11.33"', code)
code = re.sub(r'HUD_Branding\s*=\s*"MAIKO PRO GOLD DEMO \| V\.11\.32";', 'HUD_Branding               = "MAIKO PRO GOLD DEMO | V.11.33";', code)

new_inputs = """input bool     OperarViernesNoche         = false;       // YO Permitir Operaciones Viernes Tarde (17:00+)
input int      MinutosPausaTrasTurbulencia= 60;          // Y>' Minutos Pausa tras Barrido / Turbulencia M5"""
code = re.sub(r'input bool\s+OperarViernesNoche\s*=\s*false;\s*//[^\n]+', new_inputs, code)

global_ind = """int hEMA_v = INVALID_HANDLE;
int hRSI_v = INVALID_HANDLE;
int hATR_v = INVALID_HANDLE;
int hBands_v = INVALID_HANDLE;"""
code = re.sub(r'int hEMA_v = INVALID_HANDLE;\s*int hRSI_v = INVALID_HANDLE;', global_ind, code)

new_visual = """void AgregarIndicadoresVisuales() {
    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneATR = false;
    bool tieneBands = false;

    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0) tieneRSI = true;
            if(StringFind(nombre, "ATR") >= 0) tieneATR = true;
            if(StringFind(nombre, "Bands") >= 0 || StringFind(nombre, "Bollinger") >= 0) tieneBands = true;
        }
    }

    if(!tieneEMA && hEMA_v != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hEMA_v);
    if(!tieneRSI && hRSI_v != INVALID_HANDLE) ChartIndicatorAdd(0, 1, hRSI_v); // Subventana 1 (asumiendo)
}
"""
code = re.sub(r'void AgregarIndicadoresVisuales\(\) \{.*?\}', new_visual, code, flags=re.DOTALL)

code = code.replace('"{\\"purchaseId\\":\\"%s\\",\\"account\\":\\"%s\\",\\"balance\\":%.2f,\\"equity\\":%.2f,\\"', r'"{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"')
code = code.replace('""pnl_today":%.2f,"status":"%s","symbol":"%s","narrative":"%s","', r'"\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\",\"')
code = code.replace('""armed":%s,"isReal":%s,"version":"11.32","positions":%s,"', r'"\"armed\":%s,\"isReal\":%s,\"version\":\"11.33\",\"positions\":%s,\"')
code = code.replace('""trialExpirado":%s,"diasRestantes":%d}"', r'"\"trialExpirado\":%s,\"diasRestantes\":%d}"')
code = code.replace('string headers = "Content-Type: application/json\r\n";', r'string headers = "Content-Type: application/json\r\n";')
code = code.replace('string headers = "Content-Type: application/json\n";', r'string headers = "Content-Type: application/json\r\n";')
code = code.replace('StringFind(response, ""cmd":"CLOSE_ALL"")', r'StringFind(response, "\"cmd\":\"CLOSE_ALL\"")')
code = code.replace('StringFind(response, ""armed":false")', r'StringFind(response, "\"armed\":false")')
code = code.replace('"{\\"ticket\\":\\"%I64u\\",\\"type\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"lots\\":%.2f,\\"openPrice\\":%.5f,\\"tp\\":%.5f,\\"sl\\":%.5f,\\"profit\\":%.2f}"', r'"{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}"')

code = code.replace('string gvName = "MAIKO_TRIAL_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));', 'string gvName = "MAIKO_TRIAL_V1133_FIX_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));')
code = code.replace('string gvName = "MAIKO_TRIAL_V1133_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));', 'string gvName = "MAIKO_TRIAL_V1133_FIX_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));')

m5_func = """bool EvaluarTurbulenciaM5() {
    double high5 = iHigh(_Symbol, PERIOD_M5, 1);
    double low5 = iLow(_Symbol, PERIOD_M5, 1);
    double mechaSup = high5 - MathMax(iOpen(_Symbol, PERIOD_M5, 1), iClose(_Symbol, PERIOD_M5, 1));
    double mechaInf = MathMin(iOpen(_Symbol, PERIOD_M5, 1), iClose(_Symbol, PERIOD_M5, 1)) - low5;
    double atr = iATR(_Symbol, PERIOD_M5, 14, 1);
    
    if(mechaSup > atr * 1.5 || mechaInf > atr * 1.5) {
        return true; 
    }
    return false;
}"""
if "bool EvaluarTurbulenciaM5" not in code:
    code = code.replace("void OnTick() {", m5_func + "\n\nvoid OnTick() {")

if "Turbulencia en M5 detectada" not in code:
    anti_turb = """    if(EvaluarTurbulenciaM5()) {
        narrative = "PAUSA: TURBULENCIA M5";
        return;
    }"""
    code = code.replace("    if(!CheckViernes()) return;", "    if(!CheckViernes()) return;\n" + anti_turb)

file1 = r"C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\MAIKO_PRO_GOLD_DEMO_V11.33.mq5"
file2 = r"C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5"

with open(file1, 'w', encoding='utf-16') as f:
    f.write(code)
with open(file2, 'w', encoding='utf-16') as f:
    f.write(code)

editor_path = r"C:\Program Files\MetaTrader 5\metaeditor64.exe"
if not os.path.exists(editor_path):
    editor_path = r"C:\Program Files\MetaTrader\metaeditor64.exe"

print("Compiling...")
subprocess.run([editor_path, f"/compile:{file1}", "/log"], check=False)
subprocess.run([editor_path, f"/compile:{file2}", "/log"], check=False)

ex5_source = r"C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.ex5"
base_path = r"C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal"

if os.path.exists(base_path):
    for folder in os.listdir(base_path):
        if folder in ['Common', 'Community', 'Help']: continue
        folder_path = os.path.join(base_path, folder)
        if not os.path.isdir(folder_path): continue
        d1 = os.path.join(folder_path, "MQL5", "Experts")
        d2 = os.path.join(d1, "Agosto_2026_Activos")
        d3 = os.path.join(d2, "00_OFICIALES_SEPTIEMBRE")
        
        for d in [d1, d2, d3]:
            if os.path.exists(d):
                if os.path.exists(ex5_source):
                    shutil.copy2(ex5_source, os.path.join(d, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5"))
                shutil.copy2(file1, os.path.join(d, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5"))
print("Done")
