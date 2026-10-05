import os

file_path = r"c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_OCTUBRE\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5"

with open(file_path, "rb") as f:
    raw = f.read()

print("File byte len:", len(raw))
print("First 100 bytes:", raw[:100])

# Try decoding utf-16 (autodetects BOM) or utf-8
for enc in ["utf-16", "utf-8", "latin-1", "cp1252"]:
    try:
        text = raw.decode(enc)
        lines = text.splitlines()
        print(f"Encoding '{enc}' decoded successfully! Total lines: {len(lines)}")
    except Exception as e:
        print(f"Encoding '{enc}' failed: {e}")
