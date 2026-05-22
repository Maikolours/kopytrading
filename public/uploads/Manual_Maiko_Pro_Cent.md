
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
1. Descarga el archivo `.ex5` desde tu dashboard.
2. Cópialo a `Archivo > Abrir Carpeta de Datos > MQL5 > Experts` en tu MetaTrader 5.
3. Activa las WebRequests en `Herramientas > Opciones > Asesores Expertos` y añade: `https://www.kopytrading.com`
4. Arrastra el bot a un gráfico de **XAUUSD en M1**. (Algunos brokers tienen el Oro Cent como XAUUSDc o GOLD.c, asegúrate de arrastrarlo al símbolo correcto que te permita operar).
5. Introduce tus credenciales (Licencia ID y Email) en la pestaña "Parámetros de Entrada" y activa "Algo Trading".

## 4. CONSEJOS DE USO
- Al ser una cuenta CENT, los beneficios diarios en dólares serán menores (por ejemplo $1 o $2 al día), pero el riesgo es extremadamente bajo comparado con una cuenta Estándar. Es ideal para interés compuesto a largo plazo.
- Puedes dejarlo correr con noticias sin tanto miedo, ya que el margen operativo en CENTs es inmenso.
