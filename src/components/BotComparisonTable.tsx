"use client";

import Link from "next/link";
import { useState } from "react";

const BOTS_DATA = [
    {
        id: "euro-precision",
        name: "Euro Precision Flow",
        pair: "EUR/USD",
        timeframe: "H1",
        risk: "Bajo",
        minCapital: "$500",
        frequency: "Baja (1-3 / sem)",
        amortization: "~ 6 semanas",
        features: [true, true, true, true],
        icon: "🎯",
        color: "from-blue-500 to-cyan-500",
        price: "179€"
    },
    {
        id: "ninja-yen",
        name: "Yen Ninja Ghost",
        pair: "USD/JPY",
        timeframe: "M30",
        risk: "Medio",
        minCapital: "$500",
        frequency: "Media (Noche)",
        amortization: "~ 4 semanas",
        features: [true, true, true, true],
        icon: "🥷",
        color: "from-purple-500 to-indigo-500",
        price: "77€"
    },
    {
        id: "ametralladora",
        name: "La Ametralladora v5.0",
        pair: "XAU/USD",
        timeframe: "M15",
        risk: "Medio-Alto",
        minCapital: "$1,000",
        frequency: "Muy Alta (Diaria)",
        amortization: "~ 3 semanas",
        features: [true, true, true, true],
        icon: "🔥",
        color: "from-orange-500 to-red-600",
        price: "97€",
        popular: true
    },
    {
        id: "btc-storm",
        name: "BTC Storm Rider v6.0",
        pair: "BTC/USD",
        timeframe: "M30-H4",
        risk: "Alto",
        minCapital: "$2,000",
        frequency: "Ráfagas (Breakout)",
        amortization: "~ 4 semanas",
        features: [true, true, true, true],
        icon: "⚡",
        color: "from-yellow-400 to-orange-500",
        price: "87€"
    }
];

const FEATURE_LABELS = [
    "Stop Loss Físico Automático",
    "Break Even Dinámico",
    "Filtro de Horario y Noticias",
    "Protección Anti-Drawdown Diario"
];

