import os

file_path = r"c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_OCTUBRE\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5"

with open(file_path, "r", encoding="utf-16le", errors="ignore") as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
for idx, line in enumerate(lines, 1):
    if "RSI" in line or "rsi" in line or "CopyBuffer" in line or "iRSI" in line or "Indicator" in line:
        print(f"Line {idx}: {line.strip()}")
