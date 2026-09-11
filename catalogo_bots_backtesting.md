# 📊 Catálogo de Bots KOPYTRADING — Top 10 para Backtesting

> Actualizado: Septiembre 2026 · Par principal: XAUUSD (Oro) · Cuenta demo recomendada para backtesting

---

## 🏆 TOP 10 Candidatos para Backtesting

| # | Nombre del Bot | Fecha Creación | Par | Estrategia Principal | Tamaño | Prioridad |
|---|---|---|---|---|---|---|
| 1 | **MAIKO_PRO_GOLD_ORIGINAL_AGOSTO** | Sep 2026 | XAUUSD | Scholar M5 + SOS + Cosecha Sniper | 52.9 KB | ⭐⭐⭐⭐⭐ |
| 2 | **MAIKO_PRO_GOLD_DEMO_V11.33** | Sep 2026 | XAUUSD | Scholar M5 + Filtros H1/H4 + SOS | 57.7 KB | ⭐⭐⭐⭐⭐ |
| 3 | **MAIKO_PRO_GOLD_V11_34_1_RISK** | Sep 2026 | XAUUSD | Scholar M1 + ATR SL + Circuit Breaker | 81.8 KB | ⭐⭐⭐⭐ |
| 4 | **MAIKO_PRO_GOLD_DEMO_V11.34_FrancotiradorM5** | Sep 2026 | XAUUSD | Una sola entrada precisa sin SOS | 10.4 KB | ⭐⭐⭐⭐ |
| 5 | **KOPYTRADING_XAUUSD_Evolution_Pro_v5_84** | Jun 2026 | XAUUSD | Evolution Pro con lotes dinámicos | 28.8 KB | ⭐⭐⭐⭐ |
| 6 | **MAIKO_PRO_GOLD_DEMO (v11.32)** | Ago 2026 | XAUUSD | Scholar + Techos/Suelos M15 + SOS | 46.8 KB | ⭐⭐⭐⭐ |
| 7 | **KOPYTRADE_XAUUSD_Evolution_Universal_v6_10** | Mar 2026 | XAUUSD | Cesta universal bi-direccional | 21.7 KB | ⭐⭐⭐ |
| 8 | **KOPYTRADE_XAUUSD_EVOLUTION_v8_3_1_TITAN_SHIELD** | Mar 2026 | XAUUSD | Titan Shield (escudo dinámico) | 19 KB | ⭐⭐⭐ |
| 9 | **KOPYTRADE_XAUUSD_Ametralladora_Evolution** | Mar 2026 | XAUUSD | Ametralladora clásica + SOS | 29.5 KB | ⭐⭐⭐ |
| 10 | **XAUUSD_Elite_Warrior_Safe_V2** | Ago 2026 | XAUUSD | Elite Warrior con SL protegido | 42.4 KB | ⭐⭐⭐ |

---

## 📋 Descripción Detallada

---

### 1. 🥇 MAIKO_PRO_GOLD_ORIGINAL_AGOSTO
```
📁 Ruta: Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/
📅 Creación: 04 Sep 2026  |  Modificado: 10 Sep 2026
📦 Tamaño: 52.9 KB  |  ⏱️ Temporalidad: M5
```
**Estrategia:** Sistema Scholar multi-temporalidad (EMA en W1/D1/H4/H1/M15/M5/M1). Filtra por techos/suelos en M15, H1 y H4. Sistema SOS (Salvamento) con multiplicador configurable. Cosecha Sniper de operaciones individuales. Sin SL fijo en broker — gestión de cesta con cierre neto.

**Resultado real:**
- 10/09/2026 sesión apertura: **+\$3.79** ✅ Sin ninguna operación en pérdida.
- Hoy mismo AGOSTO ganó mientras RISK perdía con el mismo mercado.

**Por qué es el #1:** Es el bot que ha demostrado mejor consistencia en condiciones reales. El backtesting con datos de 2025-2026 confirmará si esto se sostiene. Candidato a ser el bot principal de Kopytrading.

