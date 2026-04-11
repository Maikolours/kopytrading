"use client";

import { memo } from "react";
import { Card, CardHeader, CardContent, CardTitle } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { Copy, CheckCircle2, ShieldCheck, BarChart3 } from "lucide-react";
import { useState } from "react";
import TradingViewChart from "./TradingViewChart";
import { OperativoChart } from "./OperativoChart";

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
    
    const getBotTheme = (symbol: string) => {
        const s = (symbol || "").toUpperCase();
        if (s.includes("BTC")) return { class: "theme-btc", border: "border-purple-500/40", text: "text-purple-400" };
        if (s.includes("XAU") || s.includes("GOLD")) return { class: "theme-gold", border: "border-amber-500/40", text: "text-amber-400" };
        return { class: "theme-btc", border: "border-purple-500/40", text: "text-purple-400" };
    };

    const assetTheme = getBotTheme(purchase.botProduct.instrument);
    const activeAcc = purchase.activePositions?.[0];
    const isCent = activeAcc?.isCent || purchase.botProduct.name.toUpperCase().includes("CENT") || baseName.toUpperCase().includes("CENT");
    const currency = isCent ? "USC" : "$";
    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
    
    let accountTypeLabel = hasRealSync ? (isCent ? "CUENTA REAL (CENT)" : "CUENTA REAL (USD)") : "CUENTA DEMO";
    let accountTypeColor = hasRealSync ? "bg-success/20 text-success border-success/40" : "bg-orange-500/20 text-orange-400 border-orange-500/40";
    
    const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
    const isGold = purchase.botProduct.name.toLowerCase().includes("gold") || purchase.botProduct.name.toLowerCase().includes("ametra");
    const isSniper = purchase.botProduct.name.toLowerCase().includes("v11") || purchase.botProduct.name.toLowerCase().includes("sniper") || isGold;

    return (
        <div className={`animate-in fade-in slide-in-from-bottom-6 duration-700 mb-8 ${assetTheme.class}`}>
            <Card className={`relative overflow-hidden glass-card ${assetTheme.border} bg-surface/60 backdrop-blur-3xl shadow-2xl rounded-[2.5rem] border`}>
                <div className="absolute inset-0 bg-gradient-to-b from-[var(--theme-color)]/10 to-[var(--theme-color)]/5 pointer-events-none opacity-40" />
                
                <CardHeader className="relative z-10 border-b border-white/5 py-3 px-4 sm:px-6">
                    <div className="flex flex-col sm:flex-row justify-between items-start gap-3">
                        <div className="flex-1">
                            <div className="flex flex-wrap items-center gap-1.5 mb-2">
                                <span className={`px-2 py-0.5 rounded-lg text-[8px] font-black border ${accountTypeColor} tracking-widest uppercase`}>
                                    {accountTypeLabel}
                                </span>
                            </div>
                            <CardTitle className="text-lg sm:text-2xl font-black text-white tracking-tighter uppercase">
                                {isGold ? "Elite Gold Ametralladora ⚡" : 
                                 purchase.botProduct.instrument === 'BTCUSD' ? "Elite Sniper v13 ⚡" : 
                                 purchase.botProduct.name}
                            </CardTitle>
                        </div>
                        <div className="p-2 px-3 rounded-lg bg-black/40 border border-white/5 text-center">
                            <span className="text-[7px] font-black uppercase opacity-40">Profit Hoy</span>
                            <div className={`text-base font-black ${dailyProfit >= 0 ? 'text-success' : 'text-danger'}`}>
                                {dailyProfit.toFixed(2)}{currency}
                            </div>
                        </div>
                    </div>
                </CardHeader>

                <CardContent className="relative z-10 p-3 sm:p-5 space-y-4">
                    <div className="grid lg:grid-cols-2 gap-4">
                        <div className={isMaintenance ? 'blur-md grayscale opacity-40' : ''}>
                            <BotRemoteControl 
                                purchaseId={purchase.id} 
                                botName={purchase.botProduct.name} 
                                account={purchase.activePositions?.[0]?.account || "unknown"}
                                isOnline={purchase.lastSync && (Math.abs(Date.now() - new Date(purchase.lastSync).getTime()) < 300000)}
                                theme={theme}
                            />
                        </div>

                        <div className="space-y-4">
                            {isSniper ? (
                                <OperativoChart 
                                    symbol={purchase.botProduct.instrument}
                                    purchaseId={purchase.id}
                                    account={purchase.activePositions?.[0]?.account || "unknown"}
                                    theme={theme}
                                />
                            ) : (
                                <TradingViewChart symbol={purchase.botProduct.instrument.includes("XAU") ? "OANDA:XAUUSD" : "BINANCE:BTCUSDT"} />
                            )}
                            
                            <div className="p-3 rounded-xl bg-black/60 border border-brand/20 shadow-xl">
                                <p className="text-[8px] text-brand-light uppercase tracking-widest font-black mb-2 flex items-center gap-2">
                                    LICENCIA MT5
                                </p>
                                <div className="flex items-center gap-1.5">
                                    <code className="text-[10px] font-black font-mono text-white select-all p-2 bg-white/5 rounded border border-white/10 flex-1 truncate">
                                        {purchase.id}
                                    </code>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="flex items-center justify-between gap-2 p-2 rounded-lg bg-white/5 border border-white/5">
                        <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                        <CleanupButton purchaseId={purchase.id} />
                    </div>
                </CardContent>
            </Card>
        </div>
    );
});
