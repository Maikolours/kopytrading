import os, glob

mq5_files = glob.glob(r"c:\proyectos\APP KOPYTRADING\**\*.mq5", recursive=True)

print("Found mq5 files:", len(mq5_files))

for path in mq5_files:
    if "MAIKO" in path:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            if "hRSI" in content or "rsiActualVal" in content:
                print("Checking:", path)
                lines = content.splitlines()
                for i, l in enumerate(lines, 1):
                    if "hRSI" in l or "rsiActualVal" in l or "iRSI" in l:
                        print(f"  L{i:04d}: {l.strip()}")
        except Exception as e:
            pass
