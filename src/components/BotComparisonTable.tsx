"use client";

import Link from "next/link";
import { useState } from "react";

const BOTS_DATA = [
    {
        id: "demo-gold",
        name: "MAIKO PRO GOLD DEMO",
        pair: "XAU/USD",
        timeframe: "M5",
        risk: "Bajo",
        minCapital: "$1,000",
        frequency: "Alta (Scalping)",
        amortization: "Demo 30 Días",
        features: [true, true, true, true, true],
        image: "/images/maiko-gold-demo.png",
        color: "from-amber-400 to-amber-600",
        price: "1€"
    },
    {
        id: "ufvg-demo",
        name: "MAIKO UFVG DEMO",
        pair: "XAU/USD",
        timeframe: "M5",
        risk: "Medio",
        minCapital: "N/A",
        frequency: "Media (OR FVG)",
        amortization: "Demo 30 Días",
        features: [true, true, true, true, true],
        image: "/images/maiko-ufvg-demo.png",
        color: "from-purple-400 to-purple-600",
        price: "1€"
    },
    {
        id: "ametralladora",
        name: "MAIKO PRO GOLD",
        pair: "XAU/USD",
        timeframe: "M5",
        risk: "Medio",
        minCapital: "$1,000",
        frequency: "Alta (Scalping)",
        amortization: "~ 2 semanas",
        features: [true, true, true, true, true],
        image: "/images/maiko-gold.png",
        color: "from-amber-400 to-amber-600",
        price: "Próximamente",
        popular: true
    },
    {
        id: "pro-cent",
        name: "MAIKO PRO CENT",
        pair: "CENT",
        timeframe: "M5",
        risk: "Bajo",
        minCapital: "$100",
        frequency: "Media",
        amortization: "~ 8 semanas",
        features: [true, true, true, true, true],
        image: "/images/maiko-cent.png",
        color: "from-slate-400 to-slate-600",
        price: "Próximamente"
    },
    {
        id: "btc-storm",
        name: "MAIKO PRO BTC",
        pair: "BTC/USD",
        timeframe: "M30-H1",
        risk: "Alto",
        minCapital: "$2,000",
        frequency: "Breakout (IA)",
        amortization: "~ 4 semanas",
        features: [true, true, true, true, true],
        image: "/images/maiko-btc.png",
        color: "from-orange-400 to-orange-600",
        price: "Próximamente"
    },
    {
        id: "euro-precision",
        name: "MAIKO EURO PRECISION",
        pair: "EUR/USD",
        timeframe: "H1",
        risk: "Bajo",
        minCapital: "$500",
        frequency: "Baja (1-3 / sem)",
        amortization: "~ 6 semanas",
        features: [true, true, true, true, true],
        image: "/images/maiko-euro.png",
        color: "from-blue-500 to-cyan-500",
        price: "En fabricación"
    },
    {
        id: "ninja-yen",
        name: "MAIKO YEN GHOST",
        pair: "USD/JPY",
        timeframe: "M30",
        risk: "Medio",
        minCapital: "$500",
        frequency: "Media (Noche)",
        amortization: "~ 4 semanas",
        features: [true, true, true, true, true],
        image: "/images/maiko-yen.png",
        color: "from-purple-500 to-indigo-500",
        price: "En fabricación"
    }
];

const FEATURE_LABELS = [
    "Stop Loss Físico Automático",
    "Break Even Dinámico",
    "Filtro de Horario y Noticias",
    "Protección Anti-Drawdown Diario",
    "Stop Loss por Equidad Ajustable"
];