---

### 2. 🥈 MAIKO_PRO_GOLD_DEMO_V11.33
```
📁 Ruta: Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/
📅 Creación: 01 Sep 2026  |  Modificado: 04 Sep 2026
📦 Tamaño: 57.7 KB  |  ⏱️ Temporalidad: M5
```
**Estrategia:** Evolución directa del Scholar v11.32. Añade: RSI como filtro adicional, mecha M15 para detectar agotamiento, confirmación de ruptura de S/R con vela cerrada, bloqueo horario por noticias (configurable), protección de beneficio diario y control de spread máximo.

**Resultado real:** Semana 7-8 Sep 2026 operó correctamente en sesión London/NY con operaciones positivas. Se desactivó al estrenar la versión AGOSTO.

**Por qué es el #2:** Tiene más filtros que AGOSTO y puede ser más selectivo. El backtesting dirá si esa selectividad aumenta o disminuye la rentabilidad total.

---

### 3. 🥉 MAIKO_PRO_GOLD_V11_34_1_RISK
```
📁 Ruta: Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/
📅 Creación: 09 Sep 2026  |  Modificado: 09 Sep 2026
📦 Tamaño: 81.8 KB  |  ⏱️ Temporalidad: M1 (actualmente)
```
**Estrategia:** Versión con gestión de riesgo avanzada: lote calculado por % de equity automáticamente, SL real en broker basado en ATR×1.80, filtro de volatilidad extrema (ratio ATR), circuit breaker tras N pérdidas consecutivas, límite de pérdida diaria por % de balance.

**Resultado real:**
- 09-10 Sep 2026: **-\$40 acumulados** ❌
- Causa confirmada: SL del broker demasiado ceñido en M1. El ruido del oro (50-80 pips de oscilación normal) caza el SL antes de que la operación se desarrolle.

**Por qué es el #3 (aunque negativo):** El backtesting permitirá optimizar:
- ATR multiplicador: de 1.80 → probar 3.0, 4.0, 5.0
- Temporalidad: M1 → probar M5 para ver si invierte el resultado
- Circuit breaker: ajustar N pérdidas consecutivas

> [!WARNING]
> Antes de más sesiones en demo con este bot, recomiendo **desactivar el SL ceñido** (`UsarStopServidorATR = false`) o subirlo a ATR×4.0 como mínimo. Actualmente está sangrando innecesariamente.

---

### 4. 🎯 MAIKO_PRO_GOLD_DEMO_V11.34_FrancotiradorM5
```
📁 Ruta: Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/
📅 Creación: 02 Sep 2026  |  Modificado: 03 Sep 2026
📦 Tamaño: 10.4 KB  |  ⏱️ Temporalidad: M5
```
**Estrategia:** Versión minimalista del Scholar. Una sola entrada de precisión, sin SOS ni martingala. Solo entra cuando todos los filtros están perfectamente alineados. Si la operación falla, no recupera. Enfocado en operaciones de altísima probabilidad con TP individual.

**Resultado real:** Pocos días en demo, historial insuficiente.

**Por qué es el #4:** Su simplicidad lo hace ideal para backtesting puro, sin el efecto "rescate" del SOS que distorsiona resultados en otros sistemas. Dará una visión limpia de la calidad de las señales de entrada del Scholar.

---

### 5. 📈 KOPYTRADING_XAUUSD_Evolution_Pro_v5_84
```
📁 Ruta: .next/standalone/public/uploads/
📅 Creación: Jun 2026
📦 Tamaño: 28.8 KB  |  ⏱️ Temporalidad: M15/M30
```
**Estrategia:** Evolution Pro de la línea clásica. Gestión dinámica de lotes por equity, tendencia con EMA y MACD, cierre por TP individual y flotante neto de cesta. Precursor conceptual del Scholar moderno. Fue probado durante varios meses en demo con resultados consistentes en tendencias claras.

---

