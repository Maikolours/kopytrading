"use client";

import { memo } from "react";
import { Card, CardHeader, CardContent, CardTitle } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { Copy, CheckCircle2 } from "lucide-react";
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
    // Protección de datos: Si no hay variantes, no renderizamos para evitar crash
    if (!variants || variants.length === 0) return null;

    const purchase = variants[selectedIndex] || variants[0];
    const botProduct = purchase?.botProduct || { name: "Bot Desconocido", instrument: "UNKNOWN", status: "ACTIVE" };
    
    const isMaintenance = botProduct.status === "MAINTENANCE" && !isOwner;
    
    const getBotTheme = (symbol: string) => {
        const s = (symbol || "").toUpperCase();
        if (s.includes("BTC")) return { class: "theme-btc", border: "border-purple-500/40", text: "text-purple-400" };
        if (s.includes("XAU") || s.includes("GOLD")) return { class: "theme-gold", border: "border-amber-500/40", text: "text-amber-400" };
        return { class: "theme-btc", border: "border-purple-500/40", text: "text-purple-400" };
    };

    const assetTheme = getBotTheme(botProduct.instrument);
    const activeAcc = purchase?.activePositions?.[0];
    const isCent = activeAcc?.isCent || botProduct.name.toUpperCase().includes("CENT") || baseName.toUpperCase().includes("CENT");
    const currency = isCent ? "USC" : "$";
    const hasRealSync = (purchase?.activePositions || []).some((pos: any) => pos.isReal);
    
    let accountTypeLabel = hasRealSync ? (isCent ? "CUENTA REAL (CENT)" : "CUENTA REAL (USD)") : "CUENTA DEMO";
    let accountTypeColor = hasRealSync ? "bg-success/20 text-success border-success/40" : "bg-orange-500/20 text-orange-400 border-orange-500/40";
    
    const dailyProfit = (purchase?.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
    const isGold = botProduct.name.toLowerCase().includes("gold") || botProduct.name.toLowerCase().includes("ametra");
    const botDisplayName = isGold ? "ELITE GOLD AMETRALLADORA" : 
                           (botProduct.instrument.includes('BTC') || botProduct.name.includes('SNIPER')) ? "ELITE SNIPER v13" : 
                           botProduct.name;

    // Formateo seguro para balance y equidad
    const balance = purchase?.balance !== null && purchase?.balance !== undefined ? Number(purchase.balance) : null;
    const equity = purchase?.equity !== null && purchase?.equity !== undefined ? Number(purchase.equity) : null;
    const isSyncing = !balance && purchase?.lastStatus === "CARGANDO...";

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
                                {purchase?.lastStatus && (
                                    <span className={`px-2.5 py-1 rounded-lg text-[9px] font-black border uppercase tracking-widest flex items-center gap-1.5 ${
                                        purchase.lastStatus === 'FUEGO' ? 'bg-orange-500/20 text-orange-400 border-orange-500/40 animate-pulse' : 
                                        purchase.lastStatus === 'PAUSA' ? 'bg-danger/20 text-danger border-danger/40' :
                                        isSyncing ? 'bg-brand/20 text-brand-light border-brand/40 animate-pulse' :
                                        'bg-brand-light/20 text-brand-light border-brand-light/40'
                                    }`}>
                                        <div className={`w-1 h-1 rounded-full ${purchase.lastStatus === 'FUEGO' || isSyncing ? 'bg-brand-light' : 'bg-current'} animate-pulse`} />
                                        {isSyncing ? 'SINCRONIZANDO DATOS...' : purchase.lastStatus}
                                    </span>
                                )}
                                <span className="px-2.5 py-1 rounded-lg text-[9px] font-bold bg-white/5 border border-white/5 text-gray-500 tracking-widest uppercase">
                                    {botProduct.instrument}
                                </span>
                            </div>
                            <CardTitle className="text-lg sm:text-2xl font-black text-white tracking-tighter uppercase">
                                {botDisplayName}
                            </CardTitle>
                        </div>

                        <div className="flex flex-col items-end gap-2">
                            <div className="flex gap-2">
                                {balance !== null && (
                                    <div className="p-2 px-3 rounded-lg bg-white/5 border border-white/5 flex flex-col items-center justify-center min-w-20 text-center premium-glass">
                                        <span className="text-[7px] font-black uppercase tracking-[0.2em] opacity-40 mb-0.5">Balance</span>
                                        <span className="text-sm font-black text-white font-mono">
                                            {balance.toFixed(2)}
                                        </span>
                                    </div>
                                )}
                                {equity !== null && (
                                    <div className="p-2 px-3 rounded-lg bg-brand-light/10 border border-brand-light/20 flex flex-col items-center justify-center min-w-20 text-center premium-glass">
                                        <span className="text-[7px] font-black uppercase tracking-[0.2em] text-brand-light/40 mb-0.5">Equidad</span>
                                        <span className="text-sm font-black text-brand-light font-mono">
                                            {equity.toFixed(2)}
                                        </span>
                                    </div>
                                )}
                                <div className="p-3 px-5 rounded-xl bg-black/40 border border-white/5 flex flex-col items-center justify-center min-w-28 text-center premium-glass shadow-purple-500/10">
                                    <span className="text-[8px] font-black uppercase tracking-[0.2em] opacity-40 mb-0.5">Profit Hoy</span>
                                    <span className={`text-xl font-black font-mono ${dailyProfit >= 0 ? 'text-success' : 'text-danger'}`}>
                                        {dailyProfit >= 0 ? '+' : ''}{dailyProfit.toFixed(2)} {currency}
                                    </span>
                                </div>
                            </div>
                            
                            <div className={`flex items-center gap-2 p-1.5 px-3 rounded-lg bg-white/5 border ${assetTheme.border} animate-pulse-glow-heavy`}>
                                <span className={`text-[8px] font-black uppercase tracking-widest ${assetTheme.text}`}>ID:</span>
                                <code className="text-[10px] font-black font-mono text-white select-all">
                                    {purchase?.id?.slice(0, 8) || "unknown"}...
                                </code>
                                <Button 
                                    size="sm" 
                                    className={`h-5 w-5 p-0 flex items-center justify-center shrink-0 rounded ${copiedId === purchase?.id ? 'bg-success text-white' : 'bg-white/10 text-white hover:bg-white/20'}`}
                                    onClick={() => onCopy(purchase?.id || "")}
                                >
                                    {copiedId === purchase?.id ? <CheckCircle2 size={10} /> : <Copy size={10} />}
                                </Button>
                            </div>
                        </div>
                    </div>
                </CardHeader>

                <CardContent className="relative z-10 p-3 sm:p-5 space-y-4">
                    <div className="grid lg:grid-cols-2 gap-4">
                        <div className={isMaintenance ? 'blur-md grayscale opacity-40' : ''}>
                            <BotRemoteControl 
                                purchaseId={purchase?.id || "unknown"} 
                                botName={botDisplayName} 
                                account={purchase?.activePositions?.[0]?.account || "unknown"}
                                isOnline={purchase?.lastSync && (Math.abs(Date.now() - new Date(purchase.lastSync).getTime()) < 300000)}
                                theme={theme}
                            />
                        </div>

                        <div className="space-y-4">
                            <OperativoChart 
                                symbol={botProduct.instrument || (isGold ? "XAUUSD" : "BTCUSDT")}
                                purchaseId={purchase?.id || "unknown"}
                                account={purchase?.activePositions?.[0]?.account || "unknown"}
                                theme={theme}
                                activePositions={purchase?.activePositions || []}
                            />
                            
                            <div className="p-3 rounded-xl bg-black/60 border border-brand/20 shadow-xl">
                                <p className="text-[8px] text-brand-light uppercase tracking-widest font-black mb-2 flex items-center gap-2">
                                    LICENCIA MT5
                                </p>
                                <div className="flex items-center gap-1.5">
                                    <code className="text-[10px] font-black font-mono text-white select-all p-2 bg-white/5 rounded border border-white/10 flex-1 truncate">
                                        {purchase?.id || "N/A"}
                                    </code>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="flex items-center justify-between gap-2 p-2 rounded-lg bg-white/5 border border-white/5">
                        <SyncStatus initialLastSync={purchase?.lastSync ? String(purchase.lastSync) : null} />
                        <CleanupButton purchaseId={purchase?.id || "unknown"} />
                    </div>
                </CardContent>
            </Card>
        </div>
    );
});
