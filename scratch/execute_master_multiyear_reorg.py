import os, sys, glob, re, shutil, subprocess

repo_root = r'c:\proyectos\APP KOPYTRADING'
target_master = r'c:\proyectos\APP KOPYTRADING\BOTS_MAIKO'
temp_stage = r'c:\proyectos\APP KOPYTRADING\scratch\stage_bots'

MONTH_MAP = {
    '01': '01_Enero', '02': '02_Febrero', '03': '03_Marzo', '04': '04_Abril',
    '05': '05_Mayo', '06': '06_Junio', '07': '07_Julio', '08': '08_Agosto',
    '09': '09_Septiembre', '10': '10_Octubre', '11': '11_Noviembre', '12': '12_Diciembre'
}

sources = [
    r'c:\proyectos\APP KOPYTRADING\public\uploads',
    r'c:\proyectos\APP KOPYTRADING\HISTORIAL_BOTS_MAIKO',
    r'c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos',
    r'C:\Users\Usuario\Downloads',
]

terminals_dir = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal'
term_hashes = [d for d in os.listdir(terminals_dir) if len(d) == 32 and os.path.isdir(os.path.join(terminals_dir, d))]
for th in term_hashes:
    exp_dir = os.path.join(terminals_dir, th, 'MQL5', 'Experts')
    if os.path.exists(exp_dir):
        sources.append(exp_dir)

def get_file_ym(fname, fpath):
    fn_lower = fname.lower()
    fp_lower = fpath.lower()
    
    if 'martingala_segura_v5' in fn_lower:
        return '2024_10_Octubre_2024'
    if 'legacy' in fp_lower or 'scalping' in fp_lower:
        return '2025_05_Mayo_2025'
    if re.search(r'v5[_\.]\d', fn_lower) or re.search(r'v5\d', fn_lower):
        return '2025_11_Noviembre_2025'
    
    if fname.endswith('.mq5') and os.path.exists(fpath):
        try:
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                head = f.read(3000)
            if '2024' in head:
                return '2024_10_Octubre_2024'
            if '2025' in head:
                return '2025_11_Noviembre_2025'
            m_date = re.search(r'2026[\.\/-](0[1-9]|1[0-2])', head)
            if m_date:
                m_str = m_date.group(1)
                return f'2026_{MONTH_MAP[m_str]}_2026'
        except:
            pass

    if 'septiembre' in fp_lower or 'sept' in fp_lower or 'v41' in fn_lower or 'v42' in fn_lower or 'warrior' in fn_lower:
        return '2026_09_Septiembre_2026'
    if 'agosto' in fp_lower or 'aug' in fp_lower or 'v11.34' in fn_lower:
        return '2026_08_Agosto_2026'
    if 'julio' in fp_lower or 'jul' in fp_lower or 'v11.33' in fn_lower:
        return '2026_07_Julio_2026'
    if 'junio' in fp_lower or 'jun' in fp_lower or 'v11.32' in fn_lower:
        return '2026_06_Junio_2026'
    if 'mayo' in fp_lower or 'v11.30' in fn_lower:
        return '2026_05_Mayo_2026'
    if 'abril' in fp_lower:
        return '2026_04_Abril_2026'
    if 'marzo' in fp_lower or 'v11.2' in fn_lower:
        return '2026_03_Marzo_2026'
    if 'enero' in fp_lower or 'v11.1' in fn_lower:
        return '2026_01_Enero_2026'

    return '2026_06_Junio_2026'

# Collect all files into temp stage first
if os.path.exists(temp_stage):
    shutil.rmtree(temp_stage)
os.makedirs(temp_stage, exist_ok=True)

unique_bots = {}
for s in sources:
    if not os.path.exists(s):
        continue
    for root, dirs, files in os.walk(s):
        if 'Examples' in root or 'Advisors' in root or 'stage_bots' in root:
            continue
        for f in files:
            if f.endswith('.mq5') or f.endswith('.ex5'):
                if f.startswith('Expert') or f in ['Controls.ex5', 'ChartInChart.ex5']:
                    continue
                fp = os.path.join(root, f)
                target_folder = get_file_ym(f, fp)
                if f not in unique_bots:
                    unique_bots[f] = (target_folder, fp)
                else:
                    cur_folder, cur_fp = unique_bots[f]
                    if fp.endswith('.mq5') and not cur_fp.endswith('.mq5'):
                        unique_bots[f] = (target_folder, fp)

print(f"Staging {len(unique_bots)} unique files into temp folder...")
for fname, (folder, src_path) in unique_bots.items():
    if not os.path.exists(src_path):
        continue
    fdir = os.path.join(temp_stage, folder)
    os.makedirs(fdir, exist_ok=True)
    shutil.copy2(src_path, os.path.join(fdir, fname))

# Replace BOTS_MAIKO with staged folder
print("Deploying staged structure to master:", target_master)
if os.path.exists(target_master):
    shutil.rmtree(target_master)
shutil.copytree(temp_stage, target_master)
shutil.rmtree(temp_stage)

# Purge obsolete folders from all MT5 Terminals and sync BOTS MAIKO
obsolete_folders = [
    '_Archive', '_Otros Bots no activos', 'Agosto_2026_Activos',
    'BOTS ACTIVOS', 'Free Robots', 'Antiguos', '03_AGOSTO_2026',
    '00_OFICIALES_SEPTIEMBRE', 'LEGACY', 'SCALPING', '2026_04_Abril',
    '2026_05_Mayo', '2026_06_Junio', '2026_07_Julio', '2025_11_Noviembre'
]

print("Syncing to MT5 Terminals...")
for th in term_hashes:
    experts_dir = os.path.join(terminals_dir, th, 'MQL5', 'Experts')
    if not os.path.exists(experts_dir):
        continue
    
    for obs in obsolete_folders:
        obs_path = os.path.join(experts_dir, obs)
        if os.path.exists(obs_path):
            shutil.rmtree(obs_path, ignore_errors=True)
            
    target_term_bots = os.path.join(experts_dir, 'BOTS MAIKO')
    if os.path.exists(target_term_bots):
        shutil.rmtree(target_term_bots, ignore_errors=True)
        
    shutil.copytree(target_master, target_term_bots)
    print(f"Synced unified multi-year BOTS MAIKO to terminal {th[:8]}")

print("Unified reorganization completed successfully!")
