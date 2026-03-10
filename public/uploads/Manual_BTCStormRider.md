# ⚡ BTC STORM RIDER v3.0

## Manual Oficial KOPYTRADING

---

> **Par:** BTCUSD · **Temporalidad:** H1 · **Plataforma:** MetaTrader 5

---

> ⚠️ **AVISO DE RIESGO LEGAL OBLIGATORIO**
>
> Bitcoin (BTCUSD) es el activo más volátil del mercado financiero.
> Opere únicamente con capital que pueda permitirse perder.
> Pruebe SIEMPRE en cuenta Demo antes de operar en real.
> Rentabilidades pasadas no garantizan resultados futuros.

---

## 🧠 1. ¿Qué es BTC Storm Rider?

**BTC Storm Rider v3.0** es la evolución definitiva del bot de Bitcoin de KOPYTRADING. Combina la potencia del **Breakout de Rango** con un sistema de **4 filtros de confirmación** y **gestión de riesgo adaptativa** basada en ATR.

### ¿Qué lo hace diferente?

| Característica | Lo que hace |
|---|---|
| 🎯 **Breakout Confirmado** | Solo entra cuando la ruptura es REAL (confirmada por 4 indicadores) |
| 📊 **4 Filtros Simultáneos** | EMA 200 + EMA 21/55 + RSI + ATR deben coincidir |
| 🛡️ **ATR Dinámico** | Stop Loss y Take Profit se adaptan a la volatilidad actual |
| 🚨 **Anti-Racha** | Límite de pérdida diaria y máx operaciones/día |
| ⏰ **Filtro de Sesión** | Solo opera cuando hay volumen real (Europa + USA) |
| 📈 **Trailing Inteligente** | Persigue el beneficio basándose en ATR |
| 🔒 **Break Even** | Protege ganancias moviendo el SL a cero riesgo |

### Expectativas de Operación

| Escenario | Frecuencia |
|---|---|
| Mercado con Tendencia Clara | 2-3 operaciones/día |
| Mercado Lateral/Rango | 0-1 operación/día |
| Días de Alta Volatilidad | 1-3 operaciones (protección activa) |

---

## 📊 2. Estrategia Técnica

### Los 5 Filtros de Entrada

El bot utiliza un sistema de **5 cerraduras**. Solo abre cuando TODAS están "en verde":

```
┌─────────────────────────────────────────────────┐
│  FILTRO 1: BREAKOUT                             │
│  ¿El precio ha roto el máximo/mínimo            │
│  de las últimas 24 velas?                        │
│                                                  │
│  FILTRO 2: TENDENCIA (EMA 200)                  │
│  ¿El precio está del lado correcto?              │
│                                                  │
│  FILTRO 3: MOMENTUM (EMA 21 vs 55)             │
│  ¿La EMA rápida confirma la dirección?           │
│                                                  │
│  FILTRO 4: FUERZA (RSI 14)                      │
│  ¿No estamos en zona peligrosa?                  │
│                                                  │
│  FILTRO 5: VOLATILIDAD (ATR 14)                 │
│  ¿Hay suficiente movimiento para ganar?          │
└─────────────────────────────────────────────────┘
                     ↓ SI TODO OK ↓
              ✅ EJECUTAR OPERACIÓN
```

### Ejemplo: Señal de Compra
1. ✅ Bitcoin rompe el **máximo** de las últimas 24 velas → Breakout real
2. ✅ Precio por **encima** de la EMA 200 → Tendencia alcista
3. ✅ EMA 21 **mayor** que EMA 55 → Momentum positivo
4. ✅ RSI entre 45-70 → Fuerza sin sobrecompra
5. ✅ ATR > mínimo → Hay movimiento suficiente

→ **¡COMPRA!** con SL a 2×ATR y TP a 4×ATR (ratio 1:2)

### Sistema Anti-Racha (NUEVO en v3.0)

```
┌──────────────────────────────────────────────┐
│  🚨 PROTECCIÓN ANTI-RACHA                    │
│                                               │
│  Si pierdes más de $100 en un día:            │
│     → Bot PARA de operar                     │
│     → Se reactiva al día siguiente           │
│                                               │
│  Si llegas a 3 operaciones en un día:         │
│     → Bot PARA de operar                     │
│     → Evita el "revenge trading"              │
└──────────────────────────────────────────────┘
```

### Para Supervisar en el Gráfico
Añade estos indicadores para "ver" lo que hace el bot:
1. **EMA 200** (Gris/Blanco) — La tendencia de fondo
2. **EMA 21** (Verde) — La señal rápida
3. **EMA 55** (Rojo) — La confirmación

---

## ⚙️ 3. Guía Completa de Parámetros

> Pulsa **F7** en MT5 para acceder a todos los parámetros.
> Los valores por defecto son los optimizados por KOPYTRADING.

### 🔑 LICENCIA KOPYTRADING

| Parámetro | Default | Descripción |
|---|---|---|
| `CuentaDemo` | 0 | Tu número de cuenta DEMO |
| `CuentaReal` | 0 | Tu número de cuenta REAL (solo compra) |

### ⏰ SESIONES DE MERCADO

| Parámetro | Default | Descripción |
|---|---|---|
| `SesionEuropa_Inicio` | 8 | Hora inicio sesión Europa |
| `SesionEuropa_Fin` | 16 | Hora fin sesión Europa |
| `SesionUS_Inicio` | 14 | Hora inicio sesión USA |
| `SesionUS_Fin` | 22 | Hora fin sesión USA |
| `OperarEnAsia` | false | ¿Permitir operar en sesión asiática? |

