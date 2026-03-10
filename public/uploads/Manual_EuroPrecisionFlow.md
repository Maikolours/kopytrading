# 🎯 EURO PRECISION FLOW v2.0 (TURBO) — Manual Oficial KOPYTRADING
**Versión 2.0 | ACTIVIDAD EXTREMA | Par: EURUSD | Temporalidad: M15/M30**

---

> **⚠️ AVISO DE RIESGO LEGAL OBLIGATORIO**
> El uso de este software conlleva un alto riesgo de pérdida de capital. Opere únicamente con capital que pueda permitirse perder. Pruebe SIEMPRE en cuenta Demo antes de operar en real.

---

## 1. ¿Qué es el Euro Precision Flow "Turbo"?

En su versión 2.0, el Euro Precision Flow ha sido optimizado para una **actividad extrema**. Es nuestro bot más equilibrado pero ahora con una frecuencia de disparo mucho mayor.

**Expectativas de Operación:**
- Escenario Normal: **4-8 operaciones/día**.
- Escenario Tendencial: **Up to 10 operaciones/día**.

---

### 🔍 Cómo Monitorear el Bot (Muy Importante)
Si ves que el bot no abre operaciones, es probable que las condiciones técnicas no se estén cumpliendo. Para vigilarlo tú mismo en MT5:

1.  **Abre el gráfico** de EURUSD en temporalidad **M15** o **M30**.
2.  **Añade estos indicadores** para ver lo mismo que el bot:
    *   `Moving Average` -> Periodo: **5**, Método: **Exponential**, Color: **Azul**.
    *   `Moving Average` -> Periodo: **13**, Método: **Exponential**, Color: **Rojo**.
    *   `Relative Strength Index (RSI)` -> Periodo: **14**. Añade niveles en **40** y **60**.
3.  **Observa la señal**: El bot busca entrar cuando la línea azul cruza la roja **Y** el RSI confirma el impulso (por encima de 60 para ventas o debajo de 40 para compras, dependiendo de la dirección del cruce). Si el mercado está plano, las EMAs estarán "pegadas" y el bot no operará para evitar pérdidas por ruido.

---

## 3. Guía de Parámetros (Inputs de MT5)

Pulsa **F7** en tu teclado dentro de MetaTrader 5 para ajustar estos valores:

### === RELOJ DE OPERACIÓN ===
*   **HoraInicio / HoraFin**: Define cuándo quieres que el bot busque entradas (Hora del broker).

### === GESTIÓN DE RIESGO ===
*   **LoteInicial**: Volumen de entrada (Recomendado 0.01 por cada 500$).
*   **StopLossUSD**: Máxima pérdida permitida en dólares por operación.
*   **ProfitObjetivo**: Ganancia en dólares para cerrar la operación.

### === GESTIÓN DE BENEFICIO ===
*   **BE_Activacion**: Cuándo mover el Stop al punto de entrada para no perder (Break Even).
*   **ActivarTrailing**: Si es TRUE, el stop perseguirá al precio para asegurar beneficios.

---

### 7. Cómo Actualizar tu Bot a una Nueva Versión
Cuando KOPYTRADING publique una mejora (ej. de v2.0 a v2.1), recibirás un aviso en tu panel de usuario. Para actualizar:

1.  **Descarga** el nuevo archivo `.ex5` desde tu panel.
2.  **⚠️ ADVERTENCIA DE SEGURIDAD (MUY IMPORTANTE):** Antes de sustituir el archivo, **copia tu bot antiguo** a una carpeta segura de tu ordenador. Si la nueva versión no te gusta o te da problemas en tu cuenta específica, siempre podrás volver a la versión anterior que ya tenías configurada.
3.  Abre MetaTrader 5 (MT5).
4.  Ve a `Archivo` -> `Abrir carpeta de datos`.
5.  Navega a `MQL5` -> `Experts`.
6.  **Reemplaza** el archivo antiguo por el nuevo.
7.  Reinicia MetaTrader o haz clic derecho en el Navegador -> Actualizar.

---

## 5. Cómo Volver a los Valores de Fábrica (RESET)

Si has modificado los parámetros y quieres volver a la configuración óptima de KOPYTRADING:
1. Abre la ventana de parámetros (**F7**).
2. Haz clic en el botón **"Restablecer" (Reset)** abajo a la derecha.
3. El bot cargará automáticamente nuestros valores "Turbo" optimizados.
4. Pulsa OK.

---

## 6. Escalado de Capital

| Capital | Lote Recomendado |
|---|---|
| 500$ | 0.01 |
| 1.500$ | 0.03 |
| 5.000$ | 0.10 |

---

*Manual revisado: Febrero 2026 | KOPYTRADING v2.0*
*© 2026 KOPYTRADING. Todos los derechos reservados.*
