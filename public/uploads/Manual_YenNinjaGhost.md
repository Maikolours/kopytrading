# 🥷 YEN NINJA GHOST v2.0 — Manual Oficial KOPYTRADING
**Versión 2.0 | REBOTE ASIÁTICO | Par: USDJPY | Temporalidad: M30/H1 | MetaTrader 5 (MT5)**

---

> **⚠️ AVISO DE RIESGO LEGAL OBLIGATORIO**
> El Yen Japonés es extremadamente sensible. Opere con precaución. Pruebe SIEMPRE en cuenta Demo antes de operar en real.

---

## 1. ¿Qué es el Yen Ninja Ghost?

Un bot especializado en la **Sesión Asiática**. Busca rebotes técnicos cuando el mercado está en calma pero definido.

**Expectativas de Operación (Sesión Noctura):**
- Escenario Normal: **1-3 operaciones/noche**.
- Mercado Volátil: **Hasta 4 operaciones/noche**.

---

## 2. Estrategia Técnica & Guía Visual

El bot usa Bandas de Bollinger y RSI. Para verlo en tu gráfico:
1. **Bandas de Bollinger** (Periodo 20, Desviación 1.5)
2. **RSI 14** (Niveles 40 / 60)

---

## 3. Guía de Parámetros (Inputs de MT5)

Pulsa **F7** en MetaTrader 5 para ajustar:

### === RELOJ DE OPERACIÓN ===
*   **HoraInicio / HoraFin**: Horario de la sesión asiática (Default 00:00 a 08:00 hora broker).

### === GESTIÓN DE RIESGO ===
*   **LoteInicial**: Volumen de entrada.
*   **StopLossUSD**: Protección máxima en dólares por operación.
*   **ProfitObjetivo**: Ganancia en dólares para cerrar.

### === ESTRATEGIA NINJA ===
*   **BB_Desviacion**: Ajusta la sensibilidad del rebote (1.5 es más activo, 2.0 más seguro).
*   **RSI_Sobrevendido / Sobrecomprado**: Filtros de agotamiento.

### === GESTIÓN DE BENEFICIO ===
*   **BE_Activacion y ActivarTrailing**: Gestión automática de la rentabilidad.

---

## 4. Cómo Actualizar tu Bot a una Nueva Versión

Si KOPYTRADING publica una nueva versión:
1.  **Descarga** el archivo `.ex5` desde el Dashboard.
2.  **⚠️ ADVERTENCIA DE SEGURIDAD (MUY IMPORTANTE):** Antes de sustituir el archivo, **copia tu bot antiguo** a una carpeta segura de tu ordenador. Si la nueva versión no te gusta o te da problemas en tu cuenta específica, siempre podrás volver a la versión anterior que ya tenías configurada.
3.  En MetaTrader 5 (MT5) ve a **Archivo > Abrir Carpeta de Datos > MQL5 > Experts**.
4.  **Reemplaza** el archivo antiguo por el nuevo.
5.  Reinicia MetaTrader o haz clic derecho en el Navegador -> Actualizar. con los nuevos ajustes.

### Resetear (Volver al inicio)
Si has tocado los ajustes y quieres volver a la configuración Ninja original:
1. Abre los parámetros (**F7**).
2. Pulsa el botón **"Restablecer" (Reset)**.
3. Pulsa OK. El bot volverá a sus valores óptimos de fábrica.

---

## 5. Escalado de Capital

| Capital | Lote Recomendado |
|---|---|
| 500$ | 0.01 |
| 1.500$ | 0.03 |
| 3.000$ | 0.06 |

---

*Manual revisado: Febrero 2026 | KOPYTRADING v2.0 para MetaTrader 5 (MT5)*
*© 2026 KOPYTRADING. Todos los derechos reservados.*
