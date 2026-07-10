import io

file_path = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\BB8163656548A371304D87AABB7A68EB\\MQL5\\Experts\\BOTS MAIKO\\Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5"

with io.open(file_path, "r", encoding="utf-16") as f:
    content = f.read()

target = """// --- FILTROS ---
double MaxRangoVelaM1 = 20.0;
double MaxSpreadPips = 4.0;
double SensibilidadMechaReal = 3.0;
int MinutosPausaTrasSusto = 1;
input double   MaxRsiCompra               = 70.0;        // 📈 RSI Máximo para Compras (Filtro Techos)
input double   MinRsiVenta                = 30.0;        // 📉 RSI Mínimo para Ventas (Filtro Suelos)"""

replacement = """// --- FILTROS DE RUIDO Y MERCADO ---
input group "━━━━━━ 🛡️ 𝗙 𝗜 𝗟 𝗧 𝗥 𝗢 𝗦   𝗗 𝗘   𝗥 𝗨 𝗜 𝗗 𝗢   𝗬   𝗠 𝗘 𝗥 𝗖 𝗔 𝗗 𝗢 ━━━━━━"
input double   MaxRangoVelaM1             = 20.0;        // ⚡ Rango Máximo Vela M1 (Pips)
input double   MaxSpreadPips              = 4.0;         // 📊 Spread Máximo Permitido (Pips)
input double   SensibilidadMechaReal      = 3.0;         // ⚖️ Sensibilidad Rechazo de Mechas
input int      MinutosPausaTrasSusto      = 1;           // ⏱️ Minutos Pausa tras Vela Extrema
input double   MaxRsiCompra               = 70.0;        // 📈 RSI Máximo para Compras (Filtro Techos)
input double   MinRsiVenta                = 30.0;        // 📉 RSI Mínimo para Ventas (Filtro Suelos)"""

if target in content:
    content = content.replace(target, replacement)
    with io.open(file_path, "w", encoding="utf-16") as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Target not found. Doing fuzzy search...")
    # Just in case line endings are different
    target_lines = target.split('\n')
    found_idx = content.find("// --- FILTROS ---")
    if found_idx != -1:
        end_idx = content.find("// --- TENDENCIA Y LOTAJE ---")
        if end_idx != -1:
            content = content[:found_idx] + replacement + "\n\n" + content[end_idx:]
            with io.open(file_path, "w", encoding="utf-16") as f:
                f.write(content)
            print("Replaced with fuzzy search successfully")
        else:
            print("End marker not found")
    else:
        print("Start marker not found")
