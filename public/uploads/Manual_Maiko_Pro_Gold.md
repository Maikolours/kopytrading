
# MANUAL OFICIAL: MAIKO PRO GOLD
**Versión del Algoritmo:** 5.84 (Maiko Engine)
**Instrumento Optimizado:** XAUUSD (Oro al contado)
**Temporalidad (Timeframe):** M1 (Optimizado) - Aunque lee H4 y M5 internamente.

---

## 1. ESTRATEGIA Y FUNCIONAMIENTO
**MAIKO PRO GOLD** es nuestro algoritmo insignia diseñado específicamente para dominar la volatilidad del Oro. Utiliza una arquitectura **Sniper Grid** en temporalidad **M1**.
- **Entradas de Alta Precisión (Sniper):** El bot analiza divergencias y agotamiento del precio mediante filtros de RSI, MACD, y acción del precio. No dispara por disparar.
- **Gestor de Drawdown (Grid/Martingala Dinámica):** Si el precio se gira en contra, el bot ejecuta un "Modo SOS" abriendo posiciones de refuerzo en niveles clave (promediando el precio de entrada) para poder salir rápido del mercado en cuanto haya un pequeño rebote.
- **Filtros Institucionales:** Tiene activados bloqueos por Spreads altos (Spread Spike Detection) y filtros de direccionalidad en temporalidades mayores (H4, H1, M15).

## 2. REQUISITOS DEL SISTEMA
- **Capital Mínimo Recomendado:** $1,000 USD (Para trabajar con holgura).
- **Cuenta:** Cuenta estándar o ECN con bajo Spread.
- **Apalancamiento:** 1:500 o superior.
- **VPS:** Altamente recomendado (un VPS garantiza conexión 24/5 con el mercado).

## 3. INSTALACIÓN Y CONEXIÓN
1. Descarga el archivo `.ex5` del dashboard de Kopytrade.
2. Abre tu **MetaTrader 5**. Ve a `Archivo > Abrir Carpeta de Datos > MQL5 > Experts` y pega ahí el archivo `.ex5`.
3. En MT5, ve a `Herramientas > Opciones > Asesores Expertos` y marca **"Permitir WebRequest para las siguientes URL"**. Añade: `https://www.kopytrading.com`
4. Refresca la ventana de "Navegador" en MT5, arrastra el bot a un gráfico de **XAUUSD en M1**.
5. En la ventana de configuración del bot, introduce tu **Email de Compra**, tu **Clave de Licencia (ID)** que aparece en el dashboard, y asegúrate de activar el botón "Algo Trading".

## 4. CONSEJOS DE USO
- **¡No cierres posiciones manualmente!** El bot tiene un TP (Take Profit) global invisible. Si cierras una operación suelta, puedes romper la cesta matemática del Grid.
- **Eventos de Noticias (NFP, IPC):** Aunque el bot tiene protección de spreads, se recomienda **PAUSAR** el bot (desde el dashboard o MT5) 30 minutos antes de noticias de muy alto impacto si tienes posiciones abiertas y flotante negativo alto.
- **Supervisión remota:** Utiliza el Dashboard Web de Kopytrade para pausarlo, cerrarlo en caso de emergencia, o monitorear el Profit del Día sin necesidad de entrar a tu VPS.
