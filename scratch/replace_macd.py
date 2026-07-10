import io

file_path = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\BB8163656548A371304D87AABB7A68EB\\MQL5\\Experts\\BOTS MAIKO\\Elite_Gold_MAIKO_Sniper_v11.30_MACD_TEST.mq5"

with io.open(file_path, "r", encoding="utf-8") as f:
    c = f.read()

# 1. Input MACD
target1 = "input double   MinRsiVenta                = 30.0;        // 📉 RSI Mínimo para Ventas (Filtro Suelos)"
replace1 = "input double   MinRsiVenta                = 30.0;        // 📉 RSI Mínimo para Ventas (Filtro Suelos)\ninput bool     UsarFiltroMACD             = true;        // 🚥 Usar Filtro de Momentum (MACD)"
c = c.replace(target1, replace1)

# 2. MagicNumber
target2 = "const int ExpertMagic = 111222;"
replace2 = "const int ExpertMagic = 111333;"
c = c.replace(target2, replace2)

# 3. HUD Branding
target3 = 'HUD_Branding               = "MAIKO v11.30 | NORMAL HISTORICO";'
replace3 = 'HUD_Branding               = "MAIKO v11.30 | MACD TEST";'
c = c.replace(target3, replace3)

# 4. Trade Comment
target_comment = 'input string   TradeComment               = "MAIKO_NORMAL_HIST";'
replace_comment = 'input string   TradeComment               = "MAIKO_MACD_TEST";'
c = c.replace(target_comment, replace_comment)

# 5. Global Handle
target4 = "int hRSI_v = INVALID_HANDLE;"
replace4 = "int hRSI_v = INVALID_HANDLE;\nint hMACD_v = INVALID_HANDLE;"
c = c.replace(target4, replace4)

# 6. Initialization
target5 = "    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);"
replace5 = "    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);\n    hMACD_v = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);"
c = c.replace(target5, replace5)

# 7. Release
target6 = "    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);"
replace6 = "    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);\n    if(hMACD_v != INVALID_HANDLE) IndicatorRelease(hMACD_v);"
c = c.replace(target6, replace6)

# 8. MACD logic
target7 = """        txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], rsiReason);
        return false;
    }"""
replace7 = """        txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], rsiReason);
        return false;
    }

    if(UsarFiltroMACD) {
        double macdLine[1], signalLine[1];
        if(CopyBuffer(hMACD_v, 0, 1, 1, macdLine) <= 0 || CopyBuffer(hMACD_v, 1, 1, 1, signalLine) <= 0) {
            txtVeredicto = "ESPERANDO HISTORIAL MACD...";
            return false;
        }
        double histogram = macdLine[0] - signalLine[0];
        bool macdOK = (porEncima ? (histogram > 0) : (histogram < 0));
        if(!macdOK) {
            txtVeredicto = StringFormat("P:%.2f EMA:%.2f HIST:%.3f | MOMENTUM CONTRA", precio, ema[0], histogram);
            return false;
        }
    }"""

# handle windows crlf
target7_crlf = target7.replace('\n', '\r\n')
replace7_crlf = replace7.replace('\n', '\r\n')

if target7 in c:
    c = c.replace(target7, replace7)
    print("Replaced 8 (LF)")
elif target7_crlf in c:
    c = c.replace(target7_crlf, replace7_crlf)
    print("Replaced 8 (CRLF)")
else:
    print("WARNING: MACD logic target NOT FOUND")

with io.open(file_path, "w", encoding="utf-8") as f:
    f.write(c)

print("Replacement complete")
