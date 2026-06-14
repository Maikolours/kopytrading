# Plan de Implementación: Estado Visual del Bot en Fin de Semana y Expansión de KopyBot

Este plan describe la solución para mejorar la experiencia de usuario y el feedback visual del bot en MetaTrader 5 cuando el mercado está cerrado (fines de semana o fuera de horario), y para enriquecer la base de datos de respuestas de nuestro asistente virtual (KopyBot) en la página web.

## Cambios Propuestos

### Componente: Robots MetaTrader 5 (MQL5)

Modificaremos los 4 archivos `.mq5` en la carpeta de origen del terminal MT5 principal:
- [Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5](file:///C:/Users/Usuario/AppData/Roaming/MetaQuotes/Terminal/BB8163656548A371304D87AABB7A68EB/MQL5/Experts/BOTS%20MAIKO/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5)
- [Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5](file:///C:/Users/Usuario/AppData/Roaming/MetaQuotes/Terminal/BB8163656548A371304D87AABB7A68EB/MQL5/Experts/BOTS%20MAIKO/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5)
- [Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5](file:///C:/Users/Usuario/AppData/Roaming/MetaQuotes/Terminal/BB8163656548A371304D87AABB7A68EB/MQL5/Experts/BOTS%20MAIKO/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5)
- [Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5](file:///C:/Users/Usuario/AppData/Roaming/MetaQuotes/Terminal/BB8163656548A371304D87AABB7A68EB/MQL5/Experts/BOTS%20MAIKO/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5)

#### Detalles de la Modificación
1. **Creación de `ActualizarTextosEstado()`**:
   Implementaremos esta función centralizada para recalcular las cadenas de texto del HUD según el estado del mercado (`TimeTradeServer()`):
   - Si `BotActivo` es falso: `txtVoz = "BOT APAGADO / PAUSADO"`, `txtVeredicto = "APAGADO"`.
   - Si hay posiciones abiertas: Mantener mensaje `"MAIKO: Vigilando COMPRA/VENTA activo..."`.
   - Si está fuera de horario (fin de semana o noche): `txtVoz = "FUERA HORARIO: MERCADO CERRADO"` o `"FUERA HORARIO: ESPERANDO"`, `txtVeredicto = "ARMADO (FUERA DE HORARIO)"`.
   - Si está dentro de horario operativo: Inicializar a `"SCHOLAR: Buscando..."` y `"ESPERANDO..."` (salvo que ya esté en análisis).

2. **Llamada en Click de Objeto (`OnChartEvent`)**:
   Cuando se pulse el botón de encendido (`MAIKO_BtnP`), se llamará inmediatamente a `ActualizarTextosEstado()` y a `ActualizarInterfazMaster()`. Esto pintará el HUD al instante (rojo "APAGAR" + Estado "ARMADO") sin requerir la llegada de un tick.

3. **Optimización en `OnTick`**:
   Llamar a `ActualizarTextosEstado()` al inicio para sincronizar y dibujar todo de inmediato. Ajustar la validación horaria de `OnTick` para evitar redundancias.

---

### Componente: Chatbot de la Página Web (React / Next.js)

#### [MODIFY] [FloatingChat.tsx](file:///C:/proyectos/APP%20KOPYTRADING/src/components/FloatingChat.tsx)
- Añadir un nuevo bloque de respuesta bajo `BOT_RESPONSES` con palabras clave como `"dormir"`, `"irse a dormir"`, `"dejar encendido"`, `"se activa solo"`, `"fin de semana"`, etc.
- La respuesta explicará claramente que si el botón está rojo ("APAGAR"), el bot está armado y operará solo en cuanto abra el mercado. Recordará también la importancia de usar un VPS si se va a dormir para evitar desconexiones.
- Enriquecer otras preguntas comunes para dotar al bot de la máxima información útil para los clientes (VPS, licencias, real vs demo, apalancamiento, etc.).

---

## Plan de Verificación

### Compilación de Bots y Sincronización
- Ejecutar el script `scratch/compile_and_sync_our_bots.ps1` en PowerShell para compilar todos los bots modificados en MetaEditor y verificar que no hay errores de sintaxis en MQL5.
- Confirmar que los archivos `.ex5` y `.mq5` se actualizan en el panel de descargas del sitio web (`public/uploads/bots/` y `private_bots_backup/`).

### Compilación Web
- Ejecutar `npm run build` en la terminal local para asegurar que la actualización de `FloatingChat.tsx` compila perfectamente en Next.js.
