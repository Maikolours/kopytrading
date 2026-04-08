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
    RefreshCw,
    Settings2
} from "lucide-react";
import { BotSettings } from "./BotSettings";

interface BotRemoteControlProps {
    purchaseId: string;
    botName: string;
    account: string;
    isOnline?: boolean;
    theme?: any;
    initialData?: any;
}

export function BotRemoteControl({ 
    purchaseId, 
    botName, 
    account, 
    isOnline: initialOnline, 
    theme,
    initialData
}: BotRemoteControlProps) {
    const [loading, setLoading] = useState<string | null>(null);
    const [statusMsg, setStatusMsg] = useState<string | null>(null);
    const [botData, setBotData] = useState<any>(initialData || null);
    const [refreshing, setRefreshing] = useState(false);
    const [showSettings, setShowSettings] = useState(false);

    const isSniper = botName.toLowerCase().includes("sniper") || botName.toLowerCase().includes("v11");
    const isGoldBot = botName.toLowerCase().includes("oro") || botName.toLowerCase().includes("ametralladora");

    useEffect(() => {
        fetchBotData();
        const interval = setInterval(fetchBotData, 5000); // Sincro cada 5s para máxima precisión
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
        <div className={`mt-4 p-0.5 rounded-xl bg-black/40 border ${theme?.border || 'border-white/10'} shadow-2xl flex flex-col backdrop-blur-xl relative overflow-hidden`}>
            {/* Animación de fondo sutil */}
            <div className={`absolute top-0 right-0 w-48 h-48 bg-gradient-to-br ${theme?.gradient || 'from-brand/20 to-transparent'} blur-3xl opacity-10 pointer-events-none`} />
            
            <div className="p-3 sm:p-4">
                {/* Header: Estado y Título */}
                <div className="flex items-center justify-between mb-3 border-b border-white/5 pb-2">
                    <div className="flex items-center gap-2">
                        <div className={`p-1 rounded-lg bg-white/5 border border-white/5 ${theme?.accent || 'text-brand-light'}`}>
                            <Activity size={12} className={isActualOnline ? 'animate-pulse' : ''} />
                        </div>
                        <div>
                            <h4 className="text-[9px] font-black uppercase tracking-wider text-white/90 leading-none">Estatus</h4>
                            <p className="text-[7px] text-white/40 font-bold uppercase tracking-widest leading-none mt-1 truncate max-w-[100px]">{botName}</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="flex flex-col items-end gap-0.5">
                            <div className="flex items-center gap-1">
                                <span className={`w-1 h-1 rounded-full ${isActualOnline ? 'bg-success shadow-[0_0_5px_#22c55e]' : 'bg-white/20'}`}></span>
                                <span className={`text-[8px] font-black uppercase tracking-tighter ${isActualOnline ? 'text-success' : 'text-white/40'}`}>
                                    {isActualOnline ? 'LIVE' : 'OFFLINE'}
                                </span>
                            </div>
                            {refreshing && <RefreshCw size={7} className="animate-spin text-white/20" />}
                        </div>
                        {/* GEAR BUTTON INTEGRADO */}
                        <div className="h-4 w-px bg-white/5 mx-1" />
                        <button 
                            onClick={() => setShowSettings(!showSettings)}
                            className={`p-1.5 rounded-md transition-colors ${showSettings ? 'bg-white/20 text-white' : 'text-white/40 hover:text-white'}`}
                        >
                            <Settings2 size={12} className={showSettings ? 'animate-spin-slow' : ''} />
                        </button>
                    </div>
                </div>

                {showSettings && (
                    <div className="mb-4">
                        <BotSettings 
                            purchaseId={purchaseId} 
                            account={account} 
                            theme={theme}
                            onClose={() => setShowSettings(false)}
                            compact
                        />
                    </div>
                )}

                {/* Telemetría Live */}
                <div className="grid grid-cols-2 gap-2 mb-4">
                    <div className="col-span-2 p-3 rounded-lg bg-white/5 border border-white/10 flex items-center justify-between">
                        <div className="space-y-0.5">
                            <p className="text-[8px] uppercase font-black tracking-widest text-white/40 leading-none">Profit Hoy</p>
                            <h3 className={`text-xl font-black tracking-tighter flex items-center gap-1.5 ${botData?.pnl_today >= 0 ? 'text-success' : 'text-danger'}`}>
                                {botData?.pnl_today >= 0 ? <TrendingUp size={18} /> : <TrendingDown size={18} />}
                                {formatCurrency(botData?.pnl_today || 0)}
                            </h3>
                        </div>
                        <div className="text-right space-y-0.5">
                            <p className="text-[8px] uppercase font-black tracking-widest text-white/40 leading-none">Equity</p>
                            <p className="text-xs font-bold text-white/90">{formatCurrency(botData?.equity || 0)}</p>
                        </div>
                    </div>

                    <div className="p-2 rounded-lg bg-white/5 border border-white/5 space-y-0.5">
                        <p className="text-[8px] uppercase font-black tracking-widest text-white/30 leading-none">Tendencia</p>
                        <div className="flex items-center gap-1.5">
                            {botData?.trend === "BULL" ? (
                                <>
                                    <ArrowUpRight className="text-emerald-400" size={14} />
                                    <span className="text-[10px] font-black text-emerald-400 uppercase">Alcista</span>
                                </>
                            ) : botData?.trend === "BEAR" ? (
                                <>
                                    <ArrowDownRight className="text-rose-400" size={14} />
                                    <span className="text-[10px] font-black text-rose-400 uppercase">Bajista</span>
                                </>
                            ) : (
                                <span className="text-[10px] font-black text-white/20 uppercase italic font-mono tracking-tighter">Analizando...</span>
                            )}
                        </div>
                    </div>

                    <div className="p-2 rounded-lg bg-white/5 border border-white/5 space-y-0.5">
                        <p className="text-[8px] uppercase font-black tracking-widest text-white/30 leading-none">Motor Sniper</p>
                        <div className="flex items-center gap-1.5">
                            <Zap className={botData?.armed ? "text-brand-light" : "text-white/20"} size={14} />
                            <span className={`text-[10px] font-black uppercase ${botData?.armed ? "text-brand-light" : "text-white/40"}`}>
                                {botData?.armed ? "ARMADO" : "ESPERA"}
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
                            className={`py-3 rounded-lg border flex flex-col gap-0.5 h-auto transition-all ${
                                botData?.casOn 
                                ? 'bg-brand/10 border-brand-light text-brand-light shadow-[0_0_15px_rgba(168,85,247,0.1)]' 
                                : 'bg-white/5 border-white/10 text-white/20'
                            }`}
                            onClick={() => sendCommand("SET_SETTING", JSON.stringify({ casOn: !botData?.casOn }))}
                            loading={loading === "SET_SETTING" && statusMsg?.includes("casOn")}
                        >
                            <Zap size={14} />
                            <span className="text-[9px] font-black tracking-widest uppercase">Cascada {botData?.casOn ? 'ON' : 'OFF'}</span>
                        </Button>

                        <Button 
                            variant="outline" 
                            className={`py-3 rounded-lg border flex flex-col gap-0.5 h-auto transition-all ${
                                (isSniper ? botData?.autoRA : botData?.giroOn)
                                ? 'bg-success/10 border-success/40 text-success shadow-[0_0_15px_rgba(34,197,94,0.1)]' 
                                : 'bg-white/5 border-white/10 text-white/20'
                            }`}
                            onClick={() => {
                                const key = isSniper ? 'autoRA' : 'giroOn';
                                sendCommand("SET_SETTING", JSON.stringify({ [key]: !(isSniper ? botData?.autoRA : botData?.giroOn) }));
                            }}
                        >
                            <RotateCcw size={14} />
                            <span className="text-[9px] font-black tracking-widest uppercase">
                                {isSniper ? `Re-Arm: ${botData?.autoRA ? 'ON' : 'OFF'}` : `Giro: ${botData?.giroOn ? 'ON' : 'OFF'}`}
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
                <div className="grid grid-cols-2 gap-2 mb-4">
                    <Button 
                        variant="outline" 
                        className="border-white/10 bg-white/5 hover:bg-white/10 text-[9px] font-black uppercase tracking-widest py-2 text-rose-400"
                        onClick={() => sendCommand("PAUSE")}
                        loading={loading === "PAUSE"}
                    >
                        Pausar
                    </Button>
                    <Button 
                        variant="outline" 
                        className="border-white/10 bg-white/5 hover:bg-white/10 text-[9px] font-black uppercase tracking-widest py-2 text-emerald-400"
                        onClick={() => sendCommand("RESUME")}
                        loading={loading === "RESUME"}
                    >
                        Reanudar
                    </Button>
                </div>

                {/* Botones de Dirección (Estilo HUD MT5) */}
                <div className="flex gap-1.5 p-1 rounded-lg bg-black/60 border border-white/5 mb-4">
                    {["BUY", "SELL", "BOTH"].map((dir) => (
                        <button
                            key={dir}
                            onClick={() => sendCommand("DIRECTION", dir)}
                            className={`flex-1 py-2.5 rounded text-[8px] font-black uppercase tracking-tighter transition-all ${
                                botData?.direction === dir ? 'bg-white/10 text-white border border-white/20' : 'text-white/20 hover:text-white/40'
                            }`}
                        >
                            {dir === "BOTH" ? "Ambos" : dir}
                        </button>
                    ))}
                </div>
                
                <Button 
                    variant="danger" 
                    size="sm" 
                    fullWidth
                    className="text-[10px] font-black uppercase tracking-[0.1em] shadow-lg shadow-danger/20 py-4 rounded-xl relative overflow-hidden group"
                    onClick={() => {
                        if(confirm("🚨 ¿PANICO? Esto cerrará todo.")) {
                            sendCommand("CLOSE_ALL");
                        }
                    }}
                >
                    <ShieldAlert className="absolute left-4 opacity-20 group-hover:scale-110 transition-transform" size={24} />
                    Cierre de Emergencia
                </Button>

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
                <div className="flex items-center gap-1.5">
                    <div className="w-5 h-5 rounded-full bg-brand/20 flex items-center justify-center">
                        <Coins size={10} className="text-brand-light" />
                    </div>
                    <div>
                        <p className="text-[7px] uppercase font-black text-white/20 tracking-widest">Balance</p>
                        <p className="text-[9px] font-black text-white/60 tracking-tighter">{formatCurrency(botData?.balance || 0)}</p>
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
