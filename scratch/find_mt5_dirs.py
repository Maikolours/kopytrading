import os, glob, shutil

terminals_dir = r"C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal"

print("Scanning terminal dirs...")
for item in os.listdir(terminals_dir):
    full = os.path.join(terminals_dir, item)
    if os.path.isdir(full):
        experts_dir = os.path.join(full, "MQL5", "Experts")
        if os.path.exists(experts_dir):
            print("Found MT5 Experts dir:", experts_dir)
            # Check for 2026_10_Octubre_2026
            oct_dir = os.path.join(experts_dir, "BOTS MAIKO", "2026_10_Octubre_2026")
            if not os.path.exists(oct_dir):
                oct_dir = os.path.join(experts_dir, "2026_10_Octubre_2026")
            print("  Octubre dir exists?", os.path.exists(oct_dir))
            if os.path.exists(oct_dir):
                print("  Files in Octubre dir:", os.listdir(oct_dir))
