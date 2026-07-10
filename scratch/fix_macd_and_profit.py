import io
file_path = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\BB8163656548A371304D87AABB7A68EB\\MQL5\\Experts\\BOTS MAIKO\\Elite_Gold_MAIKO_Sniper_v11.30_MACD_TEST.mq5"

with io.open(file_path, "r", encoding="utf-8") as f:
    c = f.read()

# Fix CalcularGanadoHoy
target_ganado = "        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) {"
replace_ganado = "        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == ExpertMagic) {"
if target_ganado in c:
    c = c.replace(target_ganado, replace_ganado)
    print("Fixed CalcularGanadoHoy")
else:
    print("CalcularGanadoHoy NOT FOUND")

# Fix MACD logic (Absolute Value instead of Histogram)
target_macd = "double histogram = macdLine[0] - signalLine[0];\n        bool macdOK = (porEncima ? (histogram > 0) : (histogram < 0));\n        if(!macdOK) {\n            txtVeredicto = StringFormat(\"P:%.2f EMA:%.2f HIST:%.3f | MOMENTUM CONTRA\", precio, ema[0], histogram);"

replace_macd = "double macdVal = macdLine[0];\n        bool macdOK = (porEncima ? (macdVal > 0) : (macdVal < 0));\n        if(!macdOK) {\n            txtVeredicto = StringFormat(\"P:%.2f EMA:%.2f MACD:%.3f | MACD CONTRA TENDENCIA\", precio, ema[0], macdVal);"

target_macd_crlf = target_macd.replace('\n', '\r\n')
replace_macd_crlf = replace_macd.replace('\n', '\r\n')

if target_macd in c:
    c = c.replace(target_macd, replace_macd)
    print("Fixed MACD Logic (LF)")
elif target_macd_crlf in c:
    c = c.replace(target_macd_crlf, replace_macd_crlf)
    print("Fixed MACD Logic (CRLF)")
else:
    print("MACD Logic NOT FOUND")

with io.open(file_path, "w", encoding="utf-8") as f:
    f.write(c)

print("Done")
