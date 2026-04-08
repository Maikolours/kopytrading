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
    Settings2,
    Clock,
    Layout,
    AlertTriangle
} from "lucide-react";
import { BotSettings } from "./BotSettings";
import OperativoChart from "./OperativoChart";

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

    const sendRemoteCommand = async (cmd: string) => {
        setLoading(cmd);
        try {
            const res = await fetch(`/api/purchase/${purchaseId}/settings`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ account, pendingCmd: cmd })
            });
            if (res.ok) {
                setStatusMsg(`Comando ${cmd} enviado.`);
                setTimeout(() => setStatusMsg(null), 3000);
            }
        } catch (error) {
            console.error("Command Error:", error);
        } finally {
            setLoading(null);
        }
    };

    const updateRemoteSetting = async (key: string, value: any) => {
        setLoading(key);
        try {
            const newSettings = { ...botData, [key]: value };
            const res = await fetch(`/api/purchase/${purchaseId}/settings`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ account, settings: newSettings })
            });
            if (res.ok) {
                setBotData(newSettings);
            }
        } catch (error) {
            console.error("Setting Update Error:", error);
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
                            <h4 className="text-[9px] font-black uppercase tracking-wider text-white/90 leading-none">Remote Commander</h4>
                            <p className="text-[7px] text-white/40 font-bold uppercase tracking-widest leading-none mt-1 truncate max-w-[100px]">v11.3.9 Sniper Build</p>
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

                {/* GRÁFICO OPERATIVO CON FIBONACCI */}
                <div className="mb-4">
                    <OperativoChart 
                        trend={botData?.trend}
                        fiboLevels={botData?.p00 !== undefined ? {
                            p00: botData.p00,
                            p50: botData.p50,
                            p62: botData.p62,
                            p78: botData.p78,
                            p100: botData.p100
                        } : undefined}
                    />
                </div>

                {/* Telemetría Crucial */}
                <div className="grid grid-cols-2 gap-2 mb-4">
                    <div className="col-span-1 p-2 rounded-lg bg-white/5 border border-white/10 space-y-0.5">
                        <p className="text-[8px] uppercase font-black tracking-widest text-white/40 leading-none">Profit Hoy</p>
                        <h3 className={`text-md font-black tracking-tighter ${botData?.pnl_today >= 0 ? 'text-success' : 'text-danger'}`}>
                            {formatCurrency(botData?.pnl_today || 0)}
                        </h3>
                    </div>
                    <div className="col-span-1 p-2 rounded-lg bg-white/5 border border-white/10 space-y-0.5 text-right">
                        <p className="text-[8px] uppercase font-black tracking-widest text-white/40 leading-none">Equity</p>
                        <p className="text-sm font-black text-white/90">{formatCurrency(botData?.equity || 0)}</p>
                    </div>
                </div>

                {/* TACTICAL COMMANDS */}
                <div className="grid grid-cols-2 gap-2 mb-4">
                    <Button 
                        variant="outline" 
                        className="border-rose-500/20 bg-rose-500/10 hover:bg-rose-500/20 text-[10px] font-black uppercase py-4 text-rose-400 gap-2"
                        onClick={() => { if(confirm("🚨 ¿PANICO? Cerrar todo.")) sendRemoteCommand("EXIT_ALL") }}
                        loading={loading === "EXIT_ALL"}
                    >
                        <AlertTriangle size={14} />
                        Pánico 💥
                    </Button>
                    <Button 
                        variant="outline" 
                        className="border-sky-500/20 bg-sky-500/10 hover:bg-sky-500/20 text-[10px] font-black uppercase py-4 text-sky-400"
                        onClick={() => sendRemoteCommand("EXIT_50")}
                        loading={loading === "EXIT_50"}
                    >
                        Cerrar 50%
                    </Button>
                </div>

                {/* GESTIÓN REMOTA DE PARÁMETROS */}
                <div className="p-4 rounded-xl bg-white/5 border border-white/5 space-y-4 mb-4">
                    <h5 className="text-[9px] font-black uppercase tracking-widest text-white/40 flex items-center gap-2">
                        <Layout size={10} /> Ajustes del Sniper
                    </h5>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-[8px] font-black text-white/20 uppercase tracking-widest flex items-center gap-1">
                                <Clock size={8} /> Lookback
                            </label>
                            <select 
                                value={botData?.lkb || 12}
                                onChange={(e) => updateRemoteSetting("lkb", parseInt(e.target.value))}
                                className="w-full bg-black/40 border border-white/10 rounded-lg px-2 py-2 text-white font-black text-[10px] uppercase outline-none"
                            >
                                <option value="6">🚀 6H Focus</option>
                                <option value="12">🛡️ 12H Standard</option>
                                <option value="24">🐢 24H Swing</option>
                            </select>
                        </div>

                        <div className="space-y-2">
                            <label className="text-[8px] font-black text-white/20 uppercase tracking-widest flex items-center gap-1">
                                <Zap size={8} /> Gráfico
                            </label>
                            <select 
                                value={botData?.timeframe || "M5"}
                                onChange={(e) => updateRemoteSetting("timeframe", e.target.value)}
                                className="w-full bg-black/40 border border-white/10 rounded-lg px-2 py-2 text-white font-black text-[10px] uppercase outline-none"
                            >
                                <option value="M5">5 Minutos</option>
                                <option value="M15">15 Minutos</option>
                                <option value="M30">30 Minutos</option>
                                <option value="H1">1 Hora</option>
                            </select>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                        <Button 
                            variant="outline" 
                            className={`py-2 rounded-lg border text-[9px] font-black uppercase transition-all ${botData?.casOn ? 'bg-brand/10 border-brand-light text-brand-light' : 'bg-white/5 border-white/10 text-white/20'}`}
                            onClick={() => updateRemoteSetting("casOn", !botData?.casOn)}
                        >
                            Cascada: {botData?.casOn ? 'ON' : 'OFF'}
                        </Button>
                        <Button 
                            variant="outline" 
                            className={`py-2 rounded-lg border text-[9px] font-black uppercase transition-all ${botData?.autoRA ? 'bg-emerald-500/10 border-emerald-500/40 text-emerald-400' : 'bg-white/5 border-white/10 text-white/20'}`}
                            onClick={() => updateRemoteSetting("autoRA", !botData?.autoRA)}
                        >
                            Re-Arm: {botData?.autoRA ? 'ON' : 'OFF'}
                        </Button>
                    </div>

                    <Button 
                        variant="outline" 
                        fullWidth
                        className={`py-2 rounded-lg border text-[9px] font-black uppercase transition-all ${botData?.giroOn ? 'bg-amber-500/10 border-amber-500/40 text-amber-400' : 'bg-white/5 border-white/10 text-white/20'}`}
                        onClick={() => updateRemoteSetting("giroOn", !botData?.giroOn)}
                    >
                        <RotateCcw size={10} className="mr-1" />
                        Giro Táctico: {botData?.giroOn ? 'ON' : 'OFF'}
                    </Button>
                </div>

                {statusMsg && (
                    <p className="text-[10px] font-black text-brand-light uppercase tracking-widest text-center animate-bounce">{statusMsg}</p>
                )}
            </div>

            <div className="p-3 bg-black/40 border-t border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                    <Coins size={10} className="text-white/20" />
                    <div>
                        <p className="text-[7px] uppercase font-black text-white/20">Balance</p>
                        <p className="text-[9px] font-black text-white/60">{formatCurrency(botData?.balance || 0)}</p>
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
