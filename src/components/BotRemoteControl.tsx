"use client";

import { useState, useEffect } from "react";
import { Button } from "./ui/Button";
import { motion, AnimatePresence } from "framer-motion";
import { 
    Activity, 
    TrendingUp, 
    TrendingDown, 
    Zap, 
    RotateCcw, 
    ShieldAlert, 
    Coins, 
    BarChart3,
    ArrowUpRight,
    ArrowDownRight,
    RefreshCw
} from "lucide-react";

interface BotRemoteControlProps {
    purchaseId: string;
    botName: string;
    account: string;
    isOnline?: boolean;
    theme?: any;
}

export function BotRemoteControl({ purchaseId, botName, account, isOnline: initialOnline, theme }: BotRemoteControlProps) {
    const [loading, setLoading] = useState<string | null>(null);
    const [statusMsg, setStatusMsg] = useState<string | null>(null);
    const [botData, setBotData] = useState<any>(null);
    const [refreshing, setRefreshing] = useState(false);

    const isSniper = botName.toLowerCase().includes("sniper") || botName.toLowerCase().includes("v11");
    const isGoldBot = botName.toLowerCase().includes("oro") || botName.toLowerCase().includes("ametralladora");

    useEffect(() => {
        fetchBotData();
        const interval = setInterval(fetchBotData, 10000); // Sincro cada 10s
        return () => clearInterval(interval);
    }, [purchaseId, account]);

    const fetchBotData = async () => {
        setRefreshing(true);
        try {
            const res = await fetch(`/api/purchase/${purchaseId}/settings?account=${account}`);
            if (res.ok) {
                const data = await res.json();
                setBotData(data);
            }
        } catch (error) {
            console.error("Error fetching bot data:", error);
        } finally {
            setRefreshing(false);
        }
    };

    const sendCommand = async (command: string, value?: string) => {
        setLoading(command);
        setStatusMsg(null);
        try {
            const res = await fetch("/api/remote-control", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ purchaseId, command, value })
            });

            if (res.ok) {
                setStatusMsg(`Orden "${command}" enviada con éxito.`);
                setTimeout(() => setStatusMsg(null), 3000);
            } else {
                setStatusMsg("Error al enviar la orden.");
            }
        } catch (error) {
            setStatusMsg("Error de conexión.");
        } finally {
            setLoading(null);
        }
    };

    const formatCurrency = (val: number) => {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val);
    };

    const isActualOnline = botData?.isOnline || initialOnline;

    return (
        <div className={`mt-6 p-1 rounded-2xl bg-black/40 border ${theme?.border || 'border-white/10'} shadow-2xl flex flex-col backdrop-blur-xl relative overflow-hidden`}>
            {/* Animación de fondo sutil */}
            <div className={`absolute top-0 right-0 w-64 h-64 bg-gradient-to-br ${theme?.gradient || 'from-brand/20 to-transparent'} blur-3xl opacity-20 pointer-events-none`} />
            
            <div className="p-4 sm:p-5">
                {/* Header: Estado y Título */}
                <div className="flex items-center justify-between mb-5 border-b border-white/10 pb-4">
                    <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-xl bg-white/5 border border-white/10 ${theme?.accent || 'text-brand-light'}`}>
                            <Activity size={18} className={isActualOnline ? 'animate-pulse' : ''} />
                        </div>
                        <div>
                            <h4 className="text-[11px] font-black uppercase tracking-[0.2em] text-white/90">Estatus Operativo</h4>
                            <p className="text-[9px] text-white/40 font-bold uppercase tracking-widest">{botName} | {account}</p>
                        </div>
                    </div>
                    <div className="flex flex-col items-end gap-1">
                        <div className="flex items-center gap-2">
                            <span className={`w-2 h-2 rounded-full ${isActualOnline ? 'bg-success shadow-[0_0_8px_#22c55e]' : 'bg-white/20'}`}></span>
                            <span className={`text-[10px] font-black uppercase tracking-tighter ${isActualOnline ? 'text-success' : 'text-white/40'}`}>
                                {isActualOnline ? 'LIVE SYNC' : 'OFFLINE'}
                            </span>
                        </div>
                        {refreshing && <RefreshCw size={10} className="animate-spin text-white/20" />}
                    </div>
                </div>

                {/* Telemetría Live */}
                <div className="grid grid-cols-2 gap-3 mb-6">
                    <div className="col-span-2 p-4 rounded-xl bg-white/5 border border-white/10 flex items-center justify-between">
                        <div className="space-y-1">
                            <p className="text-[10px] uppercase font-black tracking-widest text-white/40">Profit Hoy (USD)</p>
                            <h3 className={`text-2xl font-black tracking-tighter flex items-center gap-2 ${botData?.pnl_today >= 0 ? 'text-success' : 'text-danger'}`}>
                                {botData?.pnl_today >= 0 ? <TrendingUp size={24} /> : <TrendingDown size={24} />}
                                {formatCurrency(botData?.pnl_today || 0)}
                            </h3>
                        </div>
                        <div className="text-right space-y-1">
                            <p className="text-[10px] uppercase font-black tracking-widest text-white/40">Equity Actual</p>
                            <p className="text-sm font-bold text-white/90">{formatCurrency(botData?.equity || 0)}</p>
                        </div>
                    </div>

                    <div className="p-3 rounded-xl bg-white/5 border border-white/5 space-y-1">
                        <p className="text-[9px] uppercase font-black tracking-widest text-white/30">Tendencia Bot</p>
                        <div className="flex items-center gap-2">
                            {botData?.trend === "BULL" ? (
                                <>
                                    <ArrowUpRight className="text-emerald-400" size={16} />
                                    <span className="text-xs font-black text-emerald-400 uppercase">Bullish</span>
                                </>
                            ) : botData?.trend === "BEAR" ? (
                                <>
                                    <ArrowDownRight className="text-rose-400" size={16} />
                                    <span className="text-xs font-black text-rose-400 uppercase">Bearish</span>
                                </>
                            ) : (
                                <span className="text-xs font-black text-white/40 uppercase italic">Analyzando...</span>
                            )}
                        </div>
                    </div>

                    <div className="p-3 rounded-xl bg-white/5 border border-white/5 space-y-1">
                        <p className="text-[9px] uppercase font-black tracking-widest text-white/30">Motor Sniper</p>
                        <div className="flex items-center gap-2">
                            <Zap className={botData?.armed ? "text-brand-light" : "text-white/20"} size={16} />
                            <span className={`text-xs font-black uppercase ${botData?.armed ? "text-brand-light" : "text-white/40"}`}>
                                {botData?.armed ? "ARMADO" : "LIMPIANDO"}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Sniper Tactical Layout */}
                <div className="space-y-3 mb-6">
                    <p className="text-[10px] font-black uppercase tracking-[0.2em] opacity-30 text-center">Protocolo de Ejecución</p>
                    
                    <div className="grid grid-cols-2 gap-3">
                        <Button 
                            variant="outline" 
                            className={`py-4 rounded-xl border-2 flex flex-col gap-1 h-auto transition-all ${
                                botData?.casOn 
                                ? 'bg-brand/10 border-brand-light text-brand-light shadow-[0_0_15px_rgba(168,85,247,0.2)]' 
                                : 'bg-white/5 border-white/10 text-white/30'
                            }`}
                            onClick={() => sendCommand("SET_SETTING", JSON.stringify({ casOn: !botData?.casOn }))}
                            loading={loading === "SET_SETTING" && statusMsg?.includes("casOn")}
                        >
                            <Zap size={18} />
                            <span className="text-[10px] font-black tracking-widest uppercase">Cascada {botData?.casOn ? 'ON' : 'OFF'}</span>
                        </Button>

                        <Button 
                            variant="outline" 
                            className={`py-4 rounded-xl border-2 flex flex-col gap-1 h-auto transition-all ${
                                (isSniper ? botData?.autoRA : botData?.giroOn)
                                ? 'bg-success/10 border-success/40 text-success shadow-[0_0_15px_rgba(34,197,94,0.2)]' 
                                : 'bg-white/5 border-white/10 text-white/30'
                            }`}
                            onClick={() => {
                                const key = isSniper ? 'autoRA' : 'giroOn';
                                sendCommand("SET_SETTING", JSON.stringify({ [key]: !(isSniper ? botData?.autoRA : botData?.giroOn) }));
                            }}
                        >
                            <RotateCcw size={18} />
                            <span className="text-[10px] font-black tracking-widest uppercase">
                                {isSniper ? `Re-Armar ${botData?.autoRA ? 'ON' : 'OFF'}` : `Giro ${botData?.giroOn ? 'ON' : 'OFF'}`}
                            </span>
                        </Button>
                    </div>

                    {isGoldBot && (
                        <div className="grid grid-cols-2 gap-3">
                             <Button 
                                variant="outline" 
                                size="sm" 
                                className={`bg-amber-500/10 border-amber-500/30 hover:bg-amber-500/20 text-[10px] font-black py-4 text-amber-400 ${botData?.fearOn ? 'opacity-100' : 'opacity-50'}`}
                                onClick={() => sendCommand("SET_SETTING", JSON.stringify({ fearOn: !botData?.fearOn }))}
                            >
                                🛡️ MODO MIEDO {botData?.fearOn ? 'ON' : 'OFF'}
                            </Button>
                            <Button 
                                variant="outline" 
                                size="sm" 
                                className="bg-emerald-500/10 border-emerald-500/30 hover:bg-emerald-500/20 text-[10px] font-black py-4 text-emerald-400"
                                onClick={() => sendCommand("CHANGE_MODE", "COSECHA")}
                            >
                                🚜 COSECHA YA
                            </Button>
                        </div>
                    )}
                </div>

                {/* Control de Flujo */}
                <div className="grid grid-cols-2 gap-3 mb-6">
                    <Button 
                        variant="outline" 
                        className="border-white/10 bg-white/5 hover:bg-white/10 text-[10px] font-black uppercase tracking-widest py-3 text-rose-400"
                        onClick={() => sendCommand("PAUSE")}
                        loading={loading === "PAUSE"}
                    >
                        Pausar Sistema
                    </Button>
                    <Button 
                        variant="outline" 
                        className="border-white/10 bg-white/5 hover:bg-white/10 text-[10px] font-black uppercase tracking-widest py-3 text-emerald-400"
                        onClick={() => sendCommand("RESUME")}
                        loading={loading === "RESUME"}
                    >
                        Reanudar Bot
                    </Button>
                </div>

                {/* Botones de Dirección (Estilo HUD MT5) */}
                <div className="flex gap-2 p-1 rounded-xl bg-black/60 border border-white/5 mb-6">
                    {["BUY", "SELL", "BOTH"].map((dir) => (
                        <button
                            key={dir}
                            onClick={() => sendCommand("DIRECTION", dir)}
                            className={`flex-1 py-3 rounded-lg text-[9px] font-black uppercase tracking-tighter transition-all ${
                                botData?.direction === dir ? 'bg-white/10 text-white border border-white/20' : 'text-white/20 hover:text-white/40'
                            }`}
                        >
                            {dir === "BOTH" ? "Ambos" : `Solo ${dir}`}
                        </button>
                    ))}
                </div>

                <div className="space-y-2">
                    <Button 
                        variant="danger" 
                        size="lg" 
                        fullWidth
                        className="text-[11px] font-black uppercase tracking-[0.2em] shadow-2xl shadow-danger/30 py-6 rounded-2xl relative overflow-hidden group"
                        onClick={() => {
                            if(confirm("🚨 ¿ALERTA ROJA? Esto cerrará todas las posiciones y detendrá el bot de inmediato.")) {
                                sendCommand("CLOSE_ALL");
                            }
                        }}
                    >
                        <ShieldAlert className="absolute left-6 opacity-20 group-hover:scale-125 transition-transform" size={32} />
                        Cierre de Emergencia (Pánico)
                    </Button>
                </div>

                {statusMsg && (
                    <motion.div 
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="mt-6 p-3 text-center bg-brand-light/10 rounded-xl border border-brand-light/20"
                    >
                        <p className="text-[10px] font-black text-brand-light uppercase tracking-widest">{statusMsg}</p>
                    </motion.div>
                )}
            </div>

            <div className="p-4 bg-black/40 border-t border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <div className="w-6 h-6 rounded-full bg-brand/20 flex items-center justify-center">
                        <Coins size={12} className="text-brand-light" />
                    </div>
                    <div>
                        <p className="text-[8px] uppercase font-black text-white/20 tracking-widest">Balance Total</p>
                        <p className="text-[10px] font-black text-white/60 tracking-tighter">{formatCurrency(botData?.balance || 0)}</p>
                    </div>
                </div>
                <div className="text-right">
                    <p className="text-[8px] uppercase font-black text-white/20 tracking-widest">Last Sync</p>
                    <p className="text-[8px] font-medium text-white/40 italic">
                        {botData?.lastUpdate ? new Date(botData.lastUpdate).toLocaleTimeString() : '---'}
                    </p>
                </div>
            </div>
        </div>
    );
}
