# 🎯 EURO PRECISION FLOW — Manual Oficial KOPYTRADE
**Versión 1.0 | Par: EURUSD | Temporalidad: M30 (Recomendado) / H1 (Conservador)**

---

> **⚠️ AVISO DE RIESGO LEGAL OBLIGATORIO**
> El uso de este software conlleva un alto riesgo de pérdida de capital. Los resultados mostrados son orientativos y NO garantizan rendimientos futuros. KOPYTRADE NO se hace responsable de pérdidas derivadas del uso de este bot en ninguna circunstancia. Opere únicamente con capital que pueda permitirse perder. Pruebe SIEMPRE en cuenta Demo antes de operar en real.

---

## 1. ¿Qué es el Euro Precision Flow?

El **Euro Precision Flow** es un bot de trading tendencial para **EURUSD**. Su filosofía: no entra en cualquier movimiento, solo en los que tienen alta probabilidad de continuar. Es el bot más **seguro y conservador** de KOPYTRADE, ideal para principiantes.

---

## 2. Estrategia Técnica: Cómo Decide Cuándo Entrar

### 2.1 Las dos Medias Móviles (EMA Cross)

| EMA | Período | Rol |
|-----|---------|-----|
| EMA Rápida | 21 períodos | Captura movimiento reciente |
| EMA Lenta | 50 períodos | Tendencia más amplia |

- **COMPRA:** EMA 21 cruza POR ENCIMA de la EMA 50 + RSI < 60
- **VENTA:** EMA 21 cruza POR DEBAJO de la EMA 50 + RSI > 40

---

## 3. ¿Con Qué Frecuencia Opera? Expectativas REALES

**La clave para entender este bot: es selectivo por diseño.**

| Temporalidad | Estado del mercado | Operaciones esperadas |
|---|---|---|
| **M30 (Recomendado)** | EURUSD en tendencia | **3-6 operaciones/semana** |
| **M30 (Recomendado)** | EURUSD lateral | **1-2 operaciones/semana** |
| H1 (Conservador) | EURUSD en tendencia | **1-3 operaciones/semana** |
| H1 (Conservador) | EURUSD lateral | **0-1 operaciones/semana** |

> **⭐ En M30 puedes esperar entre 3 y 8 operaciones por semana.**

### ¿Por Qué no Ha Abierto Operaciones?

El bot espera que la EMA de 21 períodos **cruce** la EMA de 50. En mercados laterales (EURUSD quieto, sin tendencia clara) las medias van paralelas sin cruzarse. Eso puede durar 1-3 días. **Eso es normal y correcto.** El bot NO opera si no ve condiciones suficientemente claras.

Puedes confirmar que funciona: en la pestaña "Expertos" de MT5 deberías ver:
```
✅ LICENCIA COMPLETA | Cuenta: TU_NÚMERO
```

---

## 4. Configuración de Fábrica (Valores Predeterminados)

**⚠️ IMPORTANTE: Los valores de fábrica son los que han sido calibrados y probados. Úselos tal como están, especialmente los primeros meses.**

| Parámetro | Valor predeterminado | ¿Qué hace? |
|---|---|---|
| CuentaDemo / CuentaReal | 0 | Tu nº de cuenta MT5 |
| LoteInicial | **0.01** | Tamaño de cada operación |
| ProfitObjetivo | **$8.00** | Cierra la operación con $8 de ganancia |
| BE_Activacion | **$3.00** | Activa Break Even a los $3 ganados |
| GarantiaBE | **$0.50** | Protege $0.50 cuando activa BE |
| EMA_Rapida | **21** | Media móvil rápida |
| EMA_Lenta | **50** | Media móvil lenta |
| RSI_Periodo | 14 | Período del RSI |
| DistanciaTrailing | **150 puntos (15 pips)** | Trailing Stop |
| HoraInicio | 8 | Apertura sesión europea |
| HoraFin | 20 | Cierre sesión americana |

### ¿Cómo Restaurar los Valores de Fábrica?
1. Doble clic sobre el bot en el gráfico
2. Pestaña **"Inputs (Parámetros)"**
3. Clic en **"Restablecer"** (abajo del todo)
4. OK — vuelven los valores originales automáticamente

