"use client";

import { useState, useEffect } from "react";
import { Button } from "./ui/Button";
import { motion, AnimatePresence } from "framer-motion";
import { 
    Activity, 
    TrendingUp, 
    TrendingDown, 
    Zap, 
    ShieldAlert, 
    Coins, 
    BarChart3,
    ArrowUpRight,
    ArrowDownRight,
    RefreshCw,
    Settings2,
    Lock,
    Unlock,
    Settings,
    Clock,
    Eraser,
    ShieldCheck,
    Trash2
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

    // v12.4.0: Matriz Táctica Triple
    const [beValues, setBeValues] = useState<any>({ B1: "", B2: "", GR: "" });
    const [garValues, setGarValues] = useState<any>({ B1: "", B2: "", GR: "" });
    const [traValues, setTraValues] = useState<any>({ B1: "", B2: "", GR: "" });

    const isSniper = botName.toLowerCase().includes("sniper") || botName.toLowerCase().includes("v11");

    useEffect(() => {
        fetchBotData();
        const interval = setInterval(fetchBotData, 5000); 
        return () => clearInterval(interval);
    }, [purchaseId, account]);

    const fetchBotData = async () => {
        setRefreshing(true);
        try {
            // Pasamos symbol y tf si están disponibles en el estado previo
            const symbolParam = botData?.symbol ? `&symbol=${botData.symbol}` : '';
            const tfParam = botData?.tf ? `&timeframe=${botData.tf}` : '';
            const res = await fetch(`/api/purchase/${purchaseId}/settings?account=${account}${symbolParam}${tfParam}`);
            if (res.ok) {
                const data = await res.json();
                setBotData(data);
                // Sincronizar inputs locales v12.4
                if (!loading?.includes("SET_")) {
                    setBeValues({ B1: data.b1_be || "", B2: data.b2_be || "", GR: data.gr_be || "" });
                    setGarValues({ B1: data.b1_gar || "", B2: data.b2_gar || "", GR: data.gr_gar || "" });
                    setTraValues({ B1: data.b1_tra || data.trailling_val || "", B2: data.b2_tra || "", GR: data.gr_tra || "" });
                }
            }
        } catch (error) {
            console.error("Error fetching bot data:", error);
        } finally {
            setRefreshing(false);
        }
    };

    const handleReset = () => {
        if (confirm("🧹 ¿Resetear campos tácticos a Golden Settings?")) {
            setBeValues({ B1: "0.8", B2: "0.8", GR: "1.0" });
            setGarValues({ B1: "0.5", B2: "0.5", GR: "0.8" });
            setTraValues({ B1: "1.2", B2: "1.0", GR: "1.5" });
            setStatusMsg("Valores reseteados localmente.");
            setTimeout(() => setStatusMsg(null), 2000);
        }
    };

    const sendCommand = async (command: string, value?: string) => {
        setLoading(command);
        setStatusMsg(null);
        try {
            const res = await fetch("/api/remote-control", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ 
                    purchaseId, 
                    command, 
                    value,
                    // Enviamos contexto para que la orden sepa a qué memoria afecta
                    symbol: botData?.symbol,
                    timeframe: botData?.tf
                })
            });

            if (res.ok) {
                setStatusMsg(`Orden enviada con éxito.`);
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
            <div className={`absolute top-0 right-0 w-48 h-48 bg-gradient-to-br ${theme?.gradient || 'from-brand/20 to-transparent'} blur-3xl opacity-10 pointer-events-none`} />
            
            <div className="p-3 sm:p-4">
                <div className="flex items-center justify-between mb-3 border-b border-white/5 pb-2">
                    <div className="flex items-center gap-2">
                        <div className={`p-1 rounded-lg bg-white/5 border border-white/5 ${theme?.accent || 'text-brand-light'}`}>
                            <Activity size={12} className={isActualOnline ? 'animate-pulse' : ''} />
                        </div>
                        <div>
                            <h4 className="text-[9px] font-black uppercase tracking-wider text-brand-light leading-none">Sniper v12.4.6 GOLDEN</h4>
                            <div className="flex flex-col gap-0.5 mt-1">
                                <p className="text-[7px] text-white/40 font-bold uppercase tracking-widest leading-none truncate max-w-[100px]">Universal Matrix</p>
                                {botData?.symbol && (
                                    <p className="text-[6px] font-black text-brand-light/80 uppercase tracking-tighter leading-none flex items-center gap-0.5">
                                        <Clock size={6} /> {botData.symbol} {botData.tf}
                                    </p>
                                )}
                            </div>
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
                        <div className="h-4 w-px bg-white/5 mx-1" />
                        <button 
                            onClick={() => setShowSettings(!showSettings)}
                            className={`p-1.5 rounded-md transition-colors ${showSettings ? 'bg-white/20 text-white' : 'text-white/40 hover:text-white'}`}
                        >
                            <Settings2 size={12} className={showSettings ? 'animate-spin-slow' : ''} />
                        </button>
                    </div>
                </div>

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
                        <p className="text-[8px] uppercase font-black tracking-widest text-white/30 leading-none">Estatus Bot</p>
                        <div className="flex items-center gap-1.5">
                            <Zap className={botData?.armed ? "text-brand-light" : "text-white/20"} size={14} />
                            <span className={`text-[10px] font-black uppercase ${botData?.armed ? "text-brand-light" : "text-white/40"}`}>
                                {botData?.armed ? "ARMADO" : "ESPERA"}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Matrix Táctica v12.4.0 */}
                <div className="mb-4 bg-white/5 rounded-xl border border-white/5 p-3 space-y-3">
                    <div className="flex items-center justify-between border-b border-white/5 pb-1">
                        <p className="text-[8px] font-black uppercase text-white/40 tracking-widest flex items-center gap-2">
                            <ShieldAlert size={10} className="text-brand-light" /> Tactical Matrix
                        </p>
                        <div className="flex gap-4 pr-10">
                            <span className="text-[6px] font-black text-white/20 uppercase">BE</span>
                            <span className="text-[6px] font-black text-white/20 uppercase">GAR</span>
                            <span className="text-[6px] font-black text-white/20 uppercase">TRA</span>
                        </div>
                    </div>
                    
                    {['B1', 'B2', 'GR'].map((bot) => (
                        <div key={bot} className="flex items-center gap-2">
                            <div className="w-6">
                                <span className={`text-[8px] font-black ${bot==='GR' ? 'text-gold' : 'text-white/40'}`}>{bot}</span>
                            </div>
                            <div className="flex-1 grid grid-cols-3 gap-1.5 ml-1">
                                {['BE', 'GAR', 'TRA'].map((param) => {
                                    const val = param === 'BE' ? beValues[bot] : param === 'GAR' ? garValues[bot] : traValues[bot];
                                    const setter = param === 'BE' ? setBeValues : param === 'GAR' ? setGarValues : setTraValues;
                                    const cmd = `SET_${bot}_${param}`;
                                    
                                    return (
                                        <div key={param} className="flex flex-col gap-1">
                                            <div className="flex bg-black/40 rounded border border-white/5 overflow-hidden focus-within:border-brand-light/30 transition-colors">
                                                <input 
                                                    type="number"
                                                    value={val}
                                                    step="0.1"
                                                    onChange={(e) => setter({...val, [bot]: e.target.value})}
                                                    className="w-full bg-transparent px-1 py-1 text-[9px] font-bold text-white outline-none text-center"
                                                />
                                                <button 
                                                    onClick={() => sendCommand(cmd, val.toString())}
                                                    disabled={loading === cmd}
                                                    className="px-1 bg-white/5 text-[7px] font-black text-brand-light hover:bg-brand-light hover:text-black transition-colors"
                                                >
                                                    {loading === cmd ? '...' : 'OK'}
                                                </button>
                                            </div>
                                        </div>
                                    )
                                })}
                            </div>
                        </div>
                    ))}
                </div>

                <div className="space-y-3 mb-6">
                    <div className="grid grid-cols-3 gap-2">
                        <div className="col-span-3 space-y-1 mb-1 border-b border-white/5 pb-2">
                            <p className="text-[7px] font-black text-white/40 uppercase tracking-widest pl-1">Lookback (HTF) & Masters</p>
                            <div className="flex flex-wrap gap-1.5">
                                {[1, 4, 6, 12, 24].map((h) => (
                                    <Button 
                                        key={h}
                                        variant="outline"
                                        size="sm"
                                        className={`text-[9px] font-black flex-1 min-w-[40px] px-0 h-7 transition-all duration-300 ${
                                            Number(botData?.lkb) === h 
                                            ? 'bg-brand/30 border-brand-light text-brand-light shadow-[0_0_10px_rgba(36,206,203,0.2)]' 
                                            : 'bg-white/5 border-white/10 text-white/40'
                                        }`}
                                        onClick={() => sendCommand("SET_LOOKBACK", h.toString())}
                                    >
                                        {h}H
                                    </Button>
                                ))}
                            </div>
                        </div>

                {/* ACCIONES TÁCTICAS PRINCIPALES */}
                <div className="grid grid-cols-2 gap-2 mb-4">
                    <Button 
                        variant={ (botData?.casOn || botData?.cascada) ? "success" : "secondary"}
                        className={`flex items-center justify-center gap-2 py-4 h-auto text-[10px] font-black uppercase tracking-wider transition-all duration-300 ${
                            (botData?.casOn || botData?.cascada) ? 'shadow-[0_0_15px_rgba(34,197,94,0.3)]' : ''
                        }`}
                        onClick={() => sendCommand("SET_SETTING", JSON.stringify({ casOn: !(botData?.casOn || botData?.cascada) }))}
                    >
                        <Zap size={14} className={(botData?.casOn || botData?.cascada) ? "animate-pulse" : "text-white/20"} />
                        Cascada {(botData?.casOn || botData?.cascada) ? 'ON' : 'OFF'}
                    </Button>

                    <Button 
                        variant={ (botData?.giroOn || botData?.giro) ? "success" : "secondary"}
                        className={`flex items-center justify-center gap-2 py-4 h-auto text-[10px] font-black uppercase tracking-wider transition-all duration-300 ${
                            (botData?.giroOn || botData?.giro) ? 'shadow-[0_0_15px_rgba(249,115,22,0.3)]' : ''
                        }`}
                        onClick={() => sendCommand("SET_SETTING", JSON.stringify({ giroOn: !(botData?.giroOn || botData?.giro) }))}
                    >
                        <RefreshCw size={14} className={(botData?.giroOn || botData?.giro) ? "animate-spin-slow" : "text-white/20"} />
                        Giro {(botData?.giroOn || botData?.giro) ? 'ON' : 'OFF'}
                    </Button>

                    <Button 
                        variant={ botData?.hideMinor ? "success" : "secondary"}
                        className="flex items-center justify-center gap-2 py-3 h-auto text-[10px] font-black uppercase tracking-wider"
                        onClick={() => sendCommand("SET_SETTING", JSON.stringify({ hideMinor: !botData?.hideMinor }))}
                    >
                        <BarChart3 size={14} className={botData?.hideMinor ? "text-cyan" : "text-white/20"} />
                        X-RAY {botData?.hideMinor ? 'ON' : 'OFF'}
                    </Button>

                    <Button 
                        variant={ botData?.armed ? "success" : "secondary"}
                        className="flex items-center justify-center gap-2 py-3 h-auto text-[10px] font-black uppercase tracking-wider"
                        onClick={() => sendCommand("ARM_BOT", "TOGGLE")}
                    >
                        <ShieldCheck size={14} className={botData?.armed ? "text-brand-light" : "text-white/20"} />
                        {botData?.armed ? 'Armado' : 'Espera'}
                    </Button>
                </div>

                <div className="space-y-2 pt-4 border-t border-white/10">
                    <Button 
                        variant="secondary"
                        size="sm"
                        className="w-full flex items-center justify-center gap-2 py-3 bg-white/5 hover:bg-white/10 border-white/10 text-[9px] font-bold uppercase tracking-widest text-white/60"
                        onClick={handleReset}
                    >
                        <Eraser size={12} />
                        Limpiar Inputs (Golden Reset)
                    </Button>

                    <Button 
                        variant="danger" 
                        size="sm" 
                        fullWidth
                        className="w-full flex items-center justify-center gap-3 py-5 rounded-xl text-xs font-black uppercase tracking-[0.2em] shadow-[0_0_25px_rgba(239,68,68,0.2)] hover:shadow-[0_0_35px_rgba(239,68,68,0.4)] transition-all"
                        onClick={() => {
                            if(confirm("🚨 ¿PANICO? Esto cerrará todo.")) {
                                sendCommand("CLOSE_ALL");
                            }
                        }}
                    >
                        <ShieldAlert size={20} fill="red" />
                        Pánico: Cierre Total
                    </Button>
                </div>

                {statusMsg && (
                    <motion.div 
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="mt-4 p-2 text-center bg-white/5 rounded-lg border border-white/5"
                    >
                        <p className="text-[9px] font-black text-white/60 uppercase tracking-widest">{statusMsg}</p>
                    </motion.div>
                )}
            </div>

            <div className="p-4 bg-black/40 border-t border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                    <Coins size={10} className="text-white/20" />
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