export function BotComparisonTable() {
    const [activeTab, setActiveTab] = useState<string>("all");

    return (
        <div className="w-full relative overflow-guard">
            <div className="md:hidden flex items-center justify-center gap-2 mb-4 text-[10px] text-accent font-bold uppercase tracking-widest animate-pulse">
                <span>←</span> Desliza para comparar <span>→</span>
            </div>
            <div className="w-full overflow-x-auto pb-6 custom-scrollbar">

                <div className="min-w-[800px] w-full glass-card border border-white/10 rounded-2xl overflow-hidden bg-bg-dark">
                    {/* Encabezado */}
                    {/* Encabezado */}
                    <div className="grid grid-cols-7 border-b border-white/10 bg-white/5">
                        <div className="p-4 sm:p-6 text-left m-auto w-full sticky left-0 z-20 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">
                            <h4 className="text-white font-bold text-lg mb-1">Elige tu Bot</h4>
                            <p className="text-xs text-text-muted">Compara características</p>
                        </div>

                        {BOTS_DATA.map((bot) => (
                            <div key={bot.id} className={`p-4 sm:p-6 text-center border-l border-white/5 relative ${bot.popular ? 'bg-brand/10' : ''}`}>
                                {bot.popular && (
                                    <div className="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-brand-light to-brand"></div>
                                )}
                                <div className={`w-16 h-16 mx-auto rounded-full bg-gradient-to-br ${bot.color} flex items-center justify-center shadow-lg mb-3 overflow-hidden border-2 border-white/10 relative group-hover:scale-110 transition-transform duration-500`}>
                                    <img src={bot.image} alt={bot.name} className="w-full h-full object-cover group-hover:brightness-125 transition-all duration-500" />
                                </div>
                                <h4 className="font-bold text-white text-sm sm:text-base leading-tight mb-1">{bot.name}</h4>
                                <p className="text-xs text-brand-light font-mono bg-white/5 inline-block px-2 py-0.5 rounded uppercase">{bot.pair}</p>
                            </div>
                        ))}
                    </div>

                    {/* Filas de Datos */}
                    <div className="divide-y divide-white/5">

                        {/* Riesgo */}
                        <div className="grid grid-cols-7 hover:bg-white/[0.02] transition-colors group">
                            <div className="p-4 text-sm font-semibold text-text-muted flex items-center sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">Nivel de Riesgo</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-4 text-sm font-bold text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                    <span className={`px-2 py-1 rounded-md text-xs ${bot.risk.includes('Bajo') ? 'bg-success/20 text-success' : bot.risk.includes('Alto') ? 'bg-danger/20 text-danger' : 'bg-warning/20 text-warning'}`}>
                                        {bot.risk}
                                    </span>
                                </div>
                            ))}
                        </div>

                        {/* Capital */}
                        <div className="grid grid-cols-7 hover:bg-white/[0.02] transition-colors group">
                            <div className="p-4 text-sm font-semibold text-text-muted flex items-center sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">Capital Mínimo Recomendado</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-4 text-sm font-bold text-white text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                    {bot.minCapital}
                                </div>
                            ))}
                        </div>

                        {/* Temporalidad */}
                        <div className="grid grid-cols-7 hover:bg-white/[0.02] transition-colors group">
                            <div className="p-4 text-sm font-semibold text-text-muted flex items-center sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">Temporalidad Gráfico</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-4 text-sm font-bold text-white text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                    {bot.timeframe}
                                </div>
                            ))}
                        </div>

                        {/* Frecuencia */}
                        <div className="grid grid-cols-7 hover:bg-white/[0.02] transition-colors group">
                            <div className="p-4 text-sm font-semibold text-text-muted flex items-center sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">Frecuencia de Operaciones</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-4 text-xs font-medium text-text-muted text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                    {bot.frequency}
                                </div>
                            ))}
                        </div>

                        {/* Amortización */}
                        <div className="grid grid-cols-7 hover:bg-white/[0.02] transition-colors group">
                            <div className="p-4 text-sm font-semibold text-text-muted flex items-center sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">Amortización Estimada (con 1.000$)</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-4 text-xs font-bold text-success text-center border-l border-white/5 flex items-center justify-center ${bot.popular ? 'bg-brand/5' : ''}`}>
                                    {bot.amortization}
                                </div>
                            ))}
                        </div>

                        {/* Features Ticks */}
                        {FEATURE_LABELS.map((label, fIndex) => (
                            <div key={fIndex} className="grid grid-cols-7 hover:bg-white/[0.02] transition-colors group">
                                <div className="p-4 text-sm font-semibold text-text-muted flex items-center sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">{label}</div>
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
                        <div className="grid grid-cols-7 bg-white/5 group">
                            <div className="p-6 text-sm font-bold text-white flex items-center justify-start sticky left-0 z-10 bg-[#0a0a0a]/95 backdrop-blur-md border-r border-white/10">Estado / Licencia</div>
                            {BOTS_DATA.map((bot, i) => (
                                <div key={i} className={`p-6 text-center border-l border-white/5 flex flex-col justify-end gap-3 rounded-b-2xl ${bot.popular ? 'bg-brand/10 shadow-[inner_0_-10px_20px_rgba(139,92,246,0.1)]' : ''}`}>
                                    {bot.price === "Próximamente" || bot.price === "En fabricación" ? (
                                        <div className="flex flex-col items-center gap-1 w-full overflow-hidden">
                                            <span className="text-xs sm:text-sm font-black text-white/30 uppercase tracking-widest italic text-center leading-tight whitespace-normal">{bot.price}</span>
                                            <span className="text-[8px] font-black text-brand-light/40 uppercase tracking-widest text-center">✦ PRÓXIMA REVELACIÓN</span>
                                        </div>
                                    ) : (
                                        <div className="text-base sm:text-lg font-extrabold text-brand-light/70 italic">{bot.price}</div>
                                    )}
                                    <Link href="/bots" className={`w-full py-2.5 rounded-xl font-bold text-xs sm:text-sm transition-all border ${bot.popular ? 'bg-brand hover:bg-brand-light text-white border-transparent shadow-[0_0_15px_rgba(139,92,246,0.3)] animate-pulse-glow' : 'bg-transparent text-white border-white/20 hover:bg-white/10'}`}>
                                        Ver Detalles
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
