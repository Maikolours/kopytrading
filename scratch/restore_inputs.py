import os

def read_file(path):
    with open(path, 'rb') as f:
        c = f.read()
    if c.startswith(b'\xff\xfe'):
        return c.decode('utf-16le')
    elif c.startswith(b'\xef\xbb\xbf'):
        return c[3:].decode('utf-8')
    return c.decode('utf-8')

def write_file(path, content):
    with open(path, 'wb') as f:
        f.write(b'\xff\xfe' + content.encode('utf-16le'))

path_hist = 'c:/proyectos/APP KOPYTRADING/private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5'
text_hist = read_file(path_hist)
start_hist = text_hist.find('input group "')
end_hist = text_hist.find('// Globales')
if start_hist != -1 and end_hist != -1:
    hist_inputs = text_hist[start_hist:end_hist]
    
    # For TRIAL
    path_trial = 'c:/proyectos/APP KOPYTRADING/private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5'
    text_trial = read_file(path_trial)
    start_t = text_trial.find('input group "')
    end_t = text_trial.find('// Globales')
    
    # Inject DiasDeTrial
    hist_inputs_trial = hist_inputs.replace(
        'input string   MiLicencia                 = "";          // 🔑 Clave de Licencia o Correo Usuario\n',
        'input string   MiLicencia                 = "";          // 🔑 Clave de Licencia o Correo Usuario\ninput int      DiasDeTrial                = 30;          // ⏳ Días de Prueba (Solo Trial)\n'
    )
    
    if start_t != -1 and end_t != -1:
        new_text_trial = text_trial[:start_t] + hist_inputs_trial + text_trial[end_t:]
        write_file(path_trial, new_text_trial)
        print("TRIAL updated")
        
    # For REAL
    path_real = 'c:/proyectos/APP KOPYTRADING/private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5'
    text_real = read_file(path_real)
    start_r = text_real.find('input group "')
    end_r = text_real.find('// Globales')
    
    if start_r != -1 and end_r != -1:
        new_text_real = text_real[:start_r] + hist_inputs + text_real[end_r:]
        write_file(path_real, new_text_real)
        print("REAL updated")
        
    # For HISTORICO CENT
    path_cent = 'c:/proyectos/APP KOPYTRADING/private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5'
    text_cent = read_file(path_cent)
    start_c = text_cent.find('input group "')
    end_c = text_cent.find('// Globales')
    if start_c != -1 and end_c != -1:
        new_text_cent = text_cent[:start_c] + hist_inputs + text_cent[end_c:]
        write_file(path_cent, new_text_cent)
        print("CENT updated")
        
