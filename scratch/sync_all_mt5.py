import os, shutil

source_ex5 = r"c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.ex5"
source_mq5 = r"c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5"

terminals_dir = r"C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal"

count = 0
for root, dirs, files in os.walk(terminals_dir):
    if root.endswith("2026_10_Octubre_2026"):
        target_ex5 = os.path.join(root, "00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.ex5")
        target_mq5 = os.path.join(root, "00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5")
        shutil.copy2(source_ex5, target_ex5)
        shutil.copy2(source_mq5, target_mq5)
        print("Updated v2.3 in MT5 directory:", root)
        count += 1

print(f"Done! Successfully synced v2.3 to {count} MT5 terminal folders.")
