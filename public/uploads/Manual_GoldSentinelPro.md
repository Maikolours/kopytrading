# 🛡️ GOLDSENTINEL PRO v1.0 — Manual Oficial KOPYTRADING
**Versión 1.0 | Inteligencia Adaptativa para el Oro | Par: XAUUSD | Temporalidad: M30 | MetaTrader 5 (MT5)**

---

> **⚠️ AVISO DE RIESGO LEGAL OBLIGATORIO**
> El Oro (XAUUSD) es extremadamente volátil. Opere únicamente con capital que pueda permitirse perder. Pruebe SIEMPRE en cuenta Demo antes de operar en real. Rentabilidades pasadas no garantizan resultados futuros.

---

## 1. ¿Qué es GoldSentinel Pro?

Es el bot **más inteligente** de KOPYTRADING para operar en Oro. A diferencia de otros bots que disparan a todo lo que se mueve, GoldSentinel Pro espera al **"tiro perfecto"**: solo entra cuando **4 indicadores están de acuerdo** al mismo tiempo.

**Filosofía:** Calidad sobre cantidad. Menos operaciones, más precisas.

### Características Principales
- 🧠 **Multi-Confirmación**: 4 indicadores deben coincidir para abrir una operación
- 📊 **Gestión ATR Dinámica**: El Stop Loss y Take Profit se adaptan a la volatilidad REAL del mercado
- ⏰ **Filtro de Sesiones**: Solo opera durante Londres y Nueva York (las horas más rentables para el Oro)
- 🔒 **Break Even Automático**: Protege tus ganancias moviendo el stop a cero pérdida
- 📈 **Trailing Stop Inteligente**: Persigue el beneficio automáticamente
- 🛡️ **Sin Grid, Sin Martingala**: 1 operación limpia con SL/TP definidos

### Expectativas de Operación
- Escenario Normal: **3-5 operaciones/día**
- Alta Volatilidad: **5-6 operaciones/día**
- Horario Activo: Sesiones de Londres y Nueva York

---

## 2. Estrategia Técnica

### Los 4 Filtros de Confirmación

El bot utiliza un sistema de **4 cerraduras**. Solo abre una operación cuando las 4 están "en verde":

| Filtro | Indicador | Función |
|---|---|---|
| 🌍 Tendencia Global | EMA 200 | ¿El mercado sube o baja a largo plazo? |
| 🔀 Momentum | EMA 21 vs EMA 55 | ¿Se acaba de producir un cruce? (señal de entrada) |
| 📉 Fuerza | RSI 14 | ¿No estamos en zona peligrosa? (sobrecompra/sobreventa) |
| 🔥 Volatilidad | ATR 14 | ¿Hay suficiente movimiento para ganar dinero? |

### Ejemplo de Señal de Compra
1. ✅ Precio está **por encima** de la EMA 200 → Tendencia alcista
2. ✅ EMA 21 **cruza por encima** de EMA 55 → Impulso al alza
3. ✅ RSI está entre 40-65 → No está sobrecomprado
4. ✅ ATR supera el mínimo → Hay volatilidad suficiente

→ **¡COMPRA!** con SL y TP calculados automáticamente por el ATR.

### Para Supervisar en el Gráfico
Añade estos indicadores manualmente para "ver" lo que el bot está haciendo:
1. **EMA 200** (Color: Blanco o Gris) — La "autopista" de la tendencia
2. **EMA 21** (Color: Verde) — La señal rápida
3. **EMA 55** (Color: Rojo) — La confirmación

Cuando el verde cruza por encima del rojo y el precio está encima de la blanca, el bot busca comprar.

---

## 3. Guía Completa de Parámetros (F7 en MT5)

### 🔑 LICENCIA KOPYTRADING
| Parámetro | Default | Descripción |
|---|---|---|
| `CuentaDemo` | 0 | Tu número de cuenta DEMO de MT5 |
| `CuentaReal` | 0 | Tu número de cuenta REAL de MT5 (solo compra) |

### ⏰ SESIONES DE MERCADO
| Parámetro | Default | Descripción |
|---|---|---|
| `SesionLondres_Inicio` | 8 | Hora broker inicio sesión Londres |
| `SesionLondres_Fin` | 11 | Hora broker fin sesión Londres |
| `SesionNY_Inicio` | 14 | Hora broker inicio sesión Nueva York |
| `SesionNY_Fin` | 17 | Hora broker fin sesión Nueva York |

### 🛡️ GESTIÓN DE RIESGO
| Parámetro | Default | Descripción |
|---|---|---|
| `LoteInicial` | 0.01 | Tamaño de posición |
| `MaxRiesgoPorTrade_USD` | 30.0 | Máxima pérdida en dólares por operación |
| `ATR_Multiplicador_SL` | 1.5 | Multiplicador ATR para Stop Loss (1.5x = conservador) |
| `ATR_Multiplicador_TP` | 3.0 | Multiplicador ATR para Take Profit (3x = ratio 1:2) |

