import os

src_path = r'c:\proyectos\APP KOPYTRADING\public\uploads\bots\MAIKO_PRO_GOLD_DEMO_FIX_V11.37.mq5'
dst_path = r'c:\proyectos\APP KOPYTRADING\public\uploads\bots\MAIKO_PRO_GOLD_DEMO_FIX_V11.38.mq5'

with open(src_path, 'r', encoding='utf-8', errors='ignore') as f:
    c = f.read()

# 1. Update title, version, branding, comment, magic
c = c.replace('MAIKO PRO GOLD FIX V11.37', 'MAIKO PRO GOLD FIX V11.38')
c = c.replace('MAIKO_DEMO_FIX_V11.37', 'MAIKO_DEMO_FIX_V11.38')
c = c.replace('version   "11.37"', 'version   "11.38"')
c = c.replace('ExpertMagic = 111336;', 'ExpertMagic = 111338;')

# 2. Update Take Profit group to include UsarCosechaIndividualSOS
tp_old = """input group "=== COBRAR BENEFICIOS (TAKE PROFIT) ==="
input double   ProfitNetoFlush            = 5.0;         // ?? Beneficio Cierre Total Cesta ($)
input double   ProfitCosechaIndividual    = 0.75;        // ?? Beneficio Cierre SOS Individual ($)
input double   TargetDiario               = 100.0;       // ?? Meta de Beneficio Diario ($)"""

tp_new = """input group "=== COBRAR BENEFICIOS (TAKE PROFIT) ==="
input double   ProfitNetoFlush            = 5.0;         // ?? Beneficio Cierre Total Cesta ($)
input bool     UsarCosechaIndividualSOS   = false;       // ?? Cosecha SOS Individual (false = Rescate en Equipo / BreakEven)
input double   ProfitCosechaIndividual    = 0.75;        // ?? Beneficio Cierre SOS Individual ($ si activa)
input double   TargetDiario               = 100.0;       // ?? Meta de Beneficio Diario ($)"""

if tp_old not in c:
    # Try finding with any whitespace
    import re
    m = re.search(r'input group "=== COBRAR BENEFICIOS \(TAKE PROFIT\) ==="[\r\n]+input double\s+ProfitNetoFlush\s*=\s*5\.0;[^\r\n]*[\r\n]+input double\s+ProfitCosechaIndividual\s*=\s*0\.75;[^\r\n]*[\r\n]+input double\s+TargetDiario\s*=\s*100\.0;', c)
    if m:
        c = c[:m.start()] + tp_new + c[m.end():]
    else:
        print("Warning: tp_old regex failed")
else:
    c = c.replace(tp_old, tp_new)

# 3. Update Horarios Operativos
hours_old = """input group "=== HORARIOS OPERATIVOS Y DIAS ==="
input int      HoraInicioOperativa        = 1;           // ? Hora de Inicio Operaciones Diaria (Broker)
input int      HoraFinOperativa           = 23;          // ? Hora de Cierre Operaciones Diaria (Broker)"""

hours_new = """input group "=== HORARIOS OPERATIVOS Y DIAS ==="
input int      HoraInicioOperativa        = 8;           // ? Hora de Inicio Operaciones Diaria (08:00 Europa, sin madrugada toxica)
input int      HoraFinOperativa           = 18;          // ? Hora de Cierre Operaciones Diaria (18:00 Cierre Sesion Europea)"""

if hours_old not in c:
    import re
    m = re.search(r'input group "=== HORARIOS OPERATIVOS Y DIAS ==="[\r\n]+input int\s+HoraInicioOperativa\s*=\s*1;[^\r\n]*[\r\n]+input int\s+HoraFinOperativa\s*=\s*23;', c)
    if m:
        c = c[:m.start()] + hours_new + c[m.end():]
    else:
        print("Warning: hours_old regex failed")
else:
    c = c.replace(hours_old, hours_new)

# 4. Update Bloqueo Horario Genérico Noticias default to true
bloq_new = """input bool     UsarHorarioBloqueo         = true;        // ?? Bloqueo Horario Generico Diario (Noticias Wall Street 14:00-16:00)
input int      HoraInicioBloqueo          = 14;          // ? Hora Inicio Bloqueo Generico (14:00)
input int      HoraFinBloqueo             = 16;          // ? Hora Fin Bloqueo Generico (16:00)"""

import re
c = re.sub(r'input bool\s+UsarHorarioBloqueo\s*=\s*false;[^\r\n]*[\r\n]+input int\s+HoraInicioBloqueo\s*=\s*14;[^\r\n]*[\r\n]+input int\s+HoraFinBloqueo\s*=\s*16;[^\r\n]*', bloq_new, c)

