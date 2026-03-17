"use client";

import { useState } from "react";
import { Button } from "./ui/Button";

interface BotRemoteControlProps {
    purchaseId: string;
    botName: string;
}

export function BotRemoteControl({ purchaseId, botName }: BotRemoteControlProps) {
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

    const isGoldBot = botName.toLowerCase().includes("oro") || botName.toLowerCase().includes("ametralladora");

    return (
        <div className="mt-6 p-5 rounded-2xl bg-black/40 border border-white/10 shadow-inner">
            <div className="flex items-center justify-between mb-4 border-b border-white/5 pb-3">
                <h4 className="text-xs font-black uppercase tracking-[0.2em] text-brand-light">Control Remoto Live</h4>
                <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-success animate-pulse"></span>
                    <span className="text-[10px] font-bold text-success uppercase">Bot Vinculado</span>
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

            {isGoldBot && (
                <div className="grid grid-cols-2 gap-3 mb-4">
                    <Button 
                        variant="outline" 
                        size="sm" 
                        className="bg-brand/5 border-brand/20 hover:bg-brand/10 text-[10px] font-bold py-3"
                        onClick={() => sendCommand("CHANGE_MODE", "ZEN")}
                        loading={loading === "CHANGE_MODE" && statusMsg?.includes("ZEN")}
                    >
                        🧘 MODO ZEN
                    </Button>
                    <Button 
                        variant="outline" 
                        size="sm" 
                        className="bg-orange-500/5 border-orange-500/20 hover:bg-orange-500/10 text-[10px] font-bold py-3 text-orange-400"
                        onClick={() => sendCommand("CHANGE_MODE", "COSECHA")}
                        loading={loading === "CHANGE_MODE" && statusMsg?.includes("COSECHA")}
                    >
                        🚜 COSECHA
                    </Button>
                </div>
            )}

            <div className="space-y-3">
                <div className="flex gap-2">
                     <Button 
                        variant="outline" 
                        size="sm" 
                        className="flex-1 border-white/10 hover:bg-white/5 text-[9px] font-black uppercase tracking-widest"
                        onClick={() => sendCommand("DIRECTION", "BUY")}
                    >
                        SOLO BUY
                    </Button>
                    <Button 
                        variant="outline" 
                        size="sm" 
                        className="flex-1 border-white/10 hover:bg-white/5 text-[9px] font-black uppercase tracking-widest"
                        onClick={() => sendCommand("DIRECTION", "SELL")}
                    >
                        SOLO SELL
                    </Button>
                </div>
                
                <Button 
                    variant="danger" 
                    size="sm" 
                    fullWidth
                    className="text-[10px] font-black uppercase tracking-widest shadow-lg shadow-danger/20"
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
