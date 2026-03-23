"use client";

import { useState } from "react";
import { Button } from "./ui/Button";

interface BotRemoteControlProps {
    purchaseId: string;
    botName: string;
    isOnline?: boolean;
    theme?: any;
}

export function BotRemoteControl({ purchaseId, botName, isOnline, theme }: BotRemoteControlProps) {
    const [loading, setLoading] = useState<string | null>(null);
    const [statusMsg, setStatusMsg] = useState<string | null>(null);

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

    const [lot, setLot] = useState("0.01");
    const [tf, setTf] = useState("M15");
    const [meta, setMeta] = useState("500");

    const isGoldBot = botName.toLowerCase().includes("oro") || botName.toLowerCase().includes("ametralladora");

    return (
        <div className={`mt-6 p-4 sm:p-5 rounded-2xl bg-black/40 border ${theme?.border || 'border-white/10'} shadow-2xl flex flex-col backdrop-blur-sm`}>
            <div className="flex items-center justify-between mb-4 border-b border-white/10 pb-3">
                <h4 className={`text-xs font-black uppercase tracking-[0.2em] ${theme?.accent || 'text-brand-light'}`}>Control Remoto Live</h4>
                <div className="flex items-center gap-2">
                    <span className={`w-2.5 h-2.5 rounded-full ${isOnline ? 'bg-success animate-pulse' : 'bg-white/20'}`}></span>
                    <span className={`text-[10px] font-black uppercase tracking-tighter ${isOnline ? 'text-success' : 'text-white/40'}`}>
                        {isOnline ? 'CONECTADO' : 'DESCONECTADO'}
                    </span>
                </div>
            </div>

            {/* Fila de Modos (Zen/Cosecha) */}
            {isGoldBot && (
                <div className="grid grid-cols-2 gap-3 mb-6">
                    <Button 
                        variant="outline" 
                        size="sm" 
                        className="bg-amber-500/10 border-amber-500/30 hover:bg-amber-500/20 text-[10px] font-bold py-3 text-amber-400"
                        onClick={() => sendCommand("CHANGE_MODE", "ZEN")}
                        loading={loading === "CHANGE_MODE" && statusMsg?.includes("ZEN")}
                    >
                        🧘 MODO ZEN
                    </Button>
                    <Button 
                        variant="outline" 
                        size="sm" 
                        className="bg-emerald-500/10 border-emerald-500/30 hover:bg-emerald-500/20 text-[10px] font-bold py-3 text-emerald-400"
                        onClick={() => sendCommand("CHANGE_MODE", "COSECHA")}
                        loading={loading === "CHANGE_MODE" && statusMsg?.includes("COSECHA")}
                    >
                        🚜 COSECHA
                    </Button>
                </div>
            )}

            {/* CONFIGURACION PRO */}
            <div className="space-y-4 mb-6 p-4 rounded-xl bg-black/40 border border-white/5">
                <p className="text-[10px] font-black uppercase tracking-widest opacity-40 mb-2">Configuración Pro</p>
                
                {/* Lotes */}
                <div className="flex items-center gap-2">
                    <div className="flex-1">
                        <label className="text-[9px] uppercase opacity-50 block mb-1">Lote Base</label>
                        <input 
                            type="number" 
                            step="0.01"
                            value={lot}
                            onChange={(e) => setLot(e.target.value)}
                            className="w-full bg-black/60 border border-white/10 rounded-lg px-3 py-2 text-xs text-white focus:border-brand-light outline-none"
                        />
                    </div>
                    <Button 
                        size="sm" 
                        variant="outline" 
                        className="mt-4 py-2 border-white/20 text-[9px]"
                        onClick={() => sendCommand("SET_LOTS", lot)}
                        loading={loading === "SET_LOTS"}
                    >
                        SET
                    </Button>
                </div>

                {/* Temporalidad */}
                <div className="flex items-center gap-2">
                    <div className="flex-1">
                        <label className="text-[9px] uppercase opacity-50 block mb-1">Temporalidad</label>
                        <select 
                            value={tf}
                            onChange={(e) => setTf(e.target.value)}
                            className="w-full bg-black/60 border border-white/20 rounded-lg px-3 py-2 text-xs text-white outline-none"
                        >
                            <option value="M1">M1 (Scalping)</option>
                            <option value="M5">M5 (Rápido)</option>
                            <option value="M15">M15 (Estándar)</option>
                            <option value="M30">M30 (Seguro)</option>
                            <option value="H1">H1 (Swing)</option>
                        </select>
                    </div>
                    <Button 
                        size="sm" 
                        variant="outline" 
                        className="mt-4 py-2 border-white/20 text-[9px]"
                        onClick={() => sendCommand("SET_TIMEFRAME", tf)}
                        loading={loading === "SET_TIMEFRAME"}
                    >
                        SET
                    </Button>
                </div>

                {/* Meta Diaria */}
                <div className="flex items-center gap-2">
                    <div className="flex-1">
                        <label className="text-[9px] uppercase opacity-50 block mb-1">Meta Diaria (Unidades)</label>
                        <input 
                            type="number" 
                            value={meta}
                            onChange={(e) => setMeta(e.target.value)}
                            className="w-full bg-black/60 border border-white/10 rounded-lg px-3 py-2 text-xs text-white focus:border-brand-light outline-none"
                        />
                    </div>
                    <Button 
                        size="sm" 
                        variant="outline" 
                        className="mt-4 py-2 border-white/20 text-[9px]"
                        onClick={() => sendCommand("SET_META", meta)}
                        loading={loading === "SET_META"}
                    >
                        SET
                    </Button>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-3 mb-4">
                <Button 
                    variant="outline" 
                    size="sm" 
                    className="border-white/10 hover:bg-white/5 text-[10px] font-bold py-3"
                    onClick={() => sendCommand("PAUSE")}
                    loading={loading === "PAUSE"}
                >
                    🛑 PAUSAR BOT
                </Button>
                <Button 
                    variant="outline" 
                    size="sm" 
                    className="border-white/10 hover:bg-white/5 text-[10px] font-bold py-3 text-success hover:border-success/50"
                    onClick={() => sendCommand("RESUME")}
                    loading={loading === "RESUME"}
                >
                    ▶️ REANUDAR
                </Button>
            </div>

            <div className="grid grid-cols-2 gap-3 mb-6">
                 <Button 
                    variant="outline" 
                    size="sm" 
                    className={`bg-white/5 border-white/10 hover:border-brand text-[9px] font-black uppercase tracking-widest py-3 ${theme?.accent}`}
                    onClick={() => sendCommand("DIRECTION", "BUY")}
                >
                    SOLO BUY
                </Button>
                <Button 
                    variant="outline" 
                    size="sm" 
                    className={`bg-white/5 border-white/10 hover:border-brand text-[9px] font-black uppercase tracking-widest py-3 ${theme?.accent}`}
                    onClick={() => sendCommand("DIRECTION", "SELL")}
                >
                    SOLO SELL
                </Button>
            </div>
            
            <div className="mt-auto">
                <Button 
                    variant="danger" 
                    size="sm" 
                    fullWidth
                    className="text-[10px] font-black uppercase tracking-widest shadow-lg shadow-danger/20 py-4"
                    onClick={() => {
                        if(confirm("¿Estás seguro? Esto cerrará todas las posiciones abiertas del bot inmediatamente.")) {
                            sendCommand("CLOSE_ALL");
                        }
                    }}
                    loading={loading === "CLOSE_ALL"}
                >
                    🔥 CIERRE DE EMERGENCIA TOTAL
                </Button>
            </div>

            {statusMsg && (
                <div className="mt-4 p-2 text-center bg-white/5 rounded-lg border border-white/5 animate-in fade-in slide-in-from-bottom-2">
                    <p className="text-[10px] font-medium text-brand-light uppercase tracking-wider">{statusMsg}</p>
                </div>
            )}

            <div className="mt-4 pt-3 border-t border-white/5 text-[9px] text-text-muted/60 text-center italic leading-tight">
                El bot sincroniza cambios cada 30 segundos.<br/>
                Para control instantáneo use Telegram.
            </div>
        </div>
    );
}
