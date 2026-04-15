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
    const [onlyReal, setOnlyReal] = useState(true); // Default to Real only per user request

    useEffect(() => {
        const fetchData = async () => {
            setLoading(true);
            try {
                const url = `/api/dashboard/performance?onlyReal=${onlyReal}${selectedPurchaseId ? `&purchaseId=${selectedPurchaseId}` : ''}`;
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
    }, [selectedPurchaseId, onlyReal]);

    const filteredData = useMemo(() => {
        if (filter === "ALL") return data;
        const days = parseInt(filter);
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - days);
        return data.filter(d => {
            const date = new Date(d.date);
            return !isNaN(date.getTime()) && date >= cutoff;
        });
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

    const controls = (
        <div className="flex flex-col gap-6 mb-8 animate-in fade-in duration-700">
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                <div className="flex-1 space-y-3">
                    <h3 className="text-2xl font-black text-white tracking-tighter uppercase flex items-center gap-3">
                        <div className="w-2 h-8 bg-brand-light rounded-full" />
                        Rendimiento {selectedBotDetails ? `: ${selectedBotDetails.botProduct.name}` : '(Global)'}
                    </h3>
                    
                    {/* SELECTOR DE BOT PREMIUM */}
                    <div className="relative group max-w-md">
                        <label className="text-[10px] font-black text-white/30 uppercase tracking-[0.2em] mb-1.5 block ml-1">Seleccionar Bot / Estrategia</label>
                        <select 
                            value={selectedPurchaseId}
                            onChange={(e) => setSelectedPurchaseId(e.target.value)}
                            className="w-full bg-white/5 border-2 border-white/10 hover:border-brand-light/40 rounded-xl px-4 py-3 text-sm font-black text-white appearance-none focus:outline-none focus:ring-2 focus:ring-brand-light/20 transition-all cursor-pointer shadow-xl"
                        >
                            <option value="" className="bg-neutral-900">📊 RESUMEN GLOBAL</option>
                            {purchases.map(p => (
                                <option key={p.id} value={p.id} className="bg-neutral-900">
                                    {p.botProduct.name.toUpperCase()} (ID: {p.id.slice(-6).toUpperCase()})
                                </option>
                            ))}
                        </select>
                        <div className="absolute right-4 bottom-3.5 pointer-events-none text-white/20 group-hover:text-brand-light transition-colors">
                            ▼
                        </div>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-3 shrink-0">
                    {/* TOGGLE REAL/DEMO */}
                    <button
                        onClick={() => setOnlyReal(!onlyReal)}
                        className={`px-4 py-2.5 rounded-xl text-[10px] font-black tracking-widest transition-all border-2 flex items-center gap-2 group ${
                            onlyReal 
                            ? 'bg-success/10 border-success/40 text-success shadow-lg shadow-success/10' 
                            : 'bg-orange-500/10 border-orange-500/40 text-orange-400'
                        }`}
                    >
                        <div className={`w-2 h-2 rounded-full animate-pulse ${onlyReal ? 'bg-success shadow-[0_0_8px_rgba(34,197,94,0.6)]' : 'bg-orange-400'}`} />
                        {onlyReal ? 'VISTA: SOLO REAL' : 'VISTA: INCLUIR DEMO'}
                    </button>

                    <button
                        onClick={() => setIsCentAccount(!isCentAccount)}
                        className={`px-4 py-2.5 rounded-xl text-[10px] font-black tracking-widest transition-all border-2 flex items-center gap-2 ${
                            isCentAccount ? 'bg-brand/10 border-brand-light text-white' : 'bg-white/5 border-white/10 text-white/40'
                        }`}
                    >
                        <div className={`w-3 h-3 rounded-full border-2 ${isCentAccount ? 'bg-brand-light border-brand-light' : 'border-white/20'}`} />
                        DIVIDIR /100
                    </button>
                    
                    <div className="h-10 w-px bg-white/10 mx-1 hidden sm:block" />

                    <div className="flex bg-white/5 p-1 rounded-xl border border-white/10">
                        {["ALL", "30", "7"].map(f => (
                            <button
                                key={f}
                                onClick={() => setFilter(f)}
                                className={`px-4 py-1.5 rounded-lg text-[10px] font-black transition-all ${
                                    filter === f ? 'bg-white/10 text-white shadow-inner' : 'text-white/30 hover:text-white/60'
                                }`}
                            >
                                {f === "ALL" ? "TODO" : `${f}D`}
                            </button>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );

    if (loading) {
        return (
            <div className="space-y-6">
                {controls}
                <div className="flex flex-col items-center justify-center p-20 glass-card bg-black/40 rounded-3xl border-white/5 border">
                    <Loader2 className="w-12 h-12 animate-spin text-brand-light opacity-50 mb-4" />
                    <span className="text-xs font-black uppercase tracking-[0.3em] text-white/20">Sincronizando Historial...</span>
                </div>
            </div>
        );
    }

    if (data.length === 0) {
        return (
            <div className="space-y-6">
                {controls}
                <div className="glass-card p-20 text-center border-2 border-dashed border-white/5 rounded-3xl bg-black/20 group hover:border-brand-light/20 transition-all duration-500">
                    <div className="w-20 h-20 bg-white/5 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform">
                        <CalendarIcon className="w-8 h-8 text-white/10 group-hover:text-brand-light transition-colors" />
                    </div>
                    <h3 className="text-xl font-black text-white uppercase tracking-tighter mb-2">Sin Historial de Trades</h3>
                    <p className="text-sm text-text-muted/60 max-w-sm mx-auto mb-8 font-medium">Cuando tus bots comiencen a cerrar operaciones, los datos aparecerán detallados aquí automáticamente.</p>
                    
                    {selectedPurchaseId && (
                        <button 
                            onClick={() => setSelectedPurchaseId("")}
                            className="px-6 py-3 bg-white text-black text-[11px] font-black uppercase tracking-widest rounded-xl hover:bg-brand-light hover:text-white transition-all shadow-xl"
                        >
                            ← Volver al Resumen Global
                        </button>
                    )}
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-6 duration-1000">
            {controls}

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card className="glass-card bg-black/80 border-white/10 p-8 flex flex-col items-center justify-center relative overflow-hidden group shadow-[0_30px_60px_-15px_rgba(0,0,0,0.5)]">
                    <div className="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
                        <TrendingUp size={120} />
                    </div>
                    <span className="text-[10px] text-white/40 uppercase font-black tracking-[0.2em] mb-2 relative z-10">Beneficio Total</span>
                    <span className={`text-5xl font-black font-mono tracking-tighter relative z-10 transition-all ${totalProfit >= 0 ? 'text-success drop-shadow-[0_0_15px_rgba(34,197,94,0.3)]' : 'text-danger drop-shadow-[0_0_15px_rgba(239,68,68,0.3)]'}`}>
                        {totalProfit >= 0 ? '+' : ''}{totalProfit.toFixed(2)}
                        <span className="text-lg opacity-40 ml-1">{isCentAccount ? 'USC' : '$'}</span>
                    </span>
                    <div className="flex items-center gap-2 mt-4 px-3 py-1.5 rounded-full bg-white/5 border border-white/5 text-[10px] uppercase font-black tracking-widest text-white/40 group-hover:border-white/20 transition-all">
                        {totalProfit >= 0 ? <TrendingUp className="w-3 h-3 text-success" /> : <TrendingDown className="w-3 h-3 text-danger" />}
                        {filteredData.length} Días de Actividad
                    </div>
                </Card>

                <div className="md:col-span-2 glass-card bg-black/80 border-white/10 p-8 rounded-3xl relative overflow-hidden group shadow-[0_30px_60px_-15px_rgba(0,0,0,0.5)]">
                    <h4 className="text-[10px] text-white/40 uppercase font-black tracking-[0.2em] mb-8">Curva de Crecimiento Diario</h4>
                    <div className="h-48 flex items-end gap-2 px-2 pb-2 border-b border-white/5">
                        {filteredData.slice(-30).map((d, i) => (
                            <div key={i} className="flex-1 group/bar relative h-full flex items-end">
                                <div 
                                    className={`w-full rounded-t-lg transition-all duration-500 cursor-help ${d.profit >= 0 ? 'bg-success/20 group-hover/bar:bg-success shadow-[0_0_20px_rgba(34,197,94,0)] group-hover/bar:shadow-success/20' : 'bg-danger/20 group-hover/bar:bg-danger group-hover/bar:shadow-danger/20'}`}
                                    style={{ height: `${Math.max(((isCentAccount ? d.profit/100 : d.profit) / maxProfit) * 100, 8)}%` }}
                                />
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-3 p-3 bg-black/95 border border-white/20 rounded-xl text-[9px] font-black text-white opacity-0 group-hover/bar:opacity-100 pointer-events-none z-50 whitespace-nowrap shadow-2xl scale-90 group-hover/bar:scale-100 transition-all">
                                    <div className="text-white/40 mb-1">{d.date}</div>
                                    <div className={`text-sm ${d.profit >= 0 ? 'text-success' : 'text-danger'}`}>
                                        {d.profit >= 0 ? '+' : ''}{(isCentAccount ? d.profit/100 : d.profit).toFixed(2)} {isCentAccount ? 'USC' : '$'}
                                    </div>
                                    <div className="text-[7px] text-white/20 mt-1 uppercase tracking-widest">{d.count} Operaciones</div>
                                </div>
                            </div>
                        ))}
                    </div>
                    {/* EJE X MOCK */}
                    <div className="flex justify-between mt-3 px-2">
                        <span className="text-[8px] font-black text-white/10 uppercase tracking-widest">{filteredData[0]?.date}</span>
                        <span className="text-[8px] font-black text-white/10 uppercase tracking-widest">Hoy</span>
                    </div>
                </div>
            </div>

            <Card className="glass-card bg-black/80 border-white/10 rounded-3xl overflow-hidden shadow-2xl">
                <div className="p-6 border-b border-white/5 bg-white/[0.02] flex items-center justify-between">
                    <h4 className="text-[10px] text-white/40 uppercase font-black tracking-[0.2em]">Historial de Sesiones</h4>
                    <span className="text-[10px] bg-white/5 px-3 py-1 rounded-full text-white/20 font-black">REGISTROS: {filteredData.length}</span>
                </div>
                <div className="max-h-[500px] overflow-y-auto scrollbar-premium">
                    <table className="w-full text-left text-[12px] border-separate border-spacing-0">
                        <thead className="sticky top-0 bg-neutral-900/95 backdrop-blur-xl text-white/30 z-30">
                            <tr>
                                <th className="p-5 font-black uppercase tracking-widest border-b border-white/5">Fecha de Cierre</th>
                                <th className="p-5 font-black uppercase tracking-widest border-b border-white/5">Volumen Total</th>
                                <th className="p-5 font-black uppercase tracking-widest border-b border-white/5 text-right">Beneficio Neto</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {filteredData.slice().reverse().map((d, i) => (
                                <tr key={i} className="group hover:bg-white/[0.03] transition-colors cursor-default">
                                    <td className="p-5">
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-lg bg-white/5 flex items-center justify-center text-white/20 group-hover:bg-brand/10 group-hover:text-brand-light transition-all">
                                                <CalendarIcon size={14} />
                                            </div>
                                            <span className="font-mono text-white/80 group-hover:text-white transition-colors">{d.date}</span>
                                        </div>
                                    </td>
                                    <td className="p-5 text-white/40 font-black tracking-tight">{d.count} Trades ejecutados</td>
                                    <td className="p-5 text-right">
                                        <span className={`text-sm font-black font-mono transition-all ${d.profit >= 0 ? 'text-success group-hover:drop-shadow-[0_0_8px_rgba(34,197,94,0.4)]' : 'text-danger group-hover:drop-shadow-[0_0_8px_rgba(239,68,68,0.4)]'}`}>
                                            {d.profit >= 0 ? '+' : ''}{(isCentAccount ? d.profit/100 : d.profit).toFixed(2)}
                                            <span className="text-[10px] opacity-30 ml-1.5">{isCentAccount ? 'USC' : '$'}</span>
                                        </span>
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
