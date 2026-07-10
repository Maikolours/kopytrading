import os

files = [
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5',
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5',
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5',
    'private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5'
]

for f in files:
    path = os.path.join('c:/proyectos/APP KOPYTRADING', f)
    if not os.path.exists(path):
        print(f"File not found: {path}")
        continue
        
    with open(path, 'rb') as file:
        content = file.read()
        
    has_bom = content.startswith(b'\xef\xbb\xbf')
    print(f'{f} has BOM: {has_bom}')
    
    if not has_bom:
        # First, try to decode as UTF-8 to make sure it's valid UTF-8
        try:
            content.decode('utf-8')
            # It's valid UTF-8. Add BOM.
            with open(path, 'wb') as outfile:
                outfile.write(b'\xef\xbb\xbf' + content)
            print(f'Added BOM to {f}')
        except UnicodeDecodeError:
            # Maybe it's already ANSI/Windows-1252? We should decode it from cp1252 and encode to utf-8 with BOM?
            # Wait, if the emojis display as `ðŸš€` in MetaEditor, it means the bytes are literally UTF-8 (F0 9F 9A 80).
            # So `content.decode('utf-8')` will succeed.
            print(f"Could not decode {f} as UTF-8.")
