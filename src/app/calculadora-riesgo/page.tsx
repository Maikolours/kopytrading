"use client";

import { useState, useId } from "react";
import Link from "next/link";
import Script from "next/script";

interface SymbolConfig {
  name: string;
  symbol: string;
  contractSize: number; // units per lot
  pointValue: number;   // point value multiplier
  defaultPip: number;   // standard stop loss default
  description: string;
}

const SYMBOLS: Record<string, SymbolConfig> = {
  XAUUSD: {
    name: "Oro (XAUUSD)",
    symbol: "XAUUSD",
    contractSize: 100, // 1 lot = 100 oz
    pointValue: 1,      // $1 per $1 move for 1 lot (100 oz * $0.01 = $1/point)
    defaultPip: 50,     // 50 pips ($5.00 move)
    description: "Contrato estándar de 100 onzas troy. 1 lote = $100 por cada $1.00 de movimiento."
  },
  BTCUSD: {
    name: "Bitcoin (BTCUSD)",
    symbol: "BTCUSD",
    contractSize: 1,    // 1 lot = 1 BTC
    pointValue: 1,      // 1 lot * $1 move = $1
    defaultPip: 500,    // $500 move
    description: "Contrato estándar de 1 BTC. 1 lote = $1 por cada $1.00 de movimiento en el precio."
  },
  EURUSD: {
    name: "Euro / Dólar (EURUSD)",
    symbol: "EURUSD",
    contractSize: 100000,
    pointValue: 10,     // $10 per pip for 1 lot
    defaultPip: 25,
    description: "Contrato estándar de 100,000 EUR. 1 lote = $10 por pip (0.0001)."
  },
  GBPUSD: {
    name: "Libra / Dólar (GBPUSD)",
    symbol: "GBPUSD",
    contractSize: 100000,
    pointValue: 10,
    defaultPip: 30,
    description: "Contrato estándar de 100,000 GBP. 1 lote = $10 por pip (0.0001)."
  },
  USDJPY: {
    name: "Dólar / Yen (USDJPY)",
    symbol: "USDJPY",
    contractSize: 100000,
    pointValue: 6.7,    // approx USD per pip
    defaultPip: 30,
    description: "Contrato estándar de 100,000 USD. Valor del pip ajustado a la tasa del Yen."
  }
};

