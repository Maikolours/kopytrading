# ⚡ BTC STORM RIDER v2.0 — Manual Oficial KOPYTRADE
**Versión 2.0 | BREAKOUT CRIPTO | Par: BTCUSD | Temporalidad: M30/H4 | MetaTrader 5 (MT5)**

---

> **⚠️ AVISO DE RIESGO LEGAL OBLIGATORIO**
> Bitcoin es el activo más volátil. Operar con este bot implica riesgo de pérdida total. Use capital de riesgo solamente.

---

## 1. ¿Qué es el BTC Storm Rider?

Un bot de **Ruptura de Rango**. Detecta cuando Bitcoin está acumulando energía y entra cuando el precio estalla con fuerza.

**Expectativas de Operación:**
- Mercado con Tendencia: **1-2 operaciones/día**.
- Mercado Lateral: **2-4 operaciones/semana**.

---

## 2. Estrategia Técnica & Guía Visual

El bot calcula el rango de ruptura. Para visualizarlo:
1. **Canal de Precios (Donchian)** (Periodo 24) en M30 o H1.

---

## 3. Guía de Parámetros (Inputs de MT5)

Pulsa **F7** en MetaTrader 5 para ajustar:

### === GESTIÓN DE RIESGO ===
*   **LoteInicial**: Volumen (Bitcoin requiere margen suficiente).
*   **StopLossUSD**: Protección en dólares (Default 80$ por 0.01).
*   **ProfitObjetivo**: Meta de beneficio (Default 50$).

### === ESTRATEGIA BREAKOUT ===
*   **VelasRango**: Período de tiempo que el bot analiza para detectar la ruptura.

### === GESTIÓN DE BENEFICIO ===
*   **BE_Activacion / TrailingStop**: Vitales en Bitcoin para no dejar que una ganancia se convierta en pérdida.

---

## 4. Cómo Actualizar tu Bot a una Nueva Versión

Si KOPYTRADE publica una nueva versión:
1.  **Descarga** el archivo `.ex5` desde el Dashboard.
2.  **⚠️ ADVERTENCIA DE SEGURIDAD (MUY IMPORTANTE):** Antes de sustituir el archivo, **copia tu bot antiguo** a una carpeta segura de tu ordenador. Si la nueva versión no te gusta o te da problemas en tu cuenta específica, siempre podrás volver a la versión anterior que ya tenías configurada.
3.  En MetaTrader 5 (MT5) ve a **Archivo > Abrir Carpeta de Datos > MQL5 > Experts**.
4.  **Reemplaza** el archivo antiguo por el nuevo.
5.  Reinicia MetaTrader o haz clic derecho en el Navegador -> Actualizar.

### Volver a Valores de Fábrica
1. Pulsa **F7** en el gráfico.
2. Haz clic en el botón **"Restablecer" (Reset)** en la parte inferior.
3. El bot recuperará instantáneamente la configuración optimizada de KOPYTRADE.

---

## 5. Escalado de Capital

| Capital | Lote Recomendado |
|---|---|
| 2.000$ | 0.01 |
| 5.000$ | 0.03 |
| 10.000$ | 0.06 |

---

*Manual revisado: Febrero 2026 | KOPYTRADE v2.0 para MetaTrader 5 (MT5)*
*© 2026 KOPYTRADE. Todos los derechos reservados.*
