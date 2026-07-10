import os

files = [
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5',
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5',
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5',
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5'
]

for f in files:
    path = os.path.join('c:/proyectos/APP KOPYTRADING', f)
    with open(path, 'rb') as file:
        content = file.read()
        
    # Remove UTF-8 BOM if present
    if content.startswith(b'\xef\xbb\xbf'):
        content = content[3:]
        
    # Decode as UTF-8
    text = content.decode('utf-8')
    
    # Save as UTF-16 LE with BOM
    with open(path, 'wb') as file:
        file.write(text.encode('utf-16le'))
        
    print(f'Converted {f} to UTF-16 LE')
