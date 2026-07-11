import shutil
import os

src_dir = 'c:/proyectos/APP KOPYTRADING/private_bots_backup/'
dest_dir = 'C:/Users/Usuario/AppData/Roaming/MetaQuotes/Terminal/F762D69EEEA9B4430D7F17C82167C844/MQL5/Experts/BOTS MAIKO/'

files_to_copy = [
    ('Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5', 'MAIKO_PRO_GOLD_DEMO.mq5'),
    ('Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5', 'MAIKO_PRO_GOLD.mq5'),
    ('Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5', 'MAIKO_PRO_CENT_MASTER.mq5'),
    ('Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5', 'MAIKO_PRO_GOLD_MASTER.mq5'),
]

for src, dest in files_to_copy:
    src_path = os.path.join(src_dir, src)
    dest_path = os.path.join(dest_dir, dest)
    if os.path.exists(src_path):
        # Read the file
        with open(src_path, 'rb') as f:
            content = f.read()
            
        try:
            text = content.decode('utf-16le')
        except:
            text = content.decode('utf-8')
            
        # Strip any existing BOMs so we don't duplicate
        text = text.replace('\ufeff', '')
            
        # Change version to 11.31
        text = text.replace('"11.30"', '"11.31"')
        text = text.replace('v11.30', 'v11.31')
        
        # Write back as UTF-16 LE (which automatically adds BOM)
        with open(dest_path, 'wb') as f:
            f.write(text.encode('utf-16'))
            
        print(f'Copied and bumped to 11.31: {dest}')
