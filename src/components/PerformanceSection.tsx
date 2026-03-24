"use client";

import { useState, useEffect, useMemo } from "react";
import { Card, CardHeader, CardContent, CardTitle } from "./ui/Card";
import { Loader2, TrendingUp, TrendingDown, Calendar as CalendarIcon } from "lucide-react";

interface PerformanceSectionProps {
    purchaseId?: string;
    botName?: string;
    purchases?: any[];
}

export function PerformanceSection({ purchaseId: initialPurchaseId, botName: initialBotName, purchases = [] }: PerformanceSectionProps) {
    const [data, setData] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState("ALL"); // ALL, 30, 7
    const [selectedPurchaseId, setSelectedPurchaseId] = useState(initialPurchaseId || "");
    const [isCentAccount, setIsCentAccount] = useState(false);

    useEffect(() => {
        const fetchData = async () => {
            setLoading(true);
            try {
                const url = `/api/dashboard/performance${selectedPurchaseId ? `?purchaseId=${selectedPurchaseId}` : ''}`;
                const res = await fetch(url);
                const json = await res.json();
                if (json.dailyData) setData(json.dailyData);
            } catch (e) {
                console.error("Error fetching performance:", e);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, [selectedPurchaseId]);

    const filteredData = useMemo(() => {
        if (filter === "ALL") return data;
        const days = parseInt(filter);
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - days);
        return data.filter(d => new Date(d.date) >= cutoff);
    }, [data, filter]);

    const totalProfit = useMemo(() => {
        const raw = filteredData.reduce((acc, d) => acc + d.profit, 0);
        return isCentAccount ? raw / 100 : raw;
    }, [filteredData, isCentAccount]);

    const maxProfit = useMemo(() => {
        const values = data.map(d => Math.abs(d.profit));
        const max = Math.max(...values, 1);
        return isCentAccount ? max / 100 : max;
    }, [data, isCentAccount]);

    const selectedBotDetails = useMemo(() => {
        return purchases.find(p => p.id === selectedPurchaseId);
    }, [purchases, selectedPurchaseId]);

    if (loading) {
        return (
            <div className="flex items-center justify-center p-12">
                <Loader2 className="w-8 h-8 animate-spin text-brand-light" />
                <span className="ml-3 text-text-muted">Cargando histórico...</span>
            </div>
        );
    }

    if (data.length === 0) {
        return (
            <div className="glass-card p-12 text-center border border-dashed border-white/10 rounded-2xl">
                <CalendarIcon className="w-12 h-12 mx-auto mb-4 text-white/20" />
                <h3 className="text-lg font-bold text-white mb-2">Sin Historial de Trades</h3>
                <p className="text-text-muted">Cuando tus bots comiencen a cerrar operaciones, aparecerán aquí.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex flex-col gap-1">
                    <h3 className="text-xl font-black text-white tracking-widest uppercase">
                        Rendimiento {selectedBotDetails ? `: ${selectedBotDetails.botProduct.name}` : '(Global)'}
                    </h3>
                    {purchases.length > 0 && (
                        <select 
                            value={selectedPurchaseId}
                            onChange={(e) => setSelectedPurchaseId(e.target.value)}
                            className="bg-black/40 border border-white/10 rounded-lg px-2 py-1 text-[10px] font-bold text-white/60 focus:outline-none focus:border-brand-light transition-colors"
                        >
                            <option value="">TODOS LOS BOTS</option>
                            {purchases.map(p => (
                                <option key={p.id} value={p.id}>{p.botProduct.name} - {p.id.slice(-6)}</option>
                            ))}
                        </select>
                    )}
                </div>
                
                <div className="flex flex-wrap items-center gap-3">
                    <button
                        onClick={() => setIsCentAccount(!isCentAccount)}
                        className={`px-3 py-1.5 rounded-lg text-[10px] font-black transition-all border flex items-center gap-2 ${
                            isCentAccount ? 'bg-brand text-white border-brand-light shadow-lg shadow-brand/20' : 'bg-white/5 border-white/10 text-white/40'
                        }`}
                    >
                        <div className={`w-3 h-3 rounded-full border-2 ${isCentAccount ? 'bg-white border-white' : 'border-white/20'}`}></div>
                        VISTA USD (DIVIDIR /100)
                    </button>

                    <div className="flex gap-2">
                    {["ALL", "30", "7"].map(f => (
                        <button
                            key={f}
                            onClick={() => setFilter(f)}
                            className={`px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all border ${
                                filter === f ? 'bg-brand/20 border-brand-light text-white' : 'bg-white/5 border-white/10 text-white/40 hover:bg-white/10'
                            }`}
                        >
                            {f === "ALL" ? "TODO" : `ÚLTIMOS ${f} DÍAS`}
                        </button>
                    ))}
                </div>
            </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card className="glass-card bg-black/60 border-brand/20 p-6 flex flex-col items-center justify-center">
                    <span className="text-[10px] text-text-muted uppercase font-black mb-1">Beneficio Total</span>
                    <span className={`text-3xl font-black font-mono ${totalProfit >= 0 ? 'text-success' : 'text-danger'}`}>
                        {totalProfit >= 0 ? '+' : ''}{totalProfit.toFixed(2)}
                    </span>
                    <div className="flex items-center gap-1 mt-2 text-[10px] uppercase font-bold text-white/40">
                        {totalProfit >= 0 ? <TrendingUp className="w-3 h-3 text-success" /> : <TrendingDown className="w-3 h-3 text-danger" />}
                        {filteredData.length} Días con Actividad
                    </div>
                </Card>

                <div className="md:col-span-2 glass-card bg-black/60 border-white/5 p-6 rounded-2xl">
                    <h4 className="text-[10px] text-text-muted uppercase font-black mb-6">Crecimiento Diario (Últimos Registros)</h4>
                    <div className="h-40 flex items-end gap-1.5 px-2">
                        {filteredData.slice(-30).map((d, i) => (
                            <div key={i} className="flex-1 group relative">
                                <div 
                                    className={`w-full rounded-t-sm transition-all duration-300 ${d.profit >= 0 ? 'bg-success/40 group-hover:bg-success' : 'bg-danger/40 group-hover:bg-danger'}`}
                                    style={{ height: `${Math.max(((isCentAccount ? d.profit/100 : d.profit) / maxProfit) * 100, 5)}%` }}
                                />
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 p-2 bg-black border border-white/20 rounded-lg text-[8px] font-mono text-white opacity-0 group-hover:opacity-100 pointer-events-none z-20 whitespace-nowrap shadow-2xl">
                                    <div className="text-white/60">{d.date}</div>
                                    <div className={d.profit >= 0 ? 'text-success' : 'text-danger'}>
                                        {d.profit >= 0 ? '+' : ''}{(isCentAccount ? d.profit/100 : d.profit).toFixed(2)}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            <Card className="glass-card bg-black/60 border-white/5 overflow-hidden">
                <div className="p-4 border-b border-white/5 bg-white/5">
                    <h4 className="text-[10px] text-text-muted uppercase font-black">Historial Detallado por Día</h4>
                </div>
                <div className="max-h-80 overflow-y-auto scrollbar-thin">
                    <table className="w-full text-left text-[11px]">
                        <thead className="sticky top-0 bg-surface-dark/95 backdrop-blur-md text-white/40 border-b border-white/5">
                            <tr>
                                <th className="p-4 font-black uppercase">Fecha</th>
                                <th className="p-4 font-black uppercase">Operaciones</th>
                                <th className="p-4 font-black uppercase text-right">Beneficio</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredData.slice().reverse().map((d, i) => (
                                <tr key={i} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                                    <td className="p-4 font-mono text-white">{d.date}</td>
                                    <td className="p-4 text-text-muted">{d.count} trades</td>
                                    <td className={`p-4 text-right font-black font-mono ${d.profit >= 0 ? 'text-success' : 'text-danger'}`}>
                                        {d.profit >= 0 ? '+' : ''}{(isCentAccount ? d.profit/100 : d.profit).toFixed(2)}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </Card>
        </div>
    );
}
