
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #F7931A; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO BTC ₿</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO BTC** es un algoritmo Institucional diseñado para domar la bestia de las Criptomonedas, operando de Lunes a Domingo.
- **Perfil de Riesgo:** Medio-Alto (Bitcoin es altamente volátil).
- **Rendimiento Esperado:** Ganancias explosivas, seguidas de largos periodos de inactividad. A diferencia del Forex, el Bitcoin se mueve por "sacudidas". El bot no estará operando 24 horas seguidas; es un depredador paciente.
- **Operativa de Fin de Semana:** El fin de semana baja el volumen institucional. El bot está diseñado para aprovechar esta lateralización y realizar entradas seguras en los soportes y resistencias.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
A diferencia de los pares de divisas, el Bitcoin no respeta los canales lógicos y tiene fuertes impulsos (pumps y dumps). Por eso, la estrategia es radicalmente distinta:
1. **Filtro de Sobrecompra Extrema:** El bot no persigue el precio. Se queda escondido hasta que detecta que el Bitcoin ha sido sobre-vendido de manera irracional (pánico de mercado) analizando niveles de RSI y ATR en temporalidades cortas.
2. **Entrada Anti-Dump:** Entra en compra sólo cuando detecta que la fuerza vendedora se ha agotado.
3. **Protección Anti-Liquidación (Trailing DD):** En Bitcoin no podemos usar una cascada profunda porque una caída puede durar meses. El bot utiliza un sistema de límite de equidad y salidas de emergencia para cortar pérdidas antes de que ocurra un desastre.

## 3. CONSEJOS DE TEMPORALIDAD
- **Temporalidad (Timeframe) Obligatoria:** M1 (1 Minuto).
- Si lo dejas en M1, él se encargará de medir la velocidad a la que baja el precio para dictaminar si es una simple corrección o un colapso del mercado.

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Descarga el .ex5** desde Kopytrading y cópialo a `MQL5 > Experts`.
2. **Permisos Web:** Activa "Permitir WebRequest" hacia `https://www.kopytrading.com`.
3. **Broker Crypto-Friendly:** Asegúrate de que tu broker permite operar Bitcoin los fines de semana y tiene un SPREAD BAJO. (Si el spread es gigantesco, el bot se negará a operar).
4. **Gráfico:** Ábrelo en BTCUSD (M1), pon tu Licencia y Email, y enciende "Algo Trading".

## 5. RECOMENDACIONES VITALES
- **Capital Mínimo:** Recomendamos $2,000 USD de capital operativo para soportar las fluctuaciones del precio del Bitcoin de forma cómoda.

## 6. PREGUNTAS FRECUENTES Y SOLUCIÓN DE PROBLEMAS (FAQ)

### P: He arrastrado el bot y le he dado a "ENCENDER" pero no hace nada y no cambia de color.
- **Mercado cerrado o sin ticks de precio**: Los botones y textos de la interfaz del bot (HUD) solo se actualizan cuando el broker envía un movimiento de precio (tick). Si el mercado está cerrado (fin de semana) o hay bajísima liquidez, al hacer clic el botón parecerá no hacer nada. En cuanto abra el mercado y entre el primer precio, el bot se encenderá visualmente y actualizará todo su estado.
- **Algo Trading desactivado**: Asegúrate de que el botón general "Algo Trading" en la barra superior de MetaTrader 5 esté en **verde** y que hayas marcado la casilla "Permitir trading algorítmico" en las opciones comunes del bot al arrastrarlo.

### P: En el estado inferior pone "FUERA HORARIO: ESPERANDO" o "HORARIO BLOQUEADO (NOTICIAS)".
- El bot tiene horas operativas configuradas por defecto (de 09:00 a 19:00 hora del broker). Fuera de este rango, o durante periodos de noticias importantes (si tienes activado el bloqueo), el bot entrará en modo espera automática para proteger tu capital. Volverá a operar solo cuando se cumpla la hora programada.

### P: He instalado la versión de prueba (Trial/Demo) en una cuenta Real y no funciona.
- Las versiones de prueba están estrictamente limitadas por código para funcionar únicamente en cuentas de tipo **DEMO**. Si se intenta colocar en una cuenta Real, el bot lanzará una ventana de alerta y se retirará del gráfico de inmediato para evitar riesgos.

