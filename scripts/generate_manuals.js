const fs = require('fs');
const path = require('path');
const { mdToPdf } = require('md-to-pdf');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const goldMd = `
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #FFD700; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO GOLD 🏆</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO GOLD** es nuestro algoritmo más agresivo y sofisticado, diseñado para aprovechar al máximo la alta volatilidad del mercado del Oro (XAUUSD). 
- **Perfil de Riesgo:** Medio-Alto. Está pensado para generar beneficios rápidos y diarios.
- **Rendimiento Esperado:** Busca cerrar un objetivo diario concreto (ej: $100 - $150) y luego "irse a dormir". 
- **Comportamiento en Flotante:** Es normal que a lo largo de su operativa acumule un "flotante negativo" temporal. El bot promedia precios para buscar un punto de salida matemático; por tanto, **ver operaciones en rojo es parte natural de su estrategia**. No te asustes, el algoritmo tiene sus propios cortafuegos.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
Utiliza una estrategia mixta de **Sniper Scalping** y **Recuperación Elástica (SOS)**:
1. **Análisis de Tendencia:** Internamente escanea el mercado en temporalidades largas (H4, H1 y M15) para identificar si el día es alcista o bajista.
2. **Entrada de Precisión:** Baja a la temporalidad de 1 Minuto (M1) para buscar divergencias y retrocesos usando RSI y ATR. Entra justo cuando el mercado está "sobre-estirado" en el corto plazo.
3. **Gestión de Crisis (SOS / Cascada):** Si el precio se gira repentinamente en contra tras la entrada, el bot no asume la pérdida inmediatamente. En su lugar, activa el Modo SOS: despliega operaciones adicionales más abajo con un lotaje fríamente calculado (Martingala dinámica) para "promediar" el precio de entrada. En cuanto el Oro hace un pequeño retroceso (que siempre lo hace), el bot cierra toda la cesta de golpe en ganancia.

## 3. CONSEJOS DE TEMPORALIDAD
- **Temporalidad (Timeframe) Obligatoria:** M1 (1 Minuto).
- **Aviso:** Aunque lo pongas en M1, su "cerebro" está analizando H4 y M15 en segundo plano. Nunca lo pongas en H1 o H4, ya que las distancias matemáticas se romperían.

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Descarga:** Obtén el archivo \`.ex5\` desde tu dashboard de Kopytrading.
2. **Ubicación:** Cópialo en tu MetaTrader 5, dentro de \`Archivo > Abrir Carpeta de Datos > MQL5 > Experts\`.
3. **Permisos Web:** En MT5 ve a \`Herramientas > Opciones > Asesores Expertos\` y marca "Permitir WebRequest para las siguientes URL". Añade: \`https://www.kopytrading.com\`.
4. **Gráfico:** Abre un gráfico de XAUUSD (Oro) y ponlo en M1. Arrastra el bot al gráfico.
5. **Autenticación:** En la ventana que aparece, pon tu **Email de Kopytrading** y la **Clave de Licencia (ID)** que te aparece en la web.
6. **Ejecución:** Asegúrate de que el botón **"Algo Trading"** de arriba está en verde.

## 5. RECOMENDACIONES VITALES
- **Capital Mínimo:** Se recomienda encarecidamente $1,000 USD de balance para soportar los flotantes en modo SOS.
- **NO INTERVENIR:** Nunca cierres una operación manualmente si el bot tiene un grupo de operaciones abiertas. Romperías el cálculo matemático de su cierre automático.
- **Noticias:** Durante noticias extremas (NFP, IPC), el mercado se vuelve caótico. El bot tiene un filtro, pero se recomienda pausarlo 30 minutos antes de estos eventos.
`;

const centMd = `
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #00FF7F; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO CENT 🟢</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO CENT** es la versión "Blindada" del motor Maiko. Al estar diseñado exclusivamente para operar en Cuentas CENT (donde 100 dólares equivalen a 10.000 centavos), es un bot extremadamente conservador en cuanto a riesgo real, pero constante.
- **Perfil de Riesgo:** Muy Bajo.
- **Rendimiento Esperado:** Menos dólares netos al día que la versión Gold, pero con una curva de crecimiento mucho más suave y sostenida (ideal para Interés Compuesto).
- **Comportamiento en Flotante:** Soportará drawdowns enormes sin apenas inmutarse. Si el Oro cae 1000 pips de golpe, tu cuenta CENT apenas sufrirá un porcentaje minúsculo de riesgo gracias al amplio margen de los centavos.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
Es exactamente el mismo "Motor de Inteligencia" que el MAIKO PRO GOLD, pero sus distancias matemáticas están reajustadas:
1. **Entradas Sniper:** Analiza M1 para entrar en los retrocesos del mercado.
2. **Red de Seguridad Ampliada:** Al tener decenas de miles de "centavos" de margen, su modo Cascada/SOS puede permitirse abrir posiciones con mucha más distancia entre ellas. En lugar de estresarse por un retroceso rápido, el bot teje una red amplia que atrapará el precio con total seguridad, incluso si la tendencia tarda semanas en darse la vuelta.

## 3. CONSEJOS DE TEMPORALIDAD
- **Temporalidad (Timeframe) Obligatoria:** M1 (1 Minuto).
- Al igual que el Gold, aunque la gráfica esté en M1, el bot realiza sus cálculos de tendencia mayor analizando H1 y M15 de forma invisible.

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Verificar Broker:** Asegúrate de que tu cuenta en el broker es tipo **CENT**, Micro o USC. Si instalas este bot en una cuenta Standard con $100, la quemarás.
2. **Instalación:** Pega el archivo \`.ex5\` en \`MQL5 > Experts\` de tu MetaTrader 5.
3. **WebRequests:** Añade \`https://www.kopytrading.com\` en las Opciones de Asesores Expertos.
4. **Gráfico:** Abre el gráfico de Oro (frecuentemente llamado XAUUSDc, XAUUSD.c o GOLD.c en cuentas Cent). Ponlo en M1.
5. **Configuración:** Pon tu Email y tu Licencia (ID). Enciende el "Algo Trading".

## 5. RECOMENDACIONES VITALES
- **Paciencia:** Al ver las ganancias en centavos, muchos usuarios se impacientan y suben los lotes. **No lo hagas**. El poder del bot CENT reside en sobrevivir a crisis mundiales del mercado sin estrés. Deja que el interés compuesto haga su magia mes a mes.
`;

const btcMd = `
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
1. **Descarga el .ex5** desde Kopytrading y cópialo a \`MQL5 > Experts\`.
2. **Permisos Web:** Activa "Permitir WebRequest" hacia \`https://www.kopytrading.com\`.
3. **Broker Crypto-Friendly:** Asegúrate de que tu broker permite operar Bitcoin los fines de semana y tiene un SPREAD BAJO. (Si el spread es gigantesco, el bot se negará a operar).
4. **Gráfico:** Ábrelo en BTCUSD (M1), pon tu Licencia y Email, y enciende "Algo Trading".

## 5. RECOMENDACIONES VITALES
- **Status "Buscando...":** Verás que el bot pasa horas o incluso días sin abrir operaciones. **No está roto, está analizando**. El Bitcoin requiere extrema precisión.
- **Capital Mínimo:** Recomendamos $2,000 USD de capital operativo para soportar las fluctuaciones del precio del Bitcoin de forma cómoda.
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
}

generateManuals().catch(console.error);