export function BotComparisonTable() {
    const [activeTab, setActiveTab] = useState<string>("all");

    return (
        <div className="w-full relative">
            <div className="md:hidden flex items-center justify-center gap-2 mb-4 text-[10px] text-accent font-bold uppercase tracking-widest animate-pulse">
                <span>←</span> Desliza para comparar <span>→</span>
            </div>
            <div className="w-full overflow-x-auto pb-6 custom-scrollbar">

            <div className="min-w-[800px] w-full glass-card border border-white/10 rounded-2xl overflow-hidden bg-bg-dark">
                {/* Encabezado */}
                <div className="grid grid-cols-5 border-b border-white/10 bg-white/5">
                    <div className="p-4 sm:p-6 text-left m-auto w-full">
                        <h4 className="text-white font-bold text-lg mb-1">Elige tu Bot</h4>
                        <p className="text-xs text-text-muted">Compara características</p>
                    </div>

                    {BOTS_DATA.map((bot) => (
                        <div key={bot.id} className={`p-4 sm:p-6 text-center border-l border-white/5 relative ${bot.popular ? 'bg-brand/10' : ''}`}>
                            {bot.popular && (
                                <div className="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-brand-light to-brand"></div>
                            )}
                            <div className={`w-12 h-12 mx-auto rounded-xl bg-gradient-to-br ${bot.color} flex items-center justify-center text-2xl shadow-lg mb-3`}>
                                {bot.icon}
                            </div>
                            <h4 className="font-bold text-white text-sm sm:text-base leading-tight mb-1">{bot.name}</h4>
                            <p className="text-xs text-brand-light font-mono bg-white/5 inline-block px-2 py-0.5 rounded uppercase">{bot.pair}</p>
                        </div>
                    ))}
                </div>

                {/* Filas de Datos */}
                <div className="divide-y divide-white/5">

                    {/* Riesgo */}
                    <div className="grid grid-cols-5 hover:bg-white/[0.02] transition-colors">
                        <div className="p-4 text-sm font-semibold text-text-muted flex items-center">Nivel de Riesgo</div>
                        {BOTS_DATA.map((bot, i) => (
                            <div key={i} className={`p-4 text-sm font-bold text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                <span className={`px-2 py-1 rounded-md text-xs ${bot.risk.includes('Bajo') ? 'bg-success/20 text-success' : bot.risk.includes('Alto') ? 'bg-danger/20 text-danger' : 'bg-warning/20 text-warning'}`}>
                                    {bot.risk}
                                </span>
                            </div>
                        ))}
                    </div>

                    {/* Capital */}
                    <div className="grid grid-cols-5 hover:bg-white/[0.02] transition-colors">
                        <div className="p-4 text-sm font-semibold text-text-muted flex items-center">Capital Mínimo Recomendado</div>
                        {BOTS_DATA.map((bot, i) => (
                            <div key={i} className={`p-4 text-sm font-bold text-white text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                {bot.minCapital}
                            </div>
                        ))}
                    </div>

                    {/* Temporalidad */}
                    <div className="grid grid-cols-5 hover:bg-white/[0.02] transition-colors">
                        <div className="p-4 text-sm font-semibold text-text-muted flex items-center">Temporalidad Gráfico</div>
                        {BOTS_DATA.map((bot, i) => (
                            <div key={i} className={`p-4 text-sm font-bold text-white text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                {bot.timeframe}
                            </div>
                        ))}
                    </div>

                    {/* Frecuencia */}
                    <div className="grid grid-cols-5 hover:bg-white/[0.02] transition-colors">
                        <div className="p-4 text-sm font-semibold text-text-muted flex items-center">Frecuencia de Operaciones</div>
                        {BOTS_DATA.map((bot, i) => (
                            <div key={i} className={`p-4 text-xs font-medium text-text-muted text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                {bot.frequency}
                            </div>
                        ))}
                    </div>

                    {/* Amortización */}
                    <div className="grid grid-cols-5 hover:bg-white/[0.02] transition-colors">
                        <div className="p-4 text-sm font-semibold text-text-muted flex items-center">Amortización Estimada (con 1.000$)</div>
                        {BOTS_DATA.map((bot, i) => (
                            <div key={i} className={`p-4 text-xs font-bold text-success text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                {bot.amortization}
                            </div>
                        ))}
                    </div>

                    {/* Features Ticks */}
                    {FEATURE_LABELS.map((label, fIndex) => (
                        <div key={fIndex} className="grid grid-cols-5 hover:bg-white/[0.02] transition-colors">
                            <div className="p-4 text-sm font-semibold text-text-muted flex items-center">{label}</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-4 text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                    {bot.features[fIndex] ? (
                                        <span className="text-success text-xl drop-shadow-[0_0_5px_rgba(34,197,94,0.5)]">✓</span>
                                    ) : (
                                        <span className="text-text-muted/30 text-sm">--</span>
                                    )}
                                </div>
                            ))}
                        </div>
                    ))}

                    {/* Fila Precios / Botones */}
                    <div className="grid grid-cols-5 bg-white/5">
                        <div className="p-6 text-sm font-bold text-white flex items-center justify-start">Licencia de por vida</div>
                        {BOTS_DATA.map((bot, i) => (
                            <div key={i} className={`p-6 text-center border-l border-white/5 flex flex-col justify-end gap-3 rounded-b-2xl ${bot.popular ? 'bg-brand/10 shadow-[inner_0_-10px_20px_rgba(139,92,246,0.1)]' : ''}`}>
                                <div className="text-xl sm:text-2xl font-extrabold text-white">{bot.price}</div>
                                <Link href="/bots" className={`w-full py-2.5 rounded-xl font-bold text-xs sm:text-sm transition-all border ${bot.popular ? 'bg-brand hover:bg-brand-light text-white border-transparent shadow-[0_0_15px_rgba(139,92,246,0.3)] animate-pulse-glow' : 'bg-transparent text-white border-white/20 hover:bg-white/10'}`}>
                                    Descargar
                                </Link>
                            </div>
                        ))}
                    </div>

                </div>
            </div>
            </div>
        </div>

    );
}