---

## 5. Para Hacer el Bot MÁS ACTIVO

Si llevas varios días sin operaciones y quieres ver más acción, tienes dos opciones:

### Opción A: Cambiar de H1 a M30 (RECOMENDADA)
Esta es la mejor opción para aumentar las señales sin cambiar ningún parámetro:
1. Cierra el bot del gráfico H1 actual
2. Abre un gráfico EURUSD en **M30**
3. Arrastra el bot al nuevo gráfico
4. Las señales serán el doble de frecuentes (de 1-3/semana a 3-6/semana)

### Opción B: Reducir los Períodos de EMA (MÁS CAMBIO)
Si quieres más señales aún manteniendo H1:

| Parámetro | Valor fábrica (H1) | Valor más activo |
|---|---|---|
| EMA_Rapida | 21 | **9** |
| EMA_Lenta | 50 | **21** |

*Con EMA 9/21 en H1 puedes esperar 3-5 operaciones por semana. El precio es que alguna señal puede ser menos fiable.*

### Opción C: Ajuste del Filtro RSI

| Parámetro | Valor fábrica | Valor más permisivo |
|---|---|---|
| RSI_Sobrecomprado | 60 | **65** |
| RSI_Sobrevendido | 40 | **35** |

*Esto permite entrar en más situaciones.*

---

## 6. Personalización: Modos Conservador y Agresivo

**⚠️ Prueba SIEMPRE en Demo antes de cambiar estos valores en cuenta Real.**

### Modo CONSERVADOR (para cuentas pequeñas o principiantes)

| Parámetro | Fábrica | Conservador |
|---|---|---|
| LoteInicial | 0.01 | **0.01** (no cambies) |
| ProfitObjetivo | $8 | **$5** |
| BE_Activacion | $3 | **$2** |
| DistanciaTrailing | 150 pts | **200 pts** |

### Modo AGRESIVO (para cuentas de +1.500$ con experiencia)

| Parámetro | Fábrica | Agresivo |
|---|---|---|
| ProfitObjetivo | $8 | **$15** |
| BE_Activacion | $3 | **$5** |
| EMA_Rapida | 21 | **9** |
| EMA_Lenta | 50 | **21** |

---

## 7. Brokers Recomendados

| Broker | Spread EURUSD | VPS gratis | Regulación |
|---|---|---|---|
| Pepperstone | Desde 0.1 pips | ✅ Sí | FCA / ASIC |
| IC Markets | Desde 0.1 pips | ✅ Sí | ASIC / CySEC |
| Vantage Markets | ~0.5 pips | ❌ | ASIC / CIMA |
| VT Markets | ~0.8 pips | ❌ | ASIC / FSC |

---

## 8. VPS — ¿Lo Necesito?

Con horario 8:00-20:00 (laboral europeo), puedes gestionar sin VPS si tu ordenador está siempre encendido. Recomendamos VPS si tienes cortes de internet frecuentes o sales mucho de casa.

---

## 9. Gestión del Riesgo

### Reglas de Oro
- ⛔ No cambies el lotaje sin experiencia previa
- ⛔ No toques el bot durante publicaciones macro (BCE, FED)
- ✅ Prueba 2-3 semanas en Demo primero
- ✅ Usa M30 para más actividad

### Capital Mínimo
- Demo: cualquier cantidad
- Real: mínimo **$500** con lote 0.01

---

## 10. Descargo de Responsabilidad

**KOPYTRADE no es un asesor financiero regulado.** Este bot es software. No garantiza rentabilidad. Bajo ninguna circunstancia KOPYTRADE asume responsabilidad por pérdidas derivadas de su uso. Los resultados históricos no garantizan rendimientos futuros. El trading de Forex implica alto riesgo. Solo opere con capital que pueda permitirse perder completamente.

Al utilizar este bot confirmas haber leído y aceptado este manual, el Aviso de Riesgo y los Términos de Uso de KOPYTRADE.

---

*Manual revisado: Febrero 2026 | KOPYTRADE v1.0*
*© 2026 KOPYTRADE. Todos los derechos reservados.*
