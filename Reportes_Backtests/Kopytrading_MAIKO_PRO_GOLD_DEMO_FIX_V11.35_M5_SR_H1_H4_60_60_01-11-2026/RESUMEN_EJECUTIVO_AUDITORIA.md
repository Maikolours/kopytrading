# Auditoría Backtest: MAIKO PRO GOLD DEMO FIX V11.35 (M5 | S/R H1: 60 / H4: 60)

- **Bot:** `MAIKO_PRO_GOLD_DEMO_FIX_V11.35` (y equivalente `MAIKO_PRO_GOLD_CLIENT_DEMO_FIX` / `REAL_FIX`)
- **Activo y Temporalidad:** `XAUUSD-VIP` (Oro) en **M5**
- **Calidad del Historial:** **100%** (58.837 barras / 1.174.804 ticks)
- **Depósito Inicial:** `$1,000.00` (Apalancamiento `1:500`)
- **Configuración Destacada:**
  - Filtro S/R M15: `15.0 pips` (24 velas)
  - Filtro S/R H1: **`60.0 pips`** (24 velas)
  - Filtro S/R H4: **`60.0 pips`** (24 velas)
  - Agotamiento Mecha M15: `40.0%` | Confirmación Ruptura: `M5`
  - Sincronía Tendencia: `CheckM15 = true`, `CheckM5 = true` (EMA 50)
  - RSI: `70.0 / 30.0`
  - Bloqueos Quirúrgicos: Jueves `01:00-07:00`, Miércoles Macro EE.UU. `14:00-17:00`, Viernes NFP `14:00-17:00`
  - Cierre Preventivo Viernes: `21:00` (`CerrarTodoViernesCierre = true`)
  - Stop Loss de Emergencia: `15.0%` + Pausa `120 min`

---

## 📊 Métricas Principales del Backtest

| Métrica | Resultado | Valoración Institucional |
| :--- | :--- | :--- |
| **Beneficio Neto** | **`+$5,183.58`** (+518.36%) | Sobresaliente (multiplica la cuenta x6.18) |
| **Balance Final** | **`$6,183.58`** | Crecimiento sostenido desde `$1,000.00` |
| **Beneficio Bruto / Pérdida Bruta** | `+$9,059.89` / `-$3,876.31` | Relación ganancia/pérdida muy sólida |
| **Factor de Beneficio (Profit Factor)** | **`2.34`** | Excelente (> 2.0 es grado institucional) |
| **Factor de Recuperación** | **`7.90`** | Capacidad de recuperación rapidísima tras cierres |
| **Ratio de Sharpe** | **`7.57`** | Retorno ajustado al riesgo extraordinario |
| **Correlación Lineal (LR Correlation)** | **`0.98`** | Curva de capital casi perfectamente recta (sobre 1.00) |
| **Drawdown Máximo de Equidad** | **`11.80%`** (`$655.96`) | Muy contenido gracias al escudo del 15% y cierre viernes |
| **Total de Operaciones** | **`5,130`** (`10,260` transacciones) | Muestra estadística masiva y fiable |
| **Tasa de Acierto Total (Win Rate)** | **`96.73%`** (`4,962` ganadas) | Cortos: `96.58%` \| Largos: `96.84%` |
| **Operaciones No Rentables** | Solo `168` (`3.27%`) | Casi todas concentradas en el cierre preventivo de los viernes a las 21:00 |
| **Tiempo Medio de Retención** | `43 minutos y 11 segundos` | Operativa intradía ágil, sin quedarse atrapado semanas |
