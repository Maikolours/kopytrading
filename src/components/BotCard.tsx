"use client";

import { memo } from "react";
import { Card, CardHeader, CardContent, CardTitle } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { Copy, CheckCircle2, ShieldCheck, BarChart3 } from "lucide-react";
import { useState } from "react";

interface BotCardProps {
    baseName: string;
    variants: any[];
    selectedIndex: number;
    onSelectVariant: (idx: number) => void;
    theme: any;
    onCopy: (id: string) => void;
    copiedId: string | null;
    isOwner?: boolean;
}

export const BotCard = memo(function BotCard({ 
    baseName, 
    variants, 
    selectedIndex, 
    onSelectVariant, 
    theme, 
    onCopy, 
    copiedId,
    isOwner = false
}: BotCardProps) {
    const purchase = variants[selectedIndex] || variants[0];
    const isMaintenance = purchase.botProduct.status === "MAINTENANCE" && !isOwner;
    
    // Asignar tema visual según el instrumento
    const getBotTheme = (symbol: string) => {
        const s = (symbol || "").toUpperCase();
        if (s.includes("BTC")) return { class: "theme-btc", glow: "shadow-purple-500/30", border: "border-purple-500/40", text: "text-purple-400" };
        if (s.includes("XAU") || s.includes("GOLD")) return { class: "theme-gold", glow: "shadow-amber-500/30", border: "border-amber-500/40", text: "text-amber-400" };
        if (s.includes("EUR")) return { class: "theme-eur", glow: "shadow-emerald-500/30", border: "border-emerald-500/40", text: "text-emerald-400" };
        if (s.includes("JPY")) return { class: "theme-jpy", glow: "shadow-red-500/30", border: "border-red-500/40", text: "text-red-400" };
        return { class: "theme-btc", glow: "shadow-purple-500/30", border: "border-purple-500/40", text: "text-purple-400" };
    };

    const assetTheme = getBotTheme(purchase.botProduct.instrument);
    
    // Detectar tipo de cuenta real sincronizada
    const activeAcc = purchase.activePositions?.[0];
    const isCent = activeAcc?.isCent || purchase.botProduct.name.toUpperCase().includes("CENT") || baseName.toUpperCase().includes("CENT");
    const currency = isCent ? "USC" : "$";

    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
    
    let accountTypeLabel = "CUENTA DEMO";
    let accountTypeColor = "bg-orange-500/20 text-orange-400 border-orange-500/40";
    
    if (hasRealSync) {
        accountTypeLabel = isCent ? "CUENTA REAL (CENT)" : "CUENTA REAL (USD)";
        accountTypeColor = "bg-success/20 text-success border-success/40";
    }
    
    const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);

    return (
        <div className={`animate-in fade-in slide-in-from-bottom-6 duration-700 mb-8 ${assetTheme.class}`}>
            <Card className={`relative overflow-hidden glass-card ${assetTheme.border} bg-surface/60 backdrop-blur-3xl shadow-2xl rounded-[2.5rem] border premium-card-glow`}>
                <div className={`absolute inset-0 bg-gradient-to-b from-[var(--theme-color)]/10 to-[var(--theme-color)]/5 pointer-events-none opacity-40`} />
                
                <CardHeader className="relative z-10 border-b border-white/5 py-3 px-4 sm:px-6">
                    <div className="flex flex-col sm:flex-row justify-between items-start gap-3">
                        <div className="flex-1 w-full">
                            <div className="flex flex-wrap items-center gap-1.5 mb-2">
                                <span className={`px-2 py-0.5 rounded-lg text-[8px] font-black border ${accountTypeColor} tracking-widest uppercase`}>
                                    {accountTypeLabel}
                                </span>
                                <span className={`px-2 py-0.5 rounded-lg text-[8px] font-black border uppercase tracking-widest ${purchase.status === 'TRIAL' ? 'bg-white/5 text-white/60 border-white/10' : 'bg-success/10 text-success border-success/20'}`}>
                                    {purchase.status === 'TRIAL' ? "TRIAL" : "LIFETIME"}
                                </span>
                                <span className="px-2 py-0.5 rounded-lg text-[8px] font-bold bg-white/5 border border-white/5 text-gray-500 tracking-widest uppercase">
                                    {purchase.botProduct.instrument}
                                </span>
                            </div>

                            <CardTitle className="text-lg sm:text-2xl font-black text-white tracking-tighter leading-tight mb-0.5 uppercase">
                                {purchase.botProduct.name}
                            </CardTitle>
                            
                            {variants.length > 1 && (
                                <div className="flex flex-wrap gap-1 mt-2 mb-0.5">
                                    {variants.map((v, idx) => {
                                        const isSel = selectedIndex === idx;
                                        const accountNum = v.activePositions?.[0]?.account;
                                        let label = accountNum ? `Cuenta ${accountNum}` : `${idx+1}`;
                                        const posCount = (v.activePositions || []).length;

                                        return (
                                            <button
                                                key={v.id}
                                                onClick={() => onSelectVariant(idx)}
                                                className={`px-2 py-1 rounded-lg text-[8px] font-black uppercase transition-all border ${
                                                    isSel 
                                                    ? 'bg-white/20 border-white/40 text-white' 
                                                    : 'bg-white/2? border-white/5 text-white/30 hover:bg-white/10'
                                                }`}
                                            >
                                                {label} {posCount > 0 && `(${posCount})`}
                                            </button>
                                        );
                                    })}
                                </div>
                            )}
                        </div>

                        <div className="p-2 px-3 rounded-lg bg-black/40 border border-white/5 flex flex-col items-center justify-center min-w-24 text-center">
                            <span className="text-[7px] font-black uppercase tracking-[0.2em] opacity-40 mb-0">Profit Hoy</span>
                            <span className={`text-base font-black font-mono ${dailyProfit >= 0 ? 'text-success' : 'text-danger'}`}>
                                {dailyProfit >= 0 ? '+' : ''}{dailyProfit.toFixed(2)}{currency}
                            </span>
                        </div>
                    </div>
                </CardHeader>

                <CardContent className="relative z-10 p-3 sm:p-5 space-y-4">
                    <div className="grid lg:grid-cols-1 gap-4">
                        <div className={`space-y-4 ${isMaintenance ? 'blur-md grayscale pointer-events-none opacity-40' : ''}`}>
                            <BotRemoteControl 
                                purchaseId={purchase.id} 
                                botName={purchase.botProduct.name} 
                                account={purchase.activePositions?.[0]?.account || "unknown"}
                                isOnline={purchase.lastSync && (Math.abs(Date.now() - new Date(purchase.lastSync).getTime()) < 300000)}
                                theme={theme}
                                initialData={purchase.botSettings?.[0]?.settings}
                            />

                            <div className="grid sm:grid-cols-2 gap-4">
                                <div className="p-3 rounded-xl bg-white/5 border border-white/10 flex flex-col justify-center">
                                    <h4 className="text-[8px] font-black uppercase tracking-widest text-white/40 mb-2">Software</h4>
                                    <a href={`/api/download/${purchase.id}?type=ex5`}>
                                        <Button fullWidth className="bg-white text-black hover:bg-white/90 font-black tracking-tight px-3 py-2 text-[10px] rounded-lg">
                                            Descargar Sniper v11.3.9 📥
                                        </Button>
                                    </a>
                                </div>

                                <div className="p-3 rounded-xl bg-black/60 border border-brand/20 shadow-xl">
                                    <p className="text-[8px] text-brand-light uppercase tracking-widest font-black mb-2 flex items-center gap-2">
                                        <ShieldCheck size={10} /> Licencia MT5
                                    </p>
                                    <div className="flex items-center gap-1.5">
                                        <code className="text-[10px] font-black font-mono text-white select-all p-2 bg-white/5 rounded border border-white/10 flex-1 truncate">
                                            {purchase.id}
                                        </code>
                                        <Button 
                                            size="sm" 
                                            className="h-9 w-9 p-0 bg-white/5 border border-white/10 text-white"
                                            onClick={() => onCopy(purchase.id)}
                                        >
                                            <Copy size={14} />
                                        </Button>
                                    </div>
                                </div>
                            </div>

                            <div className="flex items-center justify-between gap-2 p-2 rounded-lg bg-white/5 border border-white/5">
                                <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                                <CleanupButton purchaseId={purchase.id} />
                            </div>
                        </div>
                    </div>

                    {/* OPERACIONES ABIERTAS */}
                    {(purchase.activePositions?.length || 0) > 0 && (
                        <div className="space-y-4 mt-6">
                            <h4 className="text-[10px] font-black uppercase tracking-[0.2em] text-white/20 text-center">Monitor de Operaciones</h4>
                            {purchase.activePositions.map((pos: any) => (
                                <div key={pos.id} className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-all">
                                    <div className="flex items-center gap-3">
                                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center text-[10px] font-black ${pos.type === 'BUY' ? 'bg-success/20 text-success' : 'bg-danger/20 text-danger'}`}>
                                            {pos.type === 'BUY' ? 'BUY' : 'SELL'}
                                        </div>
                                        <div>
                                            <span className="text-white font-black text-sm block leading-none">{(pos.lots || 0).toFixed(2)} {pos.symbol}</span>
                                            <span className="text-[9px] text-white/20 font-mono italic">#{pos.ticket}</span>
                                        </div>
                                    </div>
                                    <div className={`text-xl font-black font-mono ${(pos.profit || 0) >= 0 ? 'text-success' : 'text-danger'}`}>
                                        {(pos.profit || 0) >= 0 ? '+' : ''}{(pos.profit || 0).toFixed(2)} {currency}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
});
