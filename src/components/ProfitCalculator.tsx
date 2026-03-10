"use client";

import { useState, useEffect } from "react";

export function ProfitCalculator() {
    const [initialCapital, setInitialCapital] = useState(1000);
    const [months, setMonths] = useState(6);
    const [winRate, setWinRate] = useState(4); // 4% monthly avg
    const [finalValue, setFinalValue] = useState(0);

    useEffect(() => {
        // Rendimiento compuesto = Capital * (1 + rate/100)^meses
        const result = initialCapital * Math.pow(1 + winRate / 100, months);
        setFinalValue(result);
    }, [initialCapital, months, winRate]);

    return (
        <div className="w-full max-w-4xl mx-auto glass-card border border-white/10 rounded-3xl p-6 sm:p-10 relative overflow-hidden">
            {/* Background elements */}
            <div className="absolute top-0 right-0 w-[300px] h-[300px] bg-brand/10 blur-[100px] rounded-full pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-[200px] h-[200px] bg-success/10 blur-[80px] rounded-full pointer-events-none" />

            <div className="grid md:grid-cols-2 gap-10 items-center relative z-10">

                {/* Controles del Simulador */}
                <div className="space-y-8">
                    <div>
                        <h3 className="text-2xl font-bold text-white mb-2 flex items-center gap-2">
                            <span className="text-brand-light">🧮</span> Simulador de Interés Compuesto
                        </h3>
                        <p className="text-text-muted text-sm">Descubre el poder matemático del trading algorítmico a medio y largo plazo.</p>
                    </div>

                    <div className="space-y-6">
                        {/* Capital Inicial */}
                        <div className="space-y-3">
                            <div className="flex justify-between">
                                <label className="text-sm font-semibold text-white">Capital Inicial</label>
                                <span className="text-sm font-bold text-success">${initialCapital.toLocaleString()}</span>
                            </div>
                            <input
                                type="range"
                                min="500" max="10000" step="100"
                                value={initialCapital}
                                onChange={(e) => setInitialCapital(Number(e.target.value))}
                                className="w-full accent-brand-light h-2 bg-white/10 rounded-lg appearance-none cursor-pointer"
                            />
                            <div className="flex justify-between text-[10px] text-text-muted">
                                <span>$500</span>
                                <span>$10,000+</span>
                            </div>
                        </div>

                        {/* Meses */}
                        <div className="space-y-3">
                            <div className="flex justify-between">
                                <label className="text-sm font-semibold text-white">Tiempo de Inversión</label>
                                <span className="text-sm font-bold text-white">{months} meses</span>
                            </div>
                            <input
                                type="range"
                                min="1" max="24" step="1"
                                value={months}
                                onChange={(e) => setMonths(Number(e.target.value))}
                                className="w-full accent-brand-light h-2 bg-white/10 rounded-lg appearance-none cursor-pointer"
                            />
                            <div className="flex justify-between text-[10px] text-text-muted">
                                <span>1 mes</span>
                                <span>2 años</span>
                            </div>
                        </div>

                        {/* % Mensual */}
                        <div className="space-y-3">
                            <div className="flex justify-between">
                                <label className="text-sm font-semibold text-white">Beneficio Mensual Estimado</label>
                                <span className="text-sm font-bold text-white">{winRate}%</span>
                            </div>
                            <input
                                type="range"
                                min="2" max="15" step="1"
                                value={winRate}
                                onChange={(e) => setWinRate(Number(e.target.value))}
                                className="w-full accent-brand-light h-2 bg-white/10 rounded-lg appearance-none cursor-pointer"
                            />
                            <div className="flex justify-between text-[10px] text-text-muted">
                                <span>Conservador (2%)</span>
                                <span>Agresivo (15%)</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Resultado Dashboard */}
                <div className="bg-bg-dark border border-white/5 rounded-2xl p-6 md:p-8 flex flex-col justify-center shadow-xl relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-brand/20 to-transparent blur-[30px] rounded-full pointer-events-none" />

                    <div className="text-center space-y-2 mb-8 relative z-10">
                        <p className="text-sm text-text-muted font-medium">Proyección de Capital Final</p>
                        <div className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-b from-white to-gray-400 drop-shadow-sm truncate">
                            ${finalValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </div>
                        <div className="inline-flex items-center gap-2 mt-2 bg-success/20 border border-success/30 px-3 py-1 rounded-full text-success text-sm font-bold">
                            + ${(finalValue - initialCapital).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })} beneficio
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4 border-t border-white/5 pt-6 relative z-10">
                        <div>
                            <p className="text-xs text-text-muted mb-1">Crecimiento Total</p>
                            <p className="text-lg font-bold text-white">+{((finalValue / initialCapital - 1) * 100).toFixed(1)}%</p>
                        </div>
                        <div>
                            <p className="text-xs text-text-muted mb-1">Rendimiento Anualizado</p>
                            <p className="text-lg font-bold text-brand-light">+{((Math.pow(1 + winRate / 100, 12) - 1) * 100).toFixed(0)}%</p>
                        </div>
                    </div>

                    <p className="text-[10px] text-text-muted/60 mt-8 leading-tight italic text-center">
                        *Esta es una simulación matemática del interés compuesto. En el trading real existirán meses en negativo (Drawdowns). Rendimientos pasados no garantizan resultados futuros.
                    </p>
                </div>

            </div>
        </div>
    );
}
