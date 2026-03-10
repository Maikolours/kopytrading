# 🔥 LA AMETRALLADORA v2.1 — Manual Oficial KOPYTRADING
**Versión 2.1 | EL REY DEL ORO | Par: XAUUSD | Temporalidad: M15 | MetaTrader 5 (MT5)**

---

> **⚠️ AVISO DE RIESGO LEGAL OBLIGATORIO**
> El Oro es extremadamente volátil. Opere únicamente con capital que pueda permitirse perder. Pruebe SIEMPRE en cuenta Demo antes de operar en real.

---

## 1. ¿Qué es La Ametralladora?

Es el bot más activo de KOPYTRADING. Utiliza un sistema de **Hedging Inteligente** (coberturas) para capturar beneficios constantes en el Oro.

**Expectativas de Operación:**
- Escenario Normal: **5-10 operaciones/día**.
- Alta Volatilidad: **Up to 15 operaciones/día**.

---

## 2. Estrategia Técnica & Guía Visual

El bot usa una EMA de referencia y un sistema de "Escudos". Para supervisarlo visualmente:
1. **EMA 14** (Color Cian o Blanco)

Cuando el precio está por encima, el bot es comprador. Cuando está por debajo, es vendedor. Si el precio retrocede, verás aparecer un "RELEVO" (cobertura) para proteger el ciclo.

---

## 3. Guía de Parámetros (Inputs de MT5)

Pulsa **F7** en MetaTrader 5 para ajustar:

### === RELOJ PERÍODO OPERATIVO ===
*   **HoraInicio / HoraFin**: Horario broker en el que el bot abrirá la "primera bala" del ciclo.

### === GESTIÓN DE RIESGO ===
*   **LoteInicial**: Tamaño de la posición inicial (Default 0.01).
*   **StopLossUSD**: Máxima pérdida en dólares que permites por ciclo de hedging.
*   **ProfitObjetivo**: Ganancia deseada para cerrar el primer disparo del ciclo.

### === ESTRATEGIA AMETRALLADORA ===
*   **DistanciaPipsHedge**: A cuántos pips se coloca el escudo de protección (Default 8 pips).
*   **LoteHedge**: Lote de la cobertura (Recomendado 0.02 si el inicial es 0.01).

### === GESTIÓN DE BENEFICIO ===
*   **BE_Activacion**: Ganancia para activar el Break Even.
*   **ActivarTrailing**: Si es TRUE, el stop persigue el beneficio.

---

## 4. Cómo Actualizar tu Bot a una Nueva Versión

Si KOPYTRADING publica una nueva versión:
1.  **Descarga** el archivo `.ex5` desde el Dashboard.
2.  **⚠️ ADVERTENCIA DE SEGURIDAD (MUY IMPORTANTE):** Antes de sustituir el archivo, **copia tu bot antiguo** a una carpeta segura de tu ordenador. Si la nueva versión no te gusta o te da problemas en tu cuenta específica, siempre podrás volver a la versión anterior que ya tenías configurada.
3.  En MetaTrader 5 (MT5) ve a **Archivo > Abrir Carpeta de Datos > MQL5 > Experts**.
4.  **Reemplaza** el archivo antiguo por el nuevo.
5.  Reinicia MetaTrader o haz clic derecho en el Navegador -> Actualizar.

---

## 5. Cómo Volver a los Valores de Fábrica (RESET)

Si los parámetros han sido modificados y quieres volver al punto de partida óptimo:
1. Abre la ventana de parámetros (**F7**).
2. Haz clic en el botón **"Restablecer" (Reset)** abajo a la derecha.
3. El bot cargará los valores de fábrica calibrados por KOPYTRADING.
4. Pulsa OK.

---

## 6. Escalado de Capital

| Capital | Lote Recomendado |
|---|---|
| 1.000$ | 0.01 |
| 2.500$ | 0.02 |
| 5.000$ | 0.05 |

---

*Manual revisado: Febrero 2026 | KOPYTRADING v2.1 para MetaTrader 5 (MT5)*
*© 2026 KOPYTRADING. Todos los derechos reservados.*