# 5. Update Seguridad Viernes and add Stop Loss Pips
sec_new = """input group "=== PROTECCION FIN DE SEMANA Y SEGURIDAD ==="
input bool     CerrarTodoViernesCierre    = true;        // ?? Cerrar Todo Viernes Cierre (Evitar Gaps Fin de Semana)
input int      HoraCierreViernes          = 16;          // ? Hora Cierre Forzoso Viernes (16:00 antes de noticias y cierre)
input bool     OperarViernesNoche         = false;       // ?? Permitir Nuevas Operaciones Viernes Noche
input int      HoraFinOperativaViernes    = 13;          // ? Hora Fin Nuevas Operaciones Viernes (Solo Manana)

input int      LimitePosicionesSOS        = 2;           // ?? Limite Maximo Posiciones SOS
input double   ProfitBreakEven            = 0.50;        // ??? Beneficio Minimo Break Even Cesta ($)
input double   ProteccionBeneficioDiario  = 0.0;         // ??? Proteger Beneficio Diario Acumulado ($)

input bool     UsarStopLossPipsCesta      = true;        // ?? Cortafuegos SL en Pips por Cesta (Anti-Desastre)
input double   MaxPipsPerdidaCesta        = 70.0;        // ?? Max. Desviacion Pips para Cortar Cesta (Evita el 15%)

input bool     UsarStopLossPorcentaje     = true;        // ??? Activar Stop Loss por % Cuenta (DE SERIE)
input double   PorcentajeStopLoss         = 15.0;        // ?? Porcentaje de Perdida Maxima (15.0% DE SERIE)"""

c = re.sub(r'input group "=== PROTECCION FIN DE SEMANA Y SEGURIDAD ==="[\r\n]+input bool\s+CerrarTodoViernesCierre\s*=\s*true;[^\r\n]*[\r\n]+input int\s+HoraCierreViernes\s*=\s*21;[^\r\n]*[\r\n]+input bool\s+OperarViernesNoche\s*=\s*false;[^\r\n]*[\r\n]+input int\s+LimitePosicionesSOS\s*=\s*2;[^\r\n]*[\r\n]+input double\s+ProfitBreakEven\s*=\s*0\.50;[^\r\n]*[\r\n]+input double\s+ProteccionBeneficioDiario\s*=\s*0\.0;[^\r\n]*[\r\n]+input bool\s+UsarStopLossPorcentaje\s*=\s*true;[^\r\n]*[\r\n]+input double\s+PorcentajeStopLoss\s*=\s*15\.0;[^\r\n]*', sec_new, c)

# 6. Update ValidarHorarioOperativo to respect HoraFinOperativaViernes
vho_old = """    // 3. Viernes noche / cierre fin de semana
    if(time.day_of_week == 5 && time.hour >= HoraCierreViernes && !OperarViernesNoche) {
        motivo = "VIERNES CIERRE FIN DE SEMANA";
        return false;
    }"""

vho_new = """    // 3. Viernes: no abrir nuevas posiciones por la tarde (despues de HoraFinOperativaViernes)
    if(time.day_of_week == 5 && time.hour >= HoraFinOperativaViernes) {
        motivo = "VIERNES TARDE BLOQUEADO (" + IntegerToString(HoraFinOperativaViernes) + ":00)";
        return false;
    }

    if(time.day_of_week == 5 && time.hour >= HoraCierreViernes && !OperarViernesNoche) {
        motivo = "VIERNES CIERRE FIN DE SEMANA";
        return false;
    }"""

if vho_old in c:
    c = c.replace(vho_old, vho_new)
else:
    c = re.sub(r'// 3\. Viernes noche / cierre fin de semana[\r\n]+if\(time\.day_of_week == 5 && time\.hour >= HoraCierreViernes && !OperarViernesNoche\) \{[\r\n]+motivo = "VIERNES CIERRE FIN DE SEMANA";[\r\n]+return false;[\r\n]+\}', vho_new, c)

# 7. Update targetActual in OnTick
c = c.replace(
    'double targetActual = (ArraySize(pos) >= LimitePosicionesSOS) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);',
    'double targetActual = (ArraySize(pos) > 1) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);'
)

# 8. Add UsarStopLossPipsCesta in OnTick
sl_pips_add = """    if(UsarStopLossPipsCesta && ArraySize(pos) > 0) {
        double pipsContra = 0;
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        if(pos[0].t == POSITION_TYPE_BUY) {
            pipsContra = (pos[0].p - bid) / (_Point * 10);
        } else {
            pipsContra = (ask - pos[0].p) / (_Point * 10);
        }
        if(pipsContra >= MaxPipsPerdidaCesta) {
            txtVoz = "STOP LOSS PIPS ALCANZADO.";
            CerrarTodo();
            enFaseAnalisis = false;
            if(UsarPausaTrasStopLoss && MinutosPausaTrasStopLoss > 0) {
                pausaStopLoss = TimeTradeServer() + (60 * MinutosPausaTrasStopLoss);
                txtVeredicto = "STANDBY TRAS SL PIPS HASTA: " + TimeToString(pausaStopLoss, TIME_MINUTES);
            } else {
                txtVeredicto = "REINICIANDO TRAS SL PIPS";
            }
            BotActivo = true;
            ActualizarInterfazMaster();
            return;
        }
    }

    GestionarCosechaSniper();"""

c = c.replace('GestionarCosechaSniper();', sl_pips_add, 1)

# 9. Update GestionarCosechaSniper
c = re.sub(
    r'void GestionarCosechaSniper\(\)\s*\{',
    'void GestionarCosechaSniper() {\n    if(!UsarCosechaIndividualSOS) return; // Si es false, la cesta se rescata en conjunto hacia Break Even',
    c, count=1
)

with open(dst_path, 'w', encoding='utf-8') as f:
    f.write(c)

print('V11.38 source code generated successfully!')