### 6. 📊 MAIKO_PRO_GOLD_DEMO (v11.32)
```
📁 Ruta: Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/
📅 Creación: 28 Ago 2026  |  Modificado: 04 Sep 2026
📦 Tamaño: 46.8 KB  |  ⏱️ Temporalidad: M5
```
**Estrategia:** Primera versión estable del Scholar con techos/suelos M15. Base de la que derivan todas las versiones posteriores. Filtra por EMA, RSI, spread y volatilidad de vela M1. Sin los filtros H1/H4 que se añadieron en v11.33.

---

### 7. 🔄 KOPYTRADE_XAUUSD_Evolution_Universal_v6_10
```
📁 Ruta: .next/standalone/public/uploads/
📅 Creación: Mar 2026
📦 Tamaño: 21.7 KB
```
**Estrategia:** Evolution Universal: combina tendencia (EMA) con sistema SOS universal. Funciona en ambas direcciones sin preferencia de tendencia macro. Primera versión con cesta "sin sesgo de dirección".

---

### 8. 🛡️ KOPYTRADE_XAUUSD_EVOLUTION_v8_3_1_TITAN_SHIELD
```
📁 Ruta: .next/standalone/public/uploads/LEGACY/
📅 Creación: Mar 2026
📦 Tamaño: 19 KB
```
**Estrategia:** Titan Shield: implementa reducción de exposición cuando el flotante supera un umbral negativo (escudo dinámico). Precursor conceptual del sistema RISK actual. Menos sofisticado pero el backtesting puede revelar si el concepto de escudo funciona bien en tendencias largas.

---

### 9. 🔫 KOPYTRADE_XAUUSD_Ametralladora_Evolution
```
📁 Ruta: .next/standalone/public/uploads/LEGACY/
📅 Creación: Mar 2026
📦 Tamaño: 29.5 KB
```
**Estrategia:** La Ametralladora clásica en su versión Evolution: múltiples entradas rápidas en la misma dirección + cierre de cesta neta. Sistema fundacional del proyecto Kopytrading (antes del Scholar). Mayor agresividad = mayor riesgo pero potencialmente mayor retorno en tendencias fuertes y largas.

---

### 10. ⚔️ XAUUSD_Elite_Warrior_Safe_V2
```
📁 Ruta: Agosto_2026_Activos/ y .next/standalone/public/uploads/bots/
📅 Creación: 11-14 Ago 2026  |  Modificado: 17 Ago 2026
📦 Tamaño: 42.4 KB
```
**Estrategia:** Elite Warrior Safe: versión de seguridad del sistema Warrior. SL fijo conservador por equity, límite de posiciones, cierre automático al superar pérdida diaria. Bot de transición entre la línea Warrior clásica y la Scholar actual.

---

## 🗂️ Mapa Completo de Carpetas con Todos los Bots

