file_path = r"c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_OCTUBRE\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5"

with open(file_path, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

for idx, line in enumerate(lines, 1):
    if "rsiActualVal" in line or "BAYES_LBL_RSI" in line:
        print(f"L{idx:04d}: {line.strip().encode('ascii', 'replace').decode('ascii')}")