### 📊 ESTRATEGIA MULTI-CONFIRMACIÓN
| Parámetro | Default | Descripción |
|---|---|---|
| `EMA_Tendencia` | 200 | EMA de tendencia de fondo |
| `EMA_Rapida` | 21 | EMA rápida para señal de cruce |
| `EMA_Lenta` | 55 | EMA lenta para confirmación |
| `RSI_Periodo` | 14 | Período del RSI |
| `RSI_Compra_Min` | 40 | RSI mínimo para comprar |
| `RSI_Compra_Max` | 65 | RSI máximo para comprar |
| `RSI_Venta_Min` | 35 | RSI mínimo para vender |
| `RSI_Venta_Max` | 60 | RSI máximo para vender |
| `ATR_Periodo` | 14 | Período del ATR |
| `ATR_Minimo_USD` | 2.0 | Volatilidad mínima para operar |

### 🔒 BREAK EVEN
| Parámetro | Default | Descripción |
|---|---|---|
| `ActivarBE` | true | Activar Break Even automático |
| `BE_ATR_Multiplicador` | 1.0 | Activar BE al ganar X veces ATR |
| `BE_Garantia_USD` | 0.5 | Ganancia asegurada tras activar BE |

### 📈 TRAILING STOP
| Parámetro | Default | Descripción |
|---|---|---|
| `ActivarTrailing` | true | Activar Trailing Stop |
| `Trailing_ATR_Multiplicador` | 1.0 | Distancia de seguimiento en ATR |
| `Trailing_Salto_Puntos` | 20 | Salto mínimo para mover el trailing |

### ⚙️ CONFIGURACIÓN AVANZADA
| Parámetro | Default | Descripción |
|---|---|---|
| `MaxPosiciones` | 1 | Máx posiciones simultáneas |
| `MostrarPanel` | true | Panel visual en el gráfico |
| `MagicNumber` | 779933 | ID único del bot |

---

## 4. Instalación Paso a Paso

1. **Descarga** el archivo `.mq5` desde tu Dashboard en kopytrading.com
2. Abre MetaTrader 5 y ve a **Archivo → Abrir Carpeta de Datos → MQL5 → Experts**
3. **Copia** el archivo descargado en esa carpeta
4. Abre **MetaEditor** (F4) y compila el archivo (F7)
5. En MT5, abre un gráfico **XAUUSD** en temporalidad **M30**
6. Arrastra el bot desde el **Navegador** al gráfico
7. Activa el botón **AlgoTrading** (arriba a la derecha, icono verde)
8. Configura tus parámetros con **F7**

---

## 5. Cómo Actualizar a una Nueva Versión

1. **⚠️ IMPORTANTE**: Antes de actualizar, **copia tu bot antiguo** a una carpeta de seguridad
2. Descarga la nueva versión desde tu Dashboard
3. Ve a `Archivo > Abrir Carpeta de Datos > MQL5 > Experts`
4. Reemplaza el archivo antiguo por el nuevo
5. Reinicia MetaTrader o haz clic derecho en el Navegador → Actualizar
6. Recompila en MetaEditor (F4 → F7)

---

## 6. Reset a Valores de Fábrica

1. Abre parámetros con **F7**
2. Pulsa **Restablecer (Reset)** abajo a la derecha
3. Los valores volverán a la configuración calibrada por KOPYTRADING
4. Pulsa OK

---

## 7. Escalado de Capital

| Tu Capital | Lote Recomendado | Riesgo Máx/Trade |
|---|---|---|
| 500$ | 0.01 | 30$ |
| 1.000$ | 0.02 | 50$ |
| 2.500$ | 0.05 | 75$ |
| 5.000$ | 0.10 | 100$ |
| 10.000$ | 0.20 | 150$ |

> **Regla de oro**: Nunca arriesgues más del 2-3% de tu capital en una sola operación.

---

## 8. Preguntas Frecuentes

**¿Por qué el bot no abre operaciones?**
Puede que estés fuera del horario de sesión (Londres 8-11h / NY 14-17h) o que la volatilidad sea demasiado baja. Revisa el panel visual.

**¿Puedo usarlo en otros pares?**
Está optimizado para XAUUSD (Oro). Usarlo en otros pares puede dar resultados impredecibles.

**¿Qué temporalidad debo usar?**
M30 es la recomendada. Puedes probar en H1 para menos operaciones y más filtradas.

**¿Funciona en cuentas de Prop Firms?**
Sí, al no usar grid ni martingala y tener SL/TP definidos, es compatible con la mayoría de reglas de prop firms.

---

*Manual revisado: Marzo 2026 | KOPYTRADING GoldSentinel Pro v1.0 para MetaTrader 5*
*© 2026 KOPYTRADING. Todos los derechos reservados.*
