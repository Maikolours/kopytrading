import os
import glob
import shutil

active_bots = [
    "MAIKO_PRO_GOLD",
    "MAIKO_PRO_GOLD_DEMO",
    "MAIKO_PRO_GOLD_MASTER",
    "MAIKO_PRO_CENT",
    "MAIKO_PRO_CENT_DEMO",
    "MAIKO_PRO_CENT_MASTER"
]

terminals_path = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\*'
terminal_dirs = glob.glob(terminals_path)

for t in terminal_dirs:
    bots_dir = os.path.join(t, 'MQL5', 'Experts', 'BOTS MAIKO')
    if not os.path.exists(bots_dir):
        continue
        
    activos_dir = os.path.join(bots_dir, '✅ BOTS ACTIVOS')
    inactivos_dir = os.path.join(bots_dir, '_Otros_Bots_No_Activos')
    
    os.makedirs(activos_dir, exist_ok=True)
    os.makedirs(inactivos_dir, exist_ok=True)
    
    # 1. Pull active bots from anywhere (root or inactivos) into activos
    all_files_in_bots = glob.glob(os.path.join(bots_dir, '**', '*.*'), recursive=True)
    for f in all_files_in_bots:
        if not os.path.isfile(f): continue
        if not (f.endswith('.mq5') or f.endswith('.ex5')): continue
        
        basename = os.path.basename(f)
        name_without_ext = os.path.splitext(basename)[0]
        
        # Determine destination
        if name_without_ext in active_bots:
            dest = os.path.join(activos_dir, basename)
        else:
            # If it's already in inactivos or deeper, leave it unless it's in root
            if os.path.dirname(f) == bots_dir:
                dest = os.path.join(inactivos_dir, basename)
            else:
                continue
                
        if f != dest:
            print(f"Moving {basename} to {os.path.basename(os.path.dirname(dest))}")
            try:
                shutil.move(f, dest)
            except Exception as e:
                print(f"Failed to move {f}: {e}")

print("Reorganization complete.")
