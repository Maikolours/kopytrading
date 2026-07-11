import codecs
import glob
import os

base_path = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\*\MQL5\Experts\BOTS MAIKO\*.mq5'
files = glob.glob(base_path)

for f in files:
    with codecs.open(f, 'r', encoding='utf-16le') as file:
        content = file.read()
    
    new_content = content.replace('v11.31', 'v11.32')
    new_content = new_content.replace('"11.31"', '"11.32"')
    
    if new_content != content:
        print(f"Bumping version in {f}")
        with open(f, 'wb') as file:
            file.write(codecs.BOM_UTF16_LE)
            # Remove any existing BOM in the string itself just in case
            clean_content = new_content.lstrip('\ufeff')
            file.write(clean_content.encode('utf-16le'))
