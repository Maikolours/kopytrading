const fs = require('fs');
const path = require('path');
const { mdToPdf } = require('md-to-pdf');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const goldMd = `
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
1. Descarga el archivo \`.ex5\` del dashboard de Kopytrade.
2. Abre tu **MetaTrader 5**. Ve a \`Archivo > Abrir Carpeta de Datos > MQL5 > Experts\` y pega ahí el archivo \`.ex5\`.
3. En MT5, ve a \`Herramientas > Opciones > Asesores Expertos\` y marca **"Permitir WebRequest para las siguientes URL"**. Añade: \`https://www.kopytrading.com\`
4. Refresca la ventana de "Navegador" en MT5, arrastra el bot a un gráfico de **XAUUSD en M1**.
5. En la ventana de configuración del bot, introduce tu **Email de Compra**, tu **Clave de Licencia (ID)** que aparece en el dashboard, y asegúrate de activar el botón "Algo Trading".

## 4. CONSEJOS DE USO
- **¡No cierres posiciones manualmente!** El bot tiene un TP (Take Profit) global invisible. Si cierras una operación suelta, puedes romper la cesta matemática del Grid.
- **Eventos de Noticias (NFP, IPC):** Aunque el bot tiene protección de spreads, se recomienda **PAUSAR** el bot (desde el dashboard o MT5) 30 minutos antes de noticias de muy alto impacto si tienes posiciones abiertas y flotante negativo alto.
- **Supervisión remota:** Utiliza el Dashboard Web de Kopytrade para pausarlo, cerrarlo en caso de emergencia, o monitorear el Profit del Día sin necesidad de entrar a tu VPS.
`;

const centMd = `
# MANUAL OFICIAL: MAIKO PRO CENT
**Versión del Algoritmo:** 2.0 (Maiko Engine)
**Instrumento Optimizado:** XAUUSD (Oro) / Pares Mayores
**Temporalidad (Timeframe):** M1 (Optimizado)

---

## 1. ESTRATEGIA Y FUNCIONAMIENTO
**MAIKO PRO CENT** contiene el mismo motor letal que la versión Gold, pero está **calibrado específicamente para cuentas CENT**.
- **Exposición de Capital Reducida:** En una cuenta CENT, $100 USD se ven como $10,000 centavos. El bot aprovecha este margen enorme para poder abrir cuadrículas (Grid) mucho más largas sin poner en riesgo el capital real.
- **Entradas Sniper:** Al igual que su hermano mayor, espera confirmaciones en los indicadores internos para lanzar la primera operación.
- **Recuperación Elástica:** Utiliza las posiciones de refuerzo (SOS) a mayores distancias, lo que le permite sobrevivir a movimientos direccionales muy fuertes del Oro sin quemar la cuenta.

## 2. REQUISITOS DEL SISTEMA
- **Capital Mínimo Recomendado:** $100 USD (que serán 10,000 centavos).
- **Tipo de Cuenta:** OBLIGATORIO usar una cuenta **CENT** o Micro.
- **Apalancamiento:** 1:500 a 1:1000.

## 3. INSTALACIÓN Y CONEXIÓN
1. Descarga el archivo \`.ex5\` desde tu dashboard.
2. Cópialo a \`Archivo > Abrir Carpeta de Datos > MQL5 > Experts\` en tu MetaTrader 5.
3. Activa las WebRequests en \`Herramientas > Opciones > Asesores Expertos\` y añade: \`https://www.kopytrading.com\`
4. Arrastra el bot a un gráfico de **XAUUSD en M1**. (Algunos brokers tienen el Oro Cent como XAUUSDc o GOLD.c, asegúrate de arrastrarlo al símbolo correcto que te permita operar).
5. Introduce tus credenciales (Licencia ID y Email) en la pestaña "Parámetros de Entrada" y activa "Algo Trading".

## 4. CONSEJOS DE USO
- Al ser una cuenta CENT, los beneficios diarios en dólares serán menores (por ejemplo $1 o $2 al día), pero el riesgo es extremadamente bajo comparado con una cuenta Estándar. Es ideal para interés compuesto a largo plazo.
- Puedes dejarlo correr con noticias sin tanto miedo, ya que el margen operativo en CENTs es inmenso.
`;

