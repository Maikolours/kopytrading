file_path = r"c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_OCTUBRE\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5"

with open(file_path, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
keywords = ["rsi", "hRSI", "CopyBuffer", "iRSI", "Indicator", "Calibrar", "Sincronizar", "Asegurar"]

for idx, line in enumerate(lines, 1):
    line_lower = line.lower()
    if any(k.lower() in line_lower for k in keywords):
        print(f"L{idx:04d}: {line.strip()}")