### 🛡️ GESTIÓN DE RIESGO

| Parámetro | Default | Descripción |
|---|---|---|
| `LoteInicial` | 0.01 | Tamaño de la posición |
| `MaxRiesgoPorTrade_USD` | 50.0 | Máxima pérdida en $ por operación |
| `ATR_Multiplicador_SL` | 2.0 | Stop Loss = X veces ATR |
| `ATR_Multiplicador_TP` | 4.0 | Take Profit = X veces ATR (ratio 1:2) |

### 🚨 PROTECCIÓN DE CUENTA

| Parámetro | Default | Descripción |
|---|---|---|
| `MaxPerdidaDiaria_USD` | 100.0 | Límite de pérdida diaria (el bot para) |
| `MaxOperacionesDia` | 3 | Máximo de operaciones por día |

### 📊 ESTRATEGIA BREAKOUT CONFIRMADO

| Parámetro | Default | Descripción |
|---|---|---|
| `VelasRango` | 24 | Nº de velas para calcular breakout |
| `FiltroMinRango_USD` | 500 | Rango mínimo en puntos |
| `EMA_Tendencia` | 200 | EMA de fondo |
| `EMA_Rapida` | 21 | EMA rápida (señal) |
| `EMA_Lenta` | 55 | EMA lenta (confirmación) |
| `RSI_Periodo` | 14 | Período RSI |
| `RSI_Compra_Min` | 45 | RSI mín para comprar |
| `RSI_Compra_Max` | 70 | RSI máx para comprar |
| `RSI_Venta_Min` | 30 | RSI mín para vender |
| `RSI_Venta_Max` | 55 | RSI máx para vender |
| `ATR_Periodo` | 14 | Período ATR |
| `ATR_Minimo_USD` | 300 | Volatilidad mínima para operar |

### 🔒 BREAK EVEN

| Parámetro | Default | Descripción |
|---|---|---|
| `ActivarBE` | true | Activar Break Even |
| `BE_ATR_Multiplicador` | 1.0 | Activar BE al ganar X veces ATR |
| `BE_Garantia_USD` | 1.0 | Ganancia asegurada tras BE |

### 📈 TRAILING STOP

| Parámetro | Default | Descripción |
|---|---|---|
| `ActivarTrailing` | true | Activar Trailing Stop |
| `Trailing_ATR_Multiplicador` | 1.5 | Distancia trailing en ATR |
| `Trailing_Salto_Puntos` | 500 | Salto mínimo para mover trailing |

### ⚙️ AVANZADO

| Parámetro | Default | Descripción |
|---|---|---|
| `MaxPosiciones` | 1 | Máx posiciones simultáneas |
| `MostrarPanel` | true | Panel informativo en el gráfico |
| `MagicNumber` | 780044 | Identificador único del bot |

---

## 🔧 4. Instalación

1. Descarga el archivo `.ex5` desde tu Dashboard en **kopytrading.com**
2. En MT5: **Archivo → Abrir Carpeta de Datos → MQL5 → Experts**
3. Copia el archivo en esa carpeta
4. Abre un gráfico **BTCUSD** en temporalidad **H1**
5. Arrastra el bot desde el **Navegador** al gráfico
6. Activa **AlgoTrading** (botón verde arriba a la derecha)
7. Configura parámetros con **F7** si lo deseas

---

## 🔄 5. Actualización y Reset

### Actualizar a Nueva Versión
1. **⚠️** Copia tu bot antiguo a una carpeta de seguridad
2. Descarga la nueva versión desde el Dashboard
3. Reemplaza en `MQL5 > Experts`
4. Reinicia MT5 o clic derecho → Actualizar

### Reset a Valores de Fábrica
1. Pulsa **F7** en el gráfico
2. Haz clic en **Restablecer (Reset)** abajo a la derecha
3. Los valores volverán a la configuración KOPYTRADING

---

## 💰 6. Escalado de Capital

| Tu Capital | Lote Recomendado | Max Pérdida Diaria |
|---|---|---|
| 2.000$ | 0.01 | $100 |
| 5.000$ | 0.03 | $150 |
| 10.000$ | 0.06 | $200 |
| 25.000$ | 0.15 | $400 |

> **Regla de oro**: Nunca arriesgues más del 2% de tu capital por operación.

---

## ❓ 7. Preguntas Frecuentes

**¿Por qué el bot no abre operaciones?**
Puede estar fuera de sesión, el ATR puede ser bajo, o la protección anti-racha se ha activado. Revisa el panel visual.

**¿Qué es la "Protección Anti-Racha"?**
Si el bot pierde más de $100 en un día o hace 3 operaciones, deja de operar hasta el día siguiente. Esto evita que una mala racha destruya tu cuenta.

**¿Puedo usarlo en cuenta real?**
Sí, pero necesitas una licencia de compra con tu número de cuenta configurado. También necesitas un mínimo de $2.000 de capital.

**¿Es compatible con Prop Firms?**
Sí. Sin martingala, sin grid, SL/TP definidos, y protección de drawdown diario.

---

*Manual revisado: Marzo 2026 | KOPYTRADING BTC Storm Rider v3.0 para MetaTrader 5*
*© 2026 KOPYTRADING. Todos los derechos reservados.*