```
c:\proyectos\APP KOPYTRADING\
│
├── Agosto_2026_Activos\
│   ├── 00_OFICIALES_SEPTIEMBRE\           ← 🟢 ACTIVOS Y EN PRODUCCIÓN
│   │   ├── MAIKO_PRO_GOLD_ORIGINAL_AGOSTO.mq5      (52.9 KB) ✅ EN DEMO
│   │   ├── MAIKO_PRO_GOLD_V11_34_1_RISK.mq5        (81.8 KB) ✅ EN DEMO
│   │   ├── MAIKO_PRO_GOLD_DEMO_V11.33.mq5          (57.7 KB)
│   │   ├── MAIKO_PRO_GOLD_DEMO.mq5                 (46.8 KB)
│   │   ├── MAIKO_PRO_GOLD_DEMO_V11.34_FrancotiradorM5.mq5 (10.4 KB)
│   │   ├── MAIKO_PRO_GOLD_CENT.mq5                 (47.1 KB)
│   │   ├── MAIKO_PRO_GOLD_REAL.mq5                 (53.4 KB)
│   │   └── MAIKO_PERFECT.mq5                       (45.2 KB)
│   │
│   ├── XAUUSD_Elite_Warrior_Safe_V2.mq5            (42.4 KB)
│   ├── XAUUSD_Smart_Hybrid_PRO.mq5                 (38.4 KB)
│   ├── Martingala_Inteligent-v2_PRUEBA.mq5         (35.5 KB)
│   ├── Maiko_Pro_Gold_SHIELD.mq5                   (42.4 KB)
│   └── sniper.mq5                                  (51.8 KB)
│
└── .next\standalone\public\uploads\
    ├── 📁 [raíz] — Versiones activas publicadas
    │   ├── KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.mq5  (28.8 KB)
    │   ├── KOPYTRADE_XAUUSD_GoldSentinelPro.mq5        (18.9 KB)
    │   ├── KOPYTRADE_XAUUSD_TITAN_FIBO_PRO.mq5         (19.7 KB)
    │   ├── KOPYTRADE_XAUUSD_Ametralladora_Evolution.mq5 (29.5 KB)
    │   ├── KOPYTRADE_XAUUSD_Evolution_Universal_v6_10.mq5 (21.7 KB)
    │   └── KOPYTRADE_XAUUSD_EVOLUTION_v8_3_1_TITAN_SHIELD.mq5 (19 KB)
    │
    ├── 📁 LEGACY\ — 🟡 Bots históricos 2025-2026
    │   ├── XAUUSD_AMETRALLADORA_ULTRA_v53_FINAL.mq5  (23.9 KB)
    │   ├── KOPYTRADE_XAU_PRO_CENT.mq5 / USD.mq5     (34.5 KB)
    │   ├── KOPYTRADE_XAUUSD_Evolution_Pro_v5_8.mq5  (33.7 KB)
    │   ├── LA_AMETRALLADORA_v6.0.mq5                (24.8 KB)
    │   ├── AMETRA_ULTRA_CENT_v5.71.mq5              (35 KB)
    │   └── KOPYTRADE_XAUUSD_Ametralladora_*.mq5     (varios)
    │
    ├── 📁 SCALPING\ — 🔵 Scalping EURUSD/XAUUSD
    │   └── EA_Scalping_Inteligente_v43 a v53.mq5    (varios 10-21 KB)
    │
    └── 📁 bots\ — 🟠 Versiones protegidas para clientes
        ├── Elite_Gold_MAIKO_Sniper_v11.30_*.mq5     (89-93 KB)
        ├── MAIKO_PRO_GOLD_CENT_PROTECTED.mq5
        ├── MAIKO_PRO_GOLD_DEMO_PROTECTED.mq5
        └── MAIKO_PRO_GOLD_PROTECTED.mq5
```

---

## 🗓️ Plan de Backtesting Recomendado

```
📌 FASE 1 — Esta semana:
   1. MAIKO_PRO_GOLD_ORIGINAL_AGOSTO  → M5, 2025-2026, Every Tick
   2. MAIKO_PRO_GOLD_DEMO_V11.33     → M5, mismo período, comparativa
   3. MAIKO_PRO_GOLD_V11_34_1_RISK   → Probar en M5 (no M1) + ATR×4.0

📌 FASE 2 — Semana siguiente:
   4. FrancotiradorM5                → M5, backtesting puro sin SOS
   5. Evolution_Pro_v5_84            → Comparativa línea clásica

📌 FASE 3 — Con resultados de Fases 1 y 2:
   6-10. Resto para confirmar o descartar definitivamente
```

> [!TIP]
> Configuración recomendada del Strategy Tester de MT5:
> - **Modelo:** Every Tick (based on real ticks)
> - **Período de datos:** Ene 2025 → Ago 2026
> - **Depósito:** \$1,000 USD
> - **Spread:** usar spread del broker real (o 25 puntos para XAUUSD)
> - **Optimización:** después del primer backtesting base, optimizar ATR, DistanciaRefuerzoPips y LoteAtaque
