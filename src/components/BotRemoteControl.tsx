"use client";

import { useState, useEffect, useMemo } from "react";
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
    ShieldCheck,
    Clock,
    Target,
    Save,
    ChevronDown,
    Lock,
    RotateCcw
} from "lucide-react";

interface BotRemoteControlProps {
    purchaseId: string;
    botName: string;
    account: string;
    symbol?: string;
    isOnline?: boolean;
    theme?: any;
    initialData?: any;
    isOwner?: boolean;
    isReal?: boolean;
}

export function BotRemoteControl({ 
    purchaseId, 
    botName, 
    account, 
    symbol,
    isOnline: initialOnline, 
    theme,
    initialData,
    isOwner = false,
    isReal = false
}: BotRemoteControlProps) {
    const [loading, setLoading] = useState<string | null>(null);
    const [statusMsg, setStatusMsg] = useState<string | null>(null);
    const [botData, setBotData] = useState<any>(initialData || null);
    const [refreshing, setRefreshing] = useState(false);
    const [showSettings, setShowSettings] = useState(false);
    const [mounted, setMounted] = useState(false);

    // ESTADOS LOCALES (Opción B: Guardar Cambios)
    const [localSettings, setLocalSettings] = useState<any>({
        sl: 250,
        tp: 500,
        be: 150,
        tra: 100,
        lkb: 48,
        tf_trend: "PERIOD_H1",
        tf_fibo: "PERIOD_M15",
        tf_entry: "PERIOD_M5",
        mode: 1,
        dir: 2,
        exec: 1, // 0: Market, 1: Limit
        insights_on: true,
        lote_manual: 0.08,
        max_reentries: 8,
        casOn: true
    });

    const [showAdvanced, setShowAdvanced] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    const isGold = botName?.toLowerCase()?.includes("gold") || botName?.toLowerCase()?.includes("ametralladora") || botData?.symbol === "XAUUSD";

    useEffect(() => {
        fetchBotData();
        const interval = setInterval(fetchBotData, 5000); 
        return () => clearInterval(interval);
    }, [purchaseId, account, symbol]);

    const fetchBotData = async () => {
        setRefreshing(true);
        try {
            const symbolParam = symbol ? `&symbol=${symbol}` : "";
            const res = await fetch(`/api/purchase/${purchaseId}/settings?account=${account}${symbolParam}`);
            if (res.ok) {
                const data = await res.json();
                setBotData(data);
                // Si no estamos cargando (aplicando), actualizamos los locales con la telemetría real del bot
                if (!loading) {
                    setLocalSettings({
                        sl: data.sl || 250,
                        tp: data.tp || 500,
                        be: data.be || 150,
                        tra: data.tra || 100,
                        lkb: data.lkb || 25,
                        tf_trend: data.tf_trend || "PERIOD_H1",
                        tf_fibo: data.tf_fibo || "PERIOD_M15",
                        tf_entry: data.tf_entry || "PERIOD_M5",
                        mode: data.mode !== undefined ? data.mode : 1,
                        dir: data.dir !== undefined ? data.dir : 2,
                        insights_on: data.insights_on !== undefined ? data.insights_on : true,
                        lote_manual: data.lote_manual !== undefined ? data.lote_manual : 0.08,
                        max_reentries: data.max_reentries !== undefined ? data.max_reentries : 8,
                        casOn: data.casOn !== undefined ? data.casOn : true
                    });
                }
            }
        } catch (error) {
            console.error("Error fetching bot data:", error);
        } finally {
            setRefreshing(false);
        }
    };

    const handleApplySettings = async () => {
        setLoading("APPLY");
        setStatusMsg("Sincronizando con MT5...");
        try {
            const res = await fetch("/api/remote-control", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ 
                    purchaseId, 
                    command: "SET_SETTING", 
                    value: JSON.stringify(localSettings)
                })
            });

            if (res.ok) {
                setStatusMsg("✅ Configuración enviada!");
                setTimeout(() => setStatusMsg(null), 3000);
            } else {
                setStatusMsg("❌ Error de comunicación.");
            }
        } catch (error) {
            setStatusMsg("❌ Error de red.");
        } finally {
            setLoading(null);
        }
    };

    const handleResetToSafeConfig = async () => {
        setLoading("APPLY");
        setStatusMsg("Restableciendo valores seguros...");
        
        // Conservamos los valores fijos optimizados por Maiko
        const safeSettings = {
            ...localSettings,
            lote_manual: 0.08,
            max_reentries: 8,
            casOn: true,
            sl: 250,
            tp: 500,
            be: 150,
            tra: 100,
            lkb: 48,
            tf_trend: "PERIOD_H1",
            tf_fibo: "PERIOD_M15",
            tf_entry: "PERIOD_M5",
            mode: 1,
            dir: 2,
            exec: 1,
            insights_on: true
        };
        
        setLocalSettings(safeSettings);
        
        try {
            const res = await fetch("/api/remote-control", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ 
                    purchaseId, 
                    command: "SET_SETTING", 
                    value: JSON.stringify(safeSettings)
                })
            });

            if (res.ok) {
                setStatusMsg("✅ ¡Configuración segura aplicada!");
                setTimeout(() => setStatusMsg(null), 3000);
            } else {
                setStatusMsg("❌ Error al aplicar configuración segura.");
            }
        } catch (error) {
            setStatusMsg("❌ Error de red.");
        } finally {
            setLoading(null);
        }
    };

    const displayNarrative = useMemo(() => {
        if (isOwner) return botData?.narrative || "Sincronizando narrativa...";
        if (!botData?.narrative) return "Sincronizando narrativa...";
        
        const containsTech = /bos|ote|fibo|orderblock|fvg|breaker|liquidity|rsl/i.test(botData.narrative);
        if (containsTech) {
            return "🎯 Estrategia institucional activa. El bot está analizando rangos de alta precisión buscando zonas óptimas de oferta y demanda en tiempo real.";
        }
        return botData.narrative;
    }, [botData?.narrative, isOwner]);

    const displayStatus = useMemo(() => {
        if (isOwner) return botData?.status || "BUSCANDO...";
        if (!botData?.status) return "BUSCANDO...";
        
        const containsTech = /bos|ote|fibo|orderblock|fvg|breaker|liquidity/i.test(botData.status);
        if (containsTech) {
            return "CICLO ACTIVO ⚡";
        }
        return botData.status;
    }, [botData?.status, isOwner]);

    const sendAction = async (command: string, value?: string) => {
        setLoading(command);
        try {
            await fetch("/api/remote-control", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ purchaseId, command, value })
            });
            setStatusMsg(`Orden ${command} enviada.`);
            setTimeout(() => setStatusMsg(null), 2000);
        } catch (e) {
            setStatusMsg("Error.");
        } finally {
            setLoading(null);
        }
    };

    const formatCurrency = (val: number) => {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val);
    };

    const isActualOnline = botData?.isOnline || initialOnline;

    const TimeframeOption = ({ label, value, current, setter, keyName }: any) => (
        <button 
            onClick={() => setter({ ...current, [keyName]: value })}
            className={`px-1.5 py-1 text-[8px] font-black rounded border transition-all ${
                current[keyName] === value 
                ? 'bg-brand/30 border-brand-light text-brand-light' 
                : 'bg-white/5 border-white/10 text-white/40 hover:text-white'
            }`}
        >
            {label}
        </button>
    );

    return (
        <div className="w-full sm:flex sm:justify-center py-2 sm:py-4">
            <div className={`w-full max-w-full sm:max-w-[400px] rounded-2xl bg-black/40 border border-white/10 shadow-2xl flex flex-col backdrop-blur-xl relative overflow-hidden mx-auto`}>
                <div className={`absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-brand/20 to-transparent blur-3xl opacity-20 pointer-events-none`} />
                
                {/* HEADER */}
                <div className="p-4 border-b border-white/5">
                    <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-3">
                            <div className={`p-2 rounded-xl bg-brand/10 border border-brand/20 text-brand-light shadow-[0_0_15px_rgba(36,206,203,0.2)]`}>
                                <Target size={16} className={isActualOnline ? 'animate-pulse' : ''} />
                            </div>
                            <div>
                                <h4 className="text-[11px] font-black uppercase tracking-widest text-white leading-none">
                                    {botName || "MAIKO SNIPER PRO"}
                                </h4>
                                <p className="text-[8px] font-bold text-brand-light mt-1 tracking-tighter">
                                    v{botData?.version || "13.92"} MAIKO ENGINE
                                </p>
                            </div>
                        </div>
                        <div className="flex items-center gap-2">
                             <div className="flex flex-col items-end">
                                <span className={`text-[7px] font-black tracking-widest ${isActualOnline ? 'text-success' : 'text-white/20'}`}>
                                    {isActualOnline ? 'ONLINE' : 'OFFLINE'}
                                </span>
                                {refreshing && <RefreshCw size={8} className="animate-spin text-white/20 mt-0.5" />}
                             </div>
                             <div className={`w-1.5 h-1.5 rounded-full ${isActualOnline ? 'bg-success shadow-[0_0_8px_#22c55e]' : 'bg-white/20'}`} />
                        </div>
                    </div>

                    <div className="flex items-center justify-between gap-2 px-2 py-1.5 bg-white/5 rounded-lg border border-white/5">
                        <div className="flex items-center gap-1.5">
                            <ShieldCheck size={10} className="text-white/30" />
                            <span className="text-[8px] font-bold text-white/40 tracking-wider">ID: {purchaseId.substring(0,8)}...</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                            <Clock size={10} className="text-white/30" />
                            <span className="text-[8px] font-black text-white/60 tracking-wider uppercase font-mono">{botData?.symbol || "---"} {botData?.tf || "---"}</span>
                        </div>
                    </div>
                </div>

                {/* TELEMETRY CARDS */}
                <div className="p-3 sm:p-4 grid grid-cols-2 gap-2 sm:gap-3">
                    <div className="col-span-2 p-4 sm:p-5 rounded-xl bg-gradient-to-br from-white/10 to-transparent border border-white/10 flex items-center justify-between group">
                        <div className="space-y-1">
                            <p className="text-[9px] sm:text-[10px] uppercase font-black tracking-[0.2em] text-white/30 leading-none">PROFIT HOY</p>
                            <h3 className={`text-3xl sm:text-4xl font-black tracking-tighter flex items-center gap-1 sm:gap-2 ${botData?.pnl_today >= 0 ? 'text-success' : 'text-danger'}`}>
                                {botData?.pnl_today >= 0 ? <TrendingUp size={24} /> : <TrendingDown size={24} />}
                                {formatCurrency(botData?.pnl_today || 0)}
                            </h3>
                        </div>
                        <div className="text-right space-y-1">
                            <p className="text-[9px] sm:text-[10px] uppercase font-black tracking-[0.2em] text-white/30 leading-none">EQUIDAD</p>
                            <p className="text-sm sm:text-lg font-black text-white group-hover:text-brand-light transition-colors">{formatCurrency(botData?.equity || 0)}</p>
                        </div>
                    </div>

                    <div className="col-span-2 p-3 sm:p-4 rounded-xl bg-brand/5 border border-brand/20 space-y-2">
                         <p className="text-[9px] uppercase font-black tracking-widest text-brand-light flex items-center gap-1">
                            <Target size={12} /> PLAN DE ATAQUE
                        </p>
                        <p className={`text-xs sm:text-sm font-bold leading-tight ${botData?.narrative?.includes("🎯") || botData?.narrative?.includes("⚡") ? "text-white" : "text-white/60"}`}>
                            {displayNarrative}
                        </p>
                    </div>

                    <div className="p-3 sm:p-4 rounded-xl bg-white/5 border border-white/5 space-y-2">
                        <p className="text-[9px] uppercase font-black tracking-widest text-white/20 flex items-center gap-1">
                            <ShieldAlert size={10} /> BIAS (4H)
                        </p>
                        <div className="flex items-center gap-1.5">
                            <div className={`w-2 h-2 rounded-full ${botData?.trend === 'BULL' ? 'bg-success' : 'bg-danger'}`} />
                            <span className={`text-[10px] font-black uppercase ${botData?.trend === 'BULL' ? 'text-success' : 'text-danger'}`}>
                                {botData?.trend === 'BULL' ? 'ALCISTA' : 'BAJISTA'}
                            </span>
                        </div>
                    </div>

                    <div className="p-3 sm:p-4 rounded-xl bg-white/5 border border-white/5 space-y-2">
                         <p className="text-[9px] uppercase font-black tracking-widest text-white/20 flex items-center gap-1">
                            <Activity size={10} /> STATUS
                        </p>
                        <p className={`text-[10px] sm:text-[11px] font-black uppercase truncate ${botData?.status?.includes("BOS") || botData?.status?.includes("OTE") ? "text-brand-light" : "text-white/40"}`}>
                            {displayStatus}
                        </p>
                    </div>
                </div>

                {/* SETTINGS TRIGGER BUTTON (Visible only for Owner, or clients on Demo accounts) */}
                {(isOwner || !isReal) && (
                    <div className="px-4 pb-4">
                        <button
                            onClick={() => setShowSettings(!showSettings)}
                            className="w-full flex items-center justify-between px-4 py-3 rounded-xl text-xs font-black uppercase tracking-widest bg-white/5 hover:bg-white/10 border border-white/10 text-white transition-all shadow-md group"
                        >
                            <span className="flex items-center gap-2">
                                <Settings2 size={14} className="group-hover:rotate-45 transition-transform duration-300 text-brand-light" />
                                {showSettings ? "Ocultar Ajustes" : "⚙️ CONFIGURACIÓN DE PARÁMETROS"}
                            </span>
                            <ChevronDown size={14} className={`text-white/40 transition-transform duration-300 ${showSettings ? 'rotate-180' : ''}`} />
                        </button>
                    </div>
                )}

                {/* SETTINGS DROPDOWN PANEL */}
                <AnimatePresence>
                    {showSettings && (isOwner || !isReal) && (
                        <motion.div
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: "auto" }}
                            exit={{ opacity: 0, height: 0 }}
                            className="px-4 pb-4 overflow-hidden"
                        >
                            <div className="p-4 rounded-xl bg-black/60 border border-white/5 space-y-4 shadow-inner">
                                <div className="flex items-center justify-between border-b border-white/5 pb-2">
                                    <span className="text-[10px] font-black uppercase tracking-wider text-brand-light">
                                        {isOwner ? "🎛️ PANEL MASTER ADMINISTRADOR" : "🎛️ CONFIGURACIÓN DE ALGORITMO (DEMO)"}
                                    </span>
                                    {isOwner && (
                                        <span className="text-[8px] font-black uppercase text-purple-400 bg-purple-500/10 border border-purple-500/20 px-2 py-0.5 rounded">
                                            Raquel Sak.
                                        </span>
                                    )}
                                </div>

                                {/* FORMULARIO */}
                                <div className="space-y-3">
                                    {/* SECCIÓN CAPADA / BÁSICA - Visible para ambos (Owner y Demo) */}
                                    <div className="grid grid-cols-2 gap-3">
                                        <div className="space-y-1">
                                            <label className="text-[8px] font-black uppercase text-white/40 tracking-wider">
                                                LOTE SNIPER BASE
                                            </label>
                                            <input
                                                type="number"
                                                step="0.01"
                                                min="0.01"
                                                className="w-full bg-white/5 border border-white/10 text-white text-xs font-bold font-mono px-2 py-1.5 rounded focus:outline-none focus:border-brand-light"
                                                value={localSettings.lote_manual}
                                                onChange={(e) => setLocalSettings({ ...localSettings, lote_manual: parseFloat(e.target.value) || 0.01 })}
                                            />
                                        </div>

                                        <div className="space-y-1">
                                            <label className="text-[8px] font-black uppercase text-white/40 tracking-wider">
                                                MAX RE-ENTRADAS
                                            </label>
                                            <select
                                                className="w-full bg-white/5 border border-white/10 text-white text-xs font-bold px-2 py-1.5 rounded focus:outline-none focus:border-brand-light"
                                                value={localSettings.max_reentries}
                                                onChange={(e) => setLocalSettings({ ...localSettings, max_reentries: parseInt(e.target.value) || 1 })}
                                            >
                                                {[1, 2, 3, 4, 5, 6, 7, 8].map((num) => (
                                                    <option key={num} value={num} className="bg-black text-white">
                                                        {num} niveles
                                                    </option>
                                                ))}
                                            </select>
                                        </div>
                                    </div>

                                    <div className="flex items-center justify-between p-2.5 rounded-lg bg-white/5 border border-white/5">
                                        <div>
                                            <p className="text-[9px] font-black uppercase text-white/80">OPERATIVA EN CASCADA</p>
                                            <p className="text-[7px] text-white/40">Permitir re-entradas automáticas</p>
                                        </div>
                                        <button
                                            onClick={() => setLocalSettings({ ...localSettings, casOn: !localSettings.casOn })}
                                            className={`px-3 py-1.5 rounded text-[8px] font-black uppercase border transition-all ${
                                                localSettings.casOn 
                                                ? 'bg-success/20 border-success text-success' 
                                                : 'bg-white/5 border-white/10 text-white/40'
                                            }`}
                                        >
                                            {localSettings.casOn ? "ACTIVADO" : "DESACTIVADO"}
                                        </button>
                                    </div>

                                    {/* SI ES SAKURA / OWNER, RENDERIZAR CONFIGURACIÓN AVANZADA COMPLETA */}
                                    {isOwner && (
                                        <div className="space-y-3 pt-3 border-t border-white/5">
                                            <div className="flex items-center justify-between">
                                                <span className="text-[8px] font-black uppercase text-purple-400 tracking-widest">
                                                    ⚡ AJUSTES AVANZADOS DE ESTRATEGIA
                                                </span>
                                            </div>

                                            <div className="grid grid-cols-3 gap-2">
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">TAKE PROFIT (TP)</label>
                                                    <input
                                                        type="number"
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[10px] font-bold font-mono px-2 py-1 rounded"
                                                        value={localSettings.tp}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, tp: parseInt(e.target.value) || 0 })}
                                                    />
                                                </div>
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">STOP LOSS (SL)</label>
                                                    <input
                                                        type="number"
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[10px] font-bold font-mono px-2 py-1 rounded"
                                                        value={localSettings.sl}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, sl: parseInt(e.target.value) || 0 })}
                                                    />
                                                </div>
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">BREAK EVEN (BE)</label>
                                                    <input
                                                        type="number"
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[10px] font-bold font-mono px-2 py-1 rounded"
                                                        value={localSettings.be}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, be: parseInt(e.target.value) || 0 })}
                                                    />
                                                </div>
                                            </div>

                                            <div className="grid grid-cols-2 gap-2">
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">TRAILING (TRA)</label>
                                                    <input
                                                        type="number"
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[10px] font-bold font-mono px-2 py-1 rounded"
                                                        value={localSettings.tra}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, tra: parseInt(e.target.value) || 0 })}
                                                    />
                                                </div>
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">LOOKBACK (LKB)</label>
                                                    <input
                                                        type="number"
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[10px] font-bold font-mono px-2 py-1 rounded"
                                                        value={localSettings.lkb}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, lkb: parseInt(e.target.value) || 0 })}
                                                    />
                                                </div>
                                            </div>

                                            <div className="grid grid-cols-3 gap-2">
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">TF TENDENCIA</label>
                                                    <select
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[8px] font-bold px-1 py-1 rounded"
                                                        value={localSettings.tf_trend}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, tf_trend: e.target.value })}
                                                    >
                                                        {["PERIOD_M5", "PERIOD_M15", "PERIOD_M30", "PERIOD_H1", "PERIOD_H4", "PERIOD_D1"].map((tf) => (
                                                            <option key={tf} value={tf} className="bg-black">{tf.replace("PERIOD_", "")}</option>
                                                        ))}
                                                    </select>
                                                </div>
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">TF FIBONACCI</label>
                                                    <select
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[8px] font-bold px-1 py-1 rounded"
                                                        value={localSettings.tf_fibo}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, tf_fibo: e.target.value })}
                                                    >
                                                        {["PERIOD_M5", "PERIOD_M15", "PERIOD_M30", "PERIOD_H1", "PERIOD_H4", "PERIOD_D1"].map((tf) => (
                                                            <option key={tf} value={tf} className="bg-black">{tf.replace("PERIOD_", "")}</option>
                                                        ))}
                                                    </select>
                                                </div>
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">TF ENTRADA</label>
                                                    <select
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[8px] font-bold px-1 py-1 rounded"
                                                        value={localSettings.tf_entry}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, tf_entry: e.target.value })}
                                                    >
                                                        {["PERIOD_M1", "PERIOD_M5", "PERIOD_M15", "PERIOD_M30", "PERIOD_H1"].map((tf) => (
                                                            <option key={tf} value={tf} className="bg-black">{tf.replace("PERIOD_", "")}</option>
                                                        ))}
                                                    </select>
                                                </div>
                                            </div>

                                            <div className="grid grid-cols-2 gap-2">
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">DIRECCIÓN</label>
                                                    <select
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[9px] font-bold px-2 py-1 rounded"
                                                        value={localSettings.dir}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, dir: parseInt(e.target.value) })}
                                                    >
                                                        <option value={0} className="bg-black">SOLO COMPRAS (BUY)</option>
                                                        <option value={1} className="bg-black">SOLO VENTAS (SELL)</option>
                                                        <option value={2} className="bg-black">BIDIRECCIONAL (BOTH)</option>
                                                    </select>
                                                </div>
                                                <div className="space-y-1">
                                                    <label className="text-[7px] font-bold uppercase text-white/30">MODO OPERATIVO</label>
                                                    <select
                                                        className="w-full bg-white/5 border border-white/10 text-white text-[9px] font-bold px-2 py-1 rounded"
                                                        value={localSettings.mode}
                                                        onChange={(e) => setLocalSettings({ ...localSettings, mode: parseInt(e.target.value) })}
                                                    >
                                                        <option value={0} className="bg-black">SNIPER (CONSERVADOR)</option>
                                                        <option value={1} className="bg-black">MODERADO</option>
                                                        <option value={2} className="bg-black">AGRESIVO</option>
                                                    </select>
                                                </div>
                                            </div>

                                            <div className="flex items-center justify-between p-2 rounded bg-white/5 border border-white/5">
                                                <span className="text-[8px] font-bold uppercase text-white/60">MOSTRAR NARRATIVA</span>
                                                <button
                                                    onClick={() => setLocalSettings({ ...localSettings, insights_on: !localSettings.insights_on })}
                                                    className={`px-2 py-1 rounded text-[7px] font-black uppercase transition-all ${
                                                        localSettings.insights_on 
                                                        ? 'bg-purple-500/20 border border-purple-500 text-purple-300' 
                                                        : 'bg-white/5 border border-white/10 text-white/40'
                                                    }`}
                                                >
                                                    {localSettings.insights_on ? "SÍ" : "NO"}
                                                </button>
                                            </div>
                                        </div>
                                    )}

                                    {/* BANNER COMERCIAL ENCRIPCIÓN PARA CLIENTES NORMALES EN DEMO */}
                                    {!isOwner && (
                                        <div className="p-3 rounded-lg bg-amber-500/10 border border-amber-500/25 flex gap-2 items-start mt-2">
                                            <Lock size={14} className="text-amber-400 shrink-0 mt-0.5" />
                                            <p className="text-[8px] font-bold text-amber-300/90 leading-normal text-left">
                                                🔑 <strong>PROTECCIÓN COGNITIVA ACTIVA:</strong> Los parámetros avanzados del algoritmo institucional (Take Profit, Stop Loss, Break-Even dinámico y timeframes cruzados del núcleo Maiko Engine) se encuentran encriptados bajo caja negra para proteger la estrategia exclusiva de Maiko.
                                            </p>
                                        </div>
                                    )}

                                    {/* BOTONES DE ACCIÓN */}
                                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/5">
                                        <button
                                            onClick={handleResetToSafeConfig}
                                            disabled={loading !== null}
                                            className="flex items-center justify-center gap-1.5 py-2.5 rounded-lg text-[9px] font-black uppercase tracking-wider bg-white/5 hover:bg-white/10 text-white/70 border border-white/10 hover:text-white transition-all disabled:opacity-50"
                                        >
                                            <RotateCcw size={10} />
                                            REINICIAR CONFIG. SEGURA
                                        </button>
                                        <button
                                            onClick={handleApplySettings}
                                            disabled={loading !== null}
                                            className="flex items-center justify-center gap-1.5 py-2.5 rounded-lg text-[9px] font-black uppercase tracking-wider bg-brand hover:bg-brand-light text-white shadow-[0_0_10px_rgba(36,206,203,0.3)] transition-all disabled:opacity-50"
                                        >
                                            <Save size={10} />
                                            {loading === "APPLY" ? "GUARDANDO..." : "GUARDAR Y APLICAR"}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>



                {/* EMERGENCY STOP */}
                <div className="p-4 sm:p-5 bg-black/60 border-t border-white/5">
                    <button 
                        className="w-full flex items-center justify-center gap-3 py-4 sm:py-5 rounded-xl text-xs font-black uppercase tracking-[0.2em] bg-red-600/20 text-red-500 border border-red-500/30 hover:bg-red-600 hover:text-white transition-all group"
                        onClick={() => {
                            if(confirm("🚨 ¿ESTÁS SEGURO? Se cerrarán TODAS las posiciones inmediatamente.")) {
                                sendAction("CLOSE_ALL");
                            }
                        }}
                    >
                        <ShieldAlert size={18} className="group-hover:animate-bounce" />
                        STOP & CLOSE ALL
                    </button>
                    
                    {statusMsg && (
                        <motion.div 
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="mt-4 p-2 text-center bg-brand/10 rounded-lg border border-brand/20"
                        >
                            <p className="text-[8px] font-black text-brand-light uppercase tracking-widest">{statusMsg}</p>
                        </motion.div>
                    )}
                </div>

                {/* FOOTER STATS */}
                <div className="px-4 py-4 bg-white/5 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <Coins size={14} className="text-white/20" />
                        <div>
                            <p className="text-[7px] sm:text-[8px] uppercase font-black text-white/20 tracking-widest">MT5 BALANCE</p>
                            <p className="text-xs sm:text-sm font-black text-white/80">{formatCurrency(botData?.balance || 0)}</p>
                        </div>
                    </div>
                    <div className="text-right">
                        <p className="text-[7px] sm:text-[8px] uppercase font-black text-white/20 tracking-widest">LAST PULSE</p>
                        <p className="text-[9px] sm:text-[10px] font-bold text-white/40 font-mono italic">
                            {(!mounted || !botData?.lastUpdate) ? 'SYSTEM SYNCING' : new Date(botData.lastUpdate).toLocaleTimeString()}
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}