export default function CalculadoraRiesgoPage() {
  const [symbolKey, setSymbolKey] = useState<string>("XAUUSD");
  const [balance, setBalance] = useState<number>(1000);
  const [riskPercent, setRiskPercent] = useState<number>(1.5);
  const [stopLossPips, setStopLossPips] = useState<number>(50);
  const [leverage, setLeverage] = useState<number>(100);

  const currentSymbol = SYMBOLS[symbolKey];

  // Calculation logic
  const riskAmount = (balance * riskPercent) / 100;
  
  // Lot calculation:
  // For XAUUSD: Risk ($) / (StopLossPips * 10 * ($1/10 pips)) => Risk / (SL_points * point_val)
  let lotSize = 0.01;
  let pipValueForOneLot = 10; // default for 1 lot standard pip

  if (symbolKey === "XAUUSD") {
    // 1 pip in Gold = $0.10 move ($1.00 move = 10 pips).
    // 1 lot (100 oz) * $0.10 move = $10 per pip.
    pipValueForOneLot = 10;
    const lossPerLot = stopLossPips * pipValueForOneLot;
    if (lossPerLot > 0) {
      lotSize = riskAmount / lossPerLot;
    }
  } else if (symbolKey === "BTCUSD") {
    // 1 pip/point in BTC = $1.00 move.
    // 1 lot (1 BTC) * $1.00 move = $1.
    pipValueForOneLot = 1;
    const lossPerLot = stopLossPips * pipValueForOneLot;
    if (lossPerLot > 0) {
      lotSize = riskAmount / lossPerLot;
    }
  } else if (symbolKey === "EURUSD" || symbolKey === "GBPUSD") {
    // 1 pip = 0.0001 = $10 for 1 lot (100k)
    pipValueForOneLot = 10;
    const lossPerLot = stopLossPips * pipValueForOneLot;
    if (lossPerLot > 0) {
      lotSize = riskAmount / lossPerLot;
    }
  } else if (symbolKey === "USDJPY") {
    // 1 pip = 0.01 = approx $6.70 for 1 lot
    pipValueForOneLot = 6.7;
    const lossPerLot = stopLossPips * pipValueForOneLot;
    if (lossPerLot > 0) {
      lotSize = riskAmount / lossPerLot;
    }
  }

  // Normalize MT5 lot size step (0.01 minimum, 2 decimals)
  const normalizedLotSize = Math.max(0.01, Math.floor(lotSize * 100) / 100);
  const actualRiskAmount = normalizedLotSize * stopLossPips * pipValueForOneLot;
  const actualRiskPercent = balance > 0 ? (actualRiskAmount / balance) * 100 : 0;
  const requiredMargin = (normalizedLotSize * currentSymbol.contractSize * 2000) / leverage; // approx margin

  // FAQ Schema JSON-LD
  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {
        "@type": "Question",
        "name": "¿Cómo se calcula el lotaje exacto para MetaTrader 5 (MT5)?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "El lotaje se calcula dividiendo la cantidad máxima de capital que estás dispuesto a arriesgar (en USD o EUR) entre el resultado de multiplicar la distancia de tu Stop Loss en pips por el valor por pip de 1 lote completo para el activo seleccionado."
        }
      },
      {
        "@type": "Question",
        "name": "¿Cuál es el valor del pip para el Oro (XAUUSD) en MT5?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "En una cuenta estándar con contrato de 100 onzas, 1 lote completo de XAUUSD equivale a $10 USD por cada 10 pips (o $1.00 de variación en el precio del oro). Con un microlote de 0.01, 1 pip de movimiento representa $0.10 USD."
        }
      },
      {
        "@type": "Question",
        "name": "¿Por qué es fundamental calcular el lote antes de ejecutar un bot o EA?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Configurar un tamaño de lote adecuado a tu balance previene caídas drásticas de capital (drawdown) durante rachas desfavorables del mercado y asegura que el algoritmo opere dentro de los límites de riesgo de tu cuenta."
        }
      }
    ]
  };

  const appSchema = {
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "Calculadora de Riesgo y Lote MetaTrader 5 (MT5)",
    "operatingSystem": "All",
    "applicationCategory": "FinanceApplication",
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "USD"
    },
    "description": "Herramienta gratuita para calcular el lotaje exacto, volumen y riesgo por operación en MetaTrader 5 para XAUUSD, BTCUSD y Forex."
  };

  return (
    <>
      <Script
        id="faq-schema-calculator"
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <Script
        id="app-schema-calculator"
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(appSchema) }}
      />

      <div className="min-h-screen pt-24 md:pt-28 pb-16 bg-[#060913] text-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          
          {/* Header */}
          <div className="text-center max-w-3xl mx-auto mb-10">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-brand/10 border border-brand/30 text-brand-light text-xs font-bold uppercase tracking-widest mb-4">
              <span className="w-2 h-2 rounded-full bg-brand animate-pulse" />
              Herramienta Profesional MT5
            </div>
            <h1 className="text-3xl sm:text-5xl font-black uppercase tracking-tight text-white mb-4">
              Calculadora de <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-light to-accent">Riesgo y Lotaje MT5</span>
            </h1>
            <p className="text-sm sm:text-base text-text-muted leading-relaxed">
              Determina el tamaño exacto de lote (lote estándar, mini o micro) para MetaTrader 5 según el balance de tu cuenta, tu porcentaje de tolerancia al riesgo y la distancia de Stop Loss.
            </p>
          </div>

          {/* Grid: Calculator + Result Display */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start mb-16">
            
            {/* Form Side */}
            <div className="lg:col-span-7 bg-black/60 border border-white/10 rounded-2xl p-6 sm:p-8 backdrop-blur-xl shadow-2xl">
              <h2 className="text-lg font-bold uppercase tracking-wider text-white mb-6 flex items-center gap-2">
                <svg className="w-5 h-5 text-brand-light" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
                </svg>
                Parámetros de la Operación
              </h2>

              <div className="space-y-5">
                {/* Symbol Select */}
                <div>
                  <label htmlFor="symbol-select" className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
                    Activo / Par de Divisas
                  </label>
                  <select
                    id="symbol-select"
                    value={symbolKey}
                    onChange={(e) => {
                      setSymbolKey(e.target.value);
                      setStopLossPips(SYMBOLS[e.target.value].defaultPip);
                    }}
                    className="w-full bg-[#0d1222] border border-white/15 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-brand-light transition-all"
                  >
                    {Object.keys(SYMBOLS).map((key) => (
                      <option key={key} value={key} className="bg-[#0d1222] text-white">
                        {SYMBOLS[key].name}
                      </option>
                    ))}
                  </select>
                  <p className="text-[11px] text-text-muted mt-1.5">{currentSymbol.description}</p>
                </div>

                {/* Account Balance */}
                <div>
                  <label htmlFor="balance-input" className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
                    Balance de Cuenta ($ USD)
                  </label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted font-bold text-sm">$</span>
                    <input
                      id="balance-input"
                      type="number"
                      min="10"
                      step="50"
                      value={balance}
                      onChange={(e) => setBalance(Math.max(0, parseFloat(e.target.value) || 0))}
                      className="w-full bg-[#0d1222] border border-white/15 rounded-xl pl-9 pr-4 py-3 text-sm text-white font-mono focus:outline-none focus:border-brand-light transition-all"
                    />
                  </div>
                </div>

                {/* Risk Percent */}
                <div>
                  <div className="flex justify-between items-center mb-2">
                    <label htmlFor="risk-percent-input" className="text-xs font-bold text-text-muted uppercase tracking-wider">
                      Porcentaje de Riesgo Máximo
                    </label>
                    <span className="text-xs font-mono font-bold text-brand-light">{riskPercent}% (${riskAmount.toFixed(2)})</span>
                  </div>
                  <input
                    id="risk-percent-input"
                    type="range"
                    min="0.1"
                    max="10"
                    step="0.1"
                    value={riskPercent}
                    onChange={(e) => setRiskPercent(parseFloat(e.target.value))}
                    className="w-full accent-brand cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] text-text-muted mt-1">
                    <span>Conservador (0.5%)</span>
                    <span>Moderado (1.5%)</span>
                    <span>Alto (3.0%+)</span>
                  </div>
                </div>

                {/* Stop Loss Pips */}
                <div>
                  <label htmlFor="stop-loss-input" className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
                    Distancia de Stop Loss (Pips / Puntos)
                  </label>
                  <input
                    id="stop-loss-input"
                    type="number"
                    min="1"
                    step="1"
                    value={stopLossPips}
                    onChange={(e) => setStopLossPips(Math.max(1, parseFloat(e.target.value) || 1))}
                    className="w-full bg-[#0d1222] border border-white/15 rounded-xl px-4 py-3 text-sm text-white font-mono focus:outline-none focus:border-brand-light transition-all"
                  />
                  <p className="text-[11px] text-text-muted mt-1">
                    En XAUUSD: 10 pips = $1.00 de diferencia en precio. En BTCUSD: 100 pips = $100.
                  </p>
                </div>

                {/* Leverage Select */}
                <div>
                  <label htmlFor="leverage-select" className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
                    Apalancamiento de Cuenta
                  </label>
                  <select
                    id="leverage-select"
                    value={leverage}
                    onChange={(e) => setLeverage(parseInt(e.target.value))}
                    className="w-full bg-[#0d1222] border border-white/15 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-brand-light transition-all"
                  >
                    <option value={50}>1:50</option>
                    <option value={100}>1:100 (Estándar)</option>
                    <option value={200}>1:200</option>
                    <option value={500}>1:500</option>
                  </select>
                </div>

              </div>
            </div>

            {/* Results Display Side */}
            <div className="lg:col-span-5 space-y-6">
              <div className="bg-gradient-to-br from-[#120a2a] via-[#0d1222] to-black border border-brand/30 rounded-2xl p-6 sm:p-8 shadow-2xl relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-brand/10 rounded-full blur-3xl pointer-events-none" />
                
                <h3 className="text-xs font-black uppercase tracking-widest text-brand-light mb-6">
                  Resultado Sugerido para MT5
                </h3>

                {/* Primary Metric: Lot Size */}
                <div className="bg-black/50 border border-white/10 rounded-xl p-5 mb-5 text-center">
                  <span className="text-xs text-text-muted uppercase tracking-wider font-bold block mb-1">
                    Lote a Introducir en MT5
                  </span>
                  <span className="text-4xl sm:text-5xl font-black font-mono text-white tracking-tight">
                    {normalizedLotSize.toFixed(2)}
                  </span>
                  <span className="text-xs text-brand-light block font-semibold mt-2">
                    {normalizedLotSize === 0.01 ? "Microlote Mínimo (0.01)" : `${normalizedLotSize} Lotes Estándar`}
                  </span>
                </div>

                {/* Details list */}
                <div className="space-y-3 text-xs">
                  <div className="flex justify-between items-center py-2 border-b border-white/5">
                    <span className="text-text-muted">Capital Máximo Expuesto:</span>
                    <span className="font-mono font-bold text-white">${actualRiskAmount.toFixed(2)} USD ({actualRiskPercent.toFixed(2)}%)</span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b border-white/5">
                    <span className="text-text-muted">Valor por Pip (con {normalizedLotSize.toFixed(2)} lotes):</span>
                    <span className="font-mono font-bold text-white">${(pipValueForOneLot * normalizedLotSize).toFixed(2)} USD</span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b border-white/5">
                    <span className="text-text-muted">Distancia Stop Loss:</span>
                    <span className="font-mono font-bold text-white">{stopLossPips} pips</span>
                  </div>
                  <div className="flex justify-between items-center py-2">
                    <span className="text-text-muted">Margen Estimado Requerido:</span>
                    <span className="font-mono font-bold text-accent">${requiredMargin.toFixed(2)} USD</span>
                  </div>
                </div>

                <div className="mt-6 pt-5 border-t border-white/10">
                  <Link href="/bots">
                    <button className="w-full bg-brand hover:bg-brand-light text-white font-bold py-3.5 px-4 rounded-xl text-xs uppercase tracking-wider transition-all shadow-lg shadow-brand/25 cursor-pointer">
                      Ver Bots Configurados con este Riesgo →
                    </button>
                  </Link>
                </div>
              </div>

              {/* Quick tip box */}
              <div className="bg-black/40 border border-white/10 rounded-2xl p-5 text-xs text-text-muted leading-relaxed">
                <p className="font-bold text-white mb-1 flex items-center gap-1.5">
                  <svg className="w-4 h-4 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Regla de Preservación de Capital
                </p>
                Mantener un porcentaje de riesgo entre el 0.5% y el 2.0% por operación protege tu cuenta contra rachas de fluctuación del mercado y previene fluctuaciones excesivas de saldo.
              </div>

            </div>

          </div>

          {/* Educational Content Section for SEO & AdSense */}
          <div className="max-w-4xl mx-auto space-y-12 border-t border-white/10 pt-12">
            
            <article className="prose prose-invert max-w-none">
              <h2 className="text-2xl font-bold text-white mb-4">
                Guía Completa de Cálculo de Lotaje y Gestión de Riesgo en MetaTrader 5
              </h2>
              <p className="text-text-muted leading-relaxed text-sm">
                En el trading algorítmico y manual en MetaTrader 5 (MT5), el tamaño de la posición (medido en lotes) es la variable más determinante para la longevidad del capital de trabajo. Un error de cálculo en el volumen de entrada puede amplificar innecesariamente la exposición durante momentos de volatilidad macroeconómica.
              </p>

              <h3 className="text-xl font-bold text-white mt-8 mb-3">
                1. ¿Cómo Funciona la Fórmula de Lote en MetaTrader 5?
              </h3>
              <p className="text-text-muted leading-relaxed text-sm">
                La fórmula fundamental utilizada por los gestores de riesgo y algoritmos automatizados es:
              </p>
              
              <div className="bg-[#0d1222] border border-brand/30 rounded-xl p-4 my-4 font-mono text-xs text-brand-light overflow-x-auto">
                Lote = Capital a Arriesgar ($) / ( Stop Loss en Pips × Valor por Pip de 1 Lote )
              </div>

              <p className="text-text-muted leading-relaxed text-sm">
                Donde el <strong>Capital a Arriesgar</strong> representa el monto monetario límite por operación. Por ejemplo, en una cuenta de $1,000 USD con una política del 1.5% de riesgo, el capital expuesto es exactamente $15.00 USD.
              </p>

              <h3 className="text-xl font-bold text-white mt-8 mb-3">
                2. Especificaciones de Contrato según el Activo
              </h3>
              <div className="overflow-x-auto my-6">
                <table className="w-full text-xs text-left border-collapse border border-white/10">
                  <thead>
                    <tr className="bg-[#0d1222] text-white font-bold border-b border-white/10">
                      <th className="p-3 border-r border-white/10">Activo</th>
                      <th className="p-3 border-r border-white/10">Tamaño de Lote Estándar</th>
                      <th className="p-3 border-r border-white/10">Valor por Pip (1 Lote)</th>
                      <th className="p-3">Lote Mínimo MT5</th>
                    </tr>
                  </thead>
                  <tbody className="text-text-muted divide-y divide-white/5">
                    <tr>
                      <td className="p-3 font-bold text-white border-r border-white/10">Oro (XAUUSD)</td>
                      <td className="p-3 border-r border-white/10">100 Onzas Troy</td>
                      <td className="p-3 border-r border-white/10">$10.00 USD / pip ($1/punto)</td>
                      <td className="p-3">0.01 ($0.10 / pip)</td>
                    </tr>
                    <tr>
                      <td className="p-3 font-bold text-white border-r border-white/10">Bitcoin (BTCUSD)</td>
                      <td className="p-3 border-r border-white/10">1 BTC</td>
                      <td className="p-3 border-r border-white/10">$1.00 USD por $1 de cambio</td>
                      <td className="p-3">0.01</td>
                    </tr>
                    <tr>
                      <td className="p-3 font-bold text-white border-r border-white/10">EURUSD / GBPUSD</td>
                      <td className="p-3 border-r border-white/10">100,000 Unidades</td>
                      <td className="p-3 border-r border-white/10">$10.00 USD / pip</td>
                      <td className="p-3">0.01 ($0.10 / pip)</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <h3 className="text-xl font-bold text-white mt-8 mb-3">
                3. Integración con Robots de Trading y Expert Advisors (EAs)
              </h3>
              <p className="text-text-muted leading-relaxed text-sm">
                Al utilizar nuestros robots en MetaTrader 5 (como <em>MAIKO PRO GOLD</em> o <em>MAIKO YEN GHOST</em>), el parámetro de <code>LotSize</code> se ajusta automáticamente o manualmente respetando los valores generados por esta calculadora. Esto evita que el bot abra posiciones desproporcionadas cuando se presentan aperturas de mercado con alta volatilidad.
              </p>
            </article>

            {/* FAQ Section */}
            <div className="bg-black/40 border border-white/10 rounded-2xl p-6 sm:p-8">
              <h3 className="text-xl font-bold text-white mb-6 uppercase tracking-wider">
                Preguntas Frecuentes sobre el Cálculo de Lote
              </h3>

              <div className="space-y-6 text-sm">
                <div>
                  <h4 className="font-bold text-white mb-2">
                    ¿Qué sucede si mi balance es menor a $100 USD?
                  </h4>
                  <p className="text-text-muted leading-relaxed text-xs">
                    Para cuentas con saldos reducidos, se recomienda operar en cuentas de tipo CENT (donde 1 lote estándar equivale a 1,000 unidades) o utilizar exclusivamente la fracción mínima de 0.01 lotes con distancias amplias de Stop Loss.
                  </p>
                </div>

                <div>
                  <h4 className="font-bold text-white mb-2">
                    ¿El apalancamiento cambia el valor del pip?
                  </h4>
                  <p className="text-text-muted leading-relaxed text-xs">
                    No. El apalancamiento únicamente modifica el margen requerido que el broker congela temporalmente para abrir la posición. El valor del pip y el capital expuesto dependen exclusivamente del volumen en lotes y de la distancia en pips del Stop Loss.
                  </p>
                </div>

                <div>
                  <h4 className="font-bold text-white mb-2">
                    ¿Cómo aplico estos resultados en la plataforma MetaTrader 5?
                  </h4>
                  <p className="text-text-muted leading-relaxed text-xs">
                    En la ventana de órdenes de MT5 (tecla F9), introduce el número exacto mostrado en la casilla &quot;Lote a Introducir en MT5&quot; en el campo &quot;Volumen&quot; antes de hacer clic en Comprar o Vender.
                  </p>
                </div>
              </div>
            </div>

            {/* Risk Disclaimer */}
            <div className="p-4 rounded-xl bg-danger/10 border border-danger/30 text-[11px] text-text-muted leading-relaxed">
              <strong className="text-white block mb-1">Aviso de Riesgo y Descargo de Responsabilidad:</strong>
              Los cálculos provistos por esta herramienta son de carácter puramente informativo e ilustrativo. La ejecución de operaciones en plataformas de trading algorítmico conlleva un alto riesgo de fluctuación de saldo. KopyTrading no garantiza resultados específicos ni se hace responsable por decisiones tomadas a partir de estos cómputos.
            </div>

          </div>

        </div>
      </div>
    </>
  );
}
