import codecs
import glob
import re
import os

var_comments_fixed = {
    "MiLicencia": "// 🔑 Clave de Licencia o Correo Usuario",
    "DiasDeTrial": "// ⏳ Días de Prueba (Solo Trial)",
    "MaxRangoVelaM1": "// ⚡ Rango Máximo Vela M1 (Pips)",
    "MaxSpreadPips": "// 📊 Spread Máximo Permitido (Pips)",
    "SensibilidadMechaReal": "// ⚖️ Sensibilidad Rechazo de Mechas",
    "MinutosPausaTrasSusto": "// ⏱️ Minutos Pausa tras Vela Extrema",
    "MaxRsiCompra": "// 📈 RSI Máximo para Compras (Filtro Techos)",
    "MinRsiVenta": "// 📉 RSI Mínimo para Ventas (Filtro Suelos)",
    "UsarFiltroTechosSuelos": "// 🏛️ Activar Filtro Techos y Suelos M15 (S/R)",
    "TimeframeTechosSuelos": "// 📅 Temporalidad para Techos/Suelos M15",
    "PeriodoTechosSuelos": "// 🔢 Período de Velas M15 a Analizar",
    "DistanciaTechoSueloPips": "// 📏 Distancia Mínima M15 para Bloquear (Pips)",
    "UsarFiltroTechosSuelosH1": "// 🛡️ Activar Filtro S/R en H1",
    "PeriodoTechosSuelosH1": "// 🔢 Período H1 a Analizar (Velas)",
    "DistanciaTechoSueloPipsH1": "// 📏 Distancia Mínima H1 (Pips)",
    "UsarFiltroTechosSuelosH4": "// 🛡️ Activar Filtro S/R en H4",
    "PeriodoTechosSuelosH4": "// 🔢 Período H4 a Analizar (Velas)",
    "DistanciaTechoSueloPipsH4": "// 📏 Distancia Mínima H4 (Pips)",
    "UsarFiltroAgotamientoM15": "// 🛑 Activar Filtro Agotamiento M15",
    "MinPorcentajeMechaM15": "// 🌡️ % Mínimo Mecha Reversa (40.0 = 40%)",
    "UsarConfirmacionRuptura": "// ✅ Confirmar Ruptura de S/R con Vela Cerrada",
    "TimeframeConfirmacion": "// 📅 Temporalidad de Confirmación (M5/M15)",
    "LoteAtaque": "// 🚀 Volumen Entrada Inicial (Ataque)",
    "MultiplicadorRefuerzo": "// ✖️ Multiplicador Lote de Rescate (SOS)",
    "DistanciaRefuerzoPips": "// 📏 Distancia Mínima para Abrir SOS (Pips)",
    "MaxLoteTotal": "// 🚫 Lote Máximo Acumulado Permitido",
    "MaxLoteIndividual": "// 🚫 Volumen Máximo por Operación SOS",
    "ProfitCosechaIndividual": "// 💵 Beneficio Cierre SOS Individual ($)",
    "TargetDiario": "// 🎯 Meta de Beneficio Diario ($)",
    "ProfitNetoFlush": "// 💵 Beneficio Cierre Total Cesta ($)",
    "ProfitBreakEven": "// 🛡️ Beneficio Mínimo Break Even Cesta ($)",
    "HoraInicioOperativa": "// ⏰ Hora de Inicio Operaciones (Broker)",
    "HoraFinOperativa": "// ⏰ Hora de Cierre Operaciones (Broker)",
    "OperarViernesNoche": "// 🌃 Permitir Operaciones Viernes Noche",
    "UsarHorarioBloqueo": "// 📰 Evitar Noticias (Bloqueo Horario)",
    "HoraInicioBloqueo": "// ⏰ Hora Inicio Bloqueo Noticias",
    "HoraFinBloqueo": "// ⏰ Hora Fin Bloqueo Noticias",
    "LimitePosicionesSOS": "// 📉 Límite Máximo Posiciones SOS",
    "UsarStopLossPorcentaje": "// 🛡️ Activar Stop Loss por % Cuenta",
    "PorcentajeStopLoss": "// 📉 Porcentaje de Pérdida Máxima...",
    "UsarPausaTrasStopLoss": "// ⏸️ Pausar Bot tras un Stop Loss",
    "MinutosPausaTrasStopLoss": "// ⏳ Minutos de Pausa tras Stop Loss",
    "ColorMain": "// 🎨 Color Principal HUD (Acento)",
    "ColorHeader": "// 🎨 Color Encabezado Panel HUD",
    "ColorBody": "// 🎨 Color Cuerpo Panel HUD",
    "BloquearPorCruceEMA_M15": "// ✅ Confirmar EMA con Vela M15 Cerrada",
    "HUD_X": "// 📐 Posición X en Pantalla (Pixeles)",
    "PosY_HUD": "// 📐 Posición Y en Pantalla (Pixeles)",
    "TradeComment": "// 📝 Comentario para Órdenes (Trade Comment)"
}

base_path = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\*\MQL5\Experts\BOTS MAIKO\*.mq5'
files = glob.glob(base_path)

for f in files:
    if 'MASTER' in f.upper():
        continue
        
    print(f"Processing {f}")
    try:
        with codecs.open(f, 'r', encoding='utf-16le') as file:
            content = file.read()
    except Exception as e:
        print(f"Failed to read {f}: {e}")
        continue
        
    lines = content.split('\n')
    changed = False
    
    for i, line in enumerate(lines):
        if 'input' in line and '//' in line:
            match = re.search(r'^(\s*(?:s?input)\s+(?:string|int|double|bool|color|ENUM_\w+)\s+(\w+)\s*(?:=|;).*?)(//.*)', line)
            if match:
                var_name = match.group(2)
                if var_name in var_comments_fixed:
                    correct_comment = var_comments_fixed[var_name]
                    if correct_comment not in line:
                        lines[i] = match.group(1) + correct_comment
                        changed = True

    if changed:
        print(f"Fixing emojis in {f}")
        new_content = '\n'.join(lines)
        with open(f, 'wb') as file:
            file.write(codecs.BOM_UTF16_LE)
            file.write(new_content.lstrip('\ufeff').encode('utf-16le'))
