import io

file_path = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\BB8163656548A371304D87AABB7A68EB\\MQL5\\Experts\\BOTS MAIKO\\Elite_Gold_MAIKO_Sniper_v11.30_MACD_TEST.mq5"

with io.open(file_path, "r", encoding="utf-8") as f:
    c = f.read()

target = 'txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], rsiReason);\n\n        return false;\n\n    }'
replace = '''txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], rsiReason);\n\n        return false;\n\n    }\n\n    if(UsarFiltroMACD) {\n        double macdLine[1], signalLine[1];\n        if(CopyBuffer(hMACD_v, 0, 1, 1, macdLine) <= 0 || CopyBuffer(hMACD_v, 1, 1, 1, signalLine) <= 0) {\n            txtVeredicto = "ESPERANDO HISTORIAL MACD...";\n            return false;\n        }\n        double histogram = macdLine[0] - signalLine[0];\n        bool macdOK = (porEncima ? (histogram > 0) : (histogram < 0));\n        if(!macdOK) {\n            txtVeredicto = StringFormat("P:%.2f EMA:%.2f HIST:%.3f | MOMENTUM CONTRA", precio, ema[0], histogram);\n            return false;\n        }\n    }'''

if target in c:
    c = c.replace(target, replace)
    print("Replaced successfully!")
else:
    print("Target still not found!")

with io.open(file_path, "w", encoding="utf-8") as f:
    f.write(c)