const btcMd = `
# MANUAL OFICIAL: MAIKO PRO BTC
**Versión del Algoritmo:** 7.11 (Maiko Engine)
**Instrumento Optimizado:** BTCUSD (Bitcoin)
**Temporalidad (Timeframe):** M1 (Optimizado)

---

## 1. ESTRATEGIA Y FUNCIONAMIENTO
**MAIKO PRO BTC** es un desarrollo institucional para operar en el mercado cripto.
- **Especialidad Fin de Semana:** El Bitcoin opera 24/7. Este algoritmo está especialmente diseñado para aprovechar la volatilidad reducida y los "micropulsos" de fin de semana, aunque puede operar perfectamente de Lunes a Viernes.
- **Mapeo de EMAs y RSI:** Utiliza análisis de Cruces de Medias Móviles en M5 y M1, junto a niveles dinámicos de RSI para identificar sobrecompras y sobreventas en Bitcoin.
- **Cierre por Drawdown (Trailing DD):** Incluye funciones únicas de protección de equidad máxima que detectan si el Bitcoin entra en un ciclo bajista/alcista salvaje incontrolable.

## 2. REQUISITOS DEL SISTEMA
- **Capital Mínimo Recomendado:** $2,000 USD (El Bitcoin mueve muchos pips muy rápido).
- **Cuenta:** Cuenta Crypto o ECN que permita operar BTC los fines de semana.
- **Spreads:** Busca un broker con spreads bajos en BTCUSD.

## 3. INSTALACIÓN Y CONEXIÓN
1. Descarga tu archivo \`.ex5\` y colócalo en la carpeta \`MQL5 > Experts\` de tu MetaTrader 5.
2. Habilita los WebRequests (\`https://www.kopytrading.com\`) en las opciones del terminal.
3. Arrastra el bot al gráfico **BTCUSD en M1**.
4. En los ajustes de entrada, coloca tu Licencia (ID del dashboard) y tu correo. 
5. Asegúrate de tener el botón verde de "Algo Trading" encendido.

## 4. CONSEJOS DE USO
- El Bitcoin no respeta horarios institucionales como Forex. Por lo que **MAIKO PRO BTC** puede estar largo rato en "Buscando Entradas" (Status). Es normal, espera a que el mercado esté maduro.
- Controla el SPREAD. En fin de semana los brokers suelen ensanchar el spread de las criptos. El bot tiene un filtro automático (\`MaxSpreadPips\`) que evitará entrar si el spread es abusivo.
`;

async function generateManuals() {
    const outDir = path.join(__dirname, '..', 'public', 'uploads');
    
    // Write markdown files
    fs.writeFileSync(path.join(outDir, 'Manual_Maiko_Pro_Gold.md'), goldMd);
    fs.writeFileSync(path.join(outDir, 'Manual_Maiko_Pro_Cent.md'), centMd);
    fs.writeFileSync(path.join(outDir, 'Manual_Maiko_Pro_BTC.md'), btcMd);

    // Convert to PDF
    console.log("Converting to PDF...");
    try {
        await mdToPdf({ path: path.join(outDir, 'Manual_Maiko_Pro_Gold.md') }, { dest: path.join(outDir, 'Manual_Maiko_Pro_Gold.pdf') });
        await mdToPdf({ path: path.join(outDir, 'Manual_Maiko_Pro_Cent.md') }, { dest: path.join(outDir, 'Manual_Maiko_Pro_Cent.pdf') });
        await mdToPdf({ path: path.join(outDir, 'Manual_Maiko_Pro_BTC.md') }, { dest: path.join(outDir, 'Manual_Maiko_Pro_BTC.pdf') });
        console.log("PDFs generated.");
    } catch (e) {
        console.error("Error generating PDFs:", e);
    }

    // Update DB
    console.log("Updating Database...");
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'GOLD' } },
        data: { pdfFilePath: '/uploads/Manual_Maiko_Pro_Gold.pdf' }
    });
    
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'CENT' } },
        data: { pdfFilePath: '/uploads/Manual_Maiko_Pro_Cent.pdf' }
    });
    
    await prisma.botProduct.updateMany({
        where: { name: { contains: 'BTC' } },
        data: { pdfFilePath: '/uploads/Manual_Maiko_Pro_BTC.pdf' }
    });

    console.log("Database updated.");
}

generateManuals().catch(console.error);
