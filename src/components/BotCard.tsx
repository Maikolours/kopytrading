"use client";

import { memo } from "react";
import { Card, CardHeader, CardContent, CardTitle } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { Copy, CheckCircle2, ShieldCheck } from "lucide-react";

interface BotCardProps {
    baseName: string;
    variants: any[];
    selectedIndex: number;
    onSelectVariant: (idx: number) => void;
    theme: any;
    onCopy: (id: string) => void;
    copiedId: string | null;
}

export const BotCard = memo(function BotCard({ 
    baseName, 
    variants, 
    selectedIndex, 
    onSelectVariant, 
    theme, 
    onCopy, 
    copiedId 
}: BotCardProps) {
    const purchase = variants[selectedIndex] || variants[0];
    const isTrial = purchase.status === "TRIAL";
    const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
    const accountTypeLabel = hasRealSync ? "CUENTA REAL" : "CUENTA DEMO";
    const accountTypeColor = hasRealSync ? "bg-success/20 text-success border-success/40" : "bg-orange-500/20 text-orange-400 border-orange-500/40";
    
    const normalizeVer = (v: string) => parseFloat(v.replace(/[^0-9.]/g, '')) || 0;
    // const hasUpdate = normalizeVer(purchase.botProduct.version) > normalizeVer(purchase.lastDownloadedVersion || "0.0");

    return (
        <div className="animate-in fade-in slide-in-from-bottom-4 duration-500 mb-6">
            <Card className={`relative overflow-hidden glass-card ${theme.border} bg-black/95 shadow-2xl rounded-2xl border`}>
                <div className={`absolute inset-0 bg-gradient-to-b ${theme.gradient} pointer-events-none opacity-30`} />
                
                <CardHeader className="relative z-10 border-b border-white/5 py-4 px-5 sm:px-6">
                    <div className="flex flex-col sm:flex-row justify-between items-start gap-3">
                        <div className="flex-1">
                            <div className="flex flex-wrap items-center gap-2 mb-3">
                                <span className={`px-2.5 py-1 rounded-lg text-[9px] font-black border ${accountTypeColor} tracking-widest uppercase`}>
                                    {accountTypeLabel}
                                </span>
                                <span className={`px-2.5 py-1 rounded-lg text-[9px] font-black border uppercase tracking-widest ${isTrial ? 'bg-white/5 text-white/60 border-white/10' : 'bg-success/10 text-success border-success/20'}`}>
                                    {isTrial ? "TRIAL" : "LIFETIME"}
                                </span>
                                <span className="px-2.5 py-1 rounded-lg text-[9px] font-bold bg-white/5 border border-white/5 text-gray-500 tracking-widest uppercase">
                                    {purchase.botProduct.instrument}
                                </span>
                            </div>

                            <CardTitle className="text-xl sm:text-2xl font-black text-white tracking-tighter leading-tight mb-1 uppercase">
                                {purchase.botProduct.name}
                            </CardTitle>
                            
                            {/* SWITCHER DE VARIANTES */}
                            {variants.length > 1 && (
                                <div className="flex flex-wrap gap-1.5 mt-3 mb-1">
                                    {variants.map((v, idx) => {
                                        const isSel = selectedIndex === idx;
                                        const vName = (v.botProduct.name || "").toUpperCase();
                                        let label = vName.includes("CENT") ? "CENT" : (vName.includes("ULTRA") ? "ULTRA" : `LIC ${idx+1}`);
                                        
                                        const posCount = (v.activePositions || []).length;
                                        const hasActiveOps = posCount > 0;

                                        return (
                                            <button
                                                key={v.id}
                                                onClick={() => onSelectVariant(idx)}
                                                className={`px-3 py-1.5 rounded-lg text-[9px] font-black uppercase transition-all border-2 relative ${
                                                    isSel 
                                                    ? 'bg-white/20 border-white/40 text-white shadow-xl' 
                                                    : 'bg-white/5 border-white/5 text-white/30 hover:bg-white/10'
                                                } ${hasActiveOps && !isSel ? 'border-amber-500/30' : ''}`}
                                            >
                                                <span className="flex items-center gap-1.5">
                                                    {label}
                                                    {hasActiveOps && (
                                                        <span className={`inline-flex items-center justify-center w-3.5 h-3.5 rounded-full text-[8px] ${isSel ? 'bg-amber-500 text-black' : 'bg-amber-500/20 text-amber-500'} font-bold`}>
                                                            {posCount}
                                                        </span>
                                                    )}
                                                </span>
                                                {hasActiveOps && !isSel && (
                                                    <span className="absolute -top-1 -right-1 w-2 h-2 bg-amber-500 rounded-full animate-ping" />
                                                )}
                                            </button>
                                        );
                                    })}
                                </div>
                            )}
                        </div>

                        <div className="w-full sm:w-auto p-3 px-5 rounded-xl bg-black/40 border border-white/5 flex flex-col items-center justify-center min-w-28 text-center">
                            <span className="text-[8px] font-black uppercase tracking-[0.2em] opacity-40 mb-0.5">Hoy</span>
                            <span className={`text-xl font-black font-mono ${dailyProfit >= 0 ? 'text-success' : 'text-danger'}`}>
                                {dailyProfit >= 0 ? '+' : ''}{dailyProfit.toFixed(2)} $
                            </span>
                        </div>
                    </div>
                </CardHeader>

                <CardContent className="relative z-10 p-4 sm:p-5 space-y-6">
                    <div className="grid lg:grid-cols-2 gap-6">
                        <div className="space-y-4">
                            <BotRemoteControl 
                                purchaseId={purchase.id} 
                                botName={purchase.botProduct.name} 
                                isOnline={purchase.lastSync && (new Date().getTime() - new Date(purchase.lastSync).getTime()) < 150000}
                                theme={theme}
                            />
                            
                            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 p-3 rounded-xl bg-white/5 border border-white/5">
                                <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                                <CleanupButton purchaseId={purchase.id} />
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="p-4 rounded-xl bg-gradient-to-br from-white/5 to-transparent border border-white/5">
                                <h4 className="text-[9px] font-black uppercase tracking-widest text-white/40 mb-3 text-center sm:text-left">Instalación</h4>
                                <div className="flex flex-col gap-2">
                                    <a href={`/api/download/${purchase.id}?type=ex5`} className="group">
                                        <Button fullWidth className="bg-white text-black hover:bg-white/90 font-black tracking-tight flex items-center justify-between px-5 py-3 h-auto rounded-lg">
                                            <div className="text-left leading-tight">
                                                 <div className="text-[10px] uppercase font-black">Descargar (.EX5)</div>
                                                 <div className="text-[8px] opacity-60 font-bold tracking-tighter">VERSIÓN {purchase.botProduct.version}</div>
                                            </div>
                                            <span className="text-base group-hover:translate-x-0.5 transition-transform font-none">📥</span>
                                        </Button>
                                    </a>
                                </div>
                            </div>

                            <div className="p-4 rounded-xl bg-black/40 border-l-2 border-brand-light shadow-xl">
                                <p className="text-[8px] text-text-muted/60 uppercase tracking-widest mb-1.5 font-black">Licencia ID</p>
                                <div className="flex items-center gap-2">
                                    <code className="text-[11px] font-black font-mono text-brand-light select-all break-all tracking-tighter uppercase p-1.5 bg-white/5 rounded flex-1">
                                        {purchase.id}
                                    </code>
                                    <Button 
                                        size="sm" 
                                        className={`transition-all h-8 w-8 p-0 flex items-center justify-center shrink-0 rounded-md ${copiedId === purchase.id ? 'bg-success text-white' : 'bg-white/10 text-white hover:bg-white/20'}`}
                                        onClick={() => onCopy(purchase.id)}
                                    >
                                        {copiedId === purchase.id ? <CheckCircle2 size={12} /> : <Copy size={12} />}
                                    </Button>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* OPERACIONES ABIERTAS - AGRUPADAS POR CUENTA */}
                    {(purchase.activePositions?.length || 0) > 0 && (
                        <div className="space-y-6">
                            {Object.entries(
                                purchase.activePositions.reduce((acc: any, pos: any) => {
                                    if (!acc[pos.account]) acc[pos.account] = [];
                                    acc[pos.account].push(pos);
                                    return acc;
                                }, {})
                            ).map(([account, posList]: [string, any]) => {
                                const detectedVersion = posList[0]?.id?.toString().includes("5.90") ? "v5.90" : (posList[0]?.id?.toString().includes("5.84") ? "v5.84" : null);

                                return (
                                    <div key={account} className="p-4 rounded-2xl bg-black/40 border border-white/5 shadow-2xl overflow-hidden relative">
                                        <div className="absolute top-0 right-0 p-3">
                                            <div className="flex flex-col items-end">
                                                <span className="text-[8px] font-black text-brand-light/40 uppercase tracking-widest">Estado</span>
                                                <span className="text-[10px] font-black text-success flex items-center gap-1.5">
                                                    <div className="w-1.5 h-1.5 bg-success rounded-full animate-pulse" />
                                                    SYNC OK
                                                </span>
                                            </div>
                                        </div>

                                        <div className="flex items-center gap-3 mb-5 border-b border-white/5 pb-3">
                                            <div className="w-10 h-10 rounded-xl bg-brand-light/10 border border-brand-light/20 flex items-center justify-center">
                                                <ShieldCheck className="text-brand-light" size={20} />
                                            </div>
                                            <div>
                                                <h4 className="text-xs font-black text-white uppercase tracking-tight flex items-center gap-2">
                                                    Cuenta: <span className="bg-brand-light/20 px-2 py-0.5 rounded text-[10px] font-mono">{account}</span>
                                                </h4>
                                                <p className="text-[9px] text-text-muted/60 font-black uppercase tracking-widest mt-1">
                                                    {posList.length} Operaciones Activas • {detectedVersion || "Bot Evolution"}
                                                </p>
                                            </div>
                                        </div>

                                        <div className="space-y-3">
                                            {posList.map((pos: any) => (
                                                <div key={pos.id} className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-all group">
                                                    <div className="flex items-center gap-3">
                                                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center text-[10px] font-black ${pos.type === 'BUY' ? 'bg-success/20 text-success' : 'bg-danger/20 text-danger'}`}>
                                                            {pos.type === 'BUY' ? 'BUY' : 'SELL'}
                                                        </div>
                                                        <div>
                                                            <div className="flex items-center gap-2">
                                                                <span className="text-white font-black text-sm leading-none">{(pos.lots || 0).toFixed(2)} {pos.symbol}</span>
                                                                <span className="text-[9px] opacity-20 font-mono italic">#{pos.ticket || "SYNC"}</span>
                                                            </div>
                                                            <div className="text-[10px] text-text-muted/60 mt-0.5 uppercase font-black tracking-widest">
                                                                Precio: <span className="text-white/60 font-mono">@{(pos.openPrice || 0).toFixed(2)}</span>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className={`text-xl font-black font-mono ${(pos.profit || 0) >= 0 ? 'text-success' : 'text-danger'}`}>
                                                        {(pos.profit || 0) >= 0 ? '+' : ''}{(pos.profit || 0).toFixed(2)} $
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    )}

                    {/* HISTORIAL - AGRUPADO POR CUENTA */}
                    {(purchase.pastTrades?.length || 0) > 0 && (
                        <div className="space-y-4">
                            {Object.entries(
                                purchase.pastTrades.reduce((acc: any, h: any) => {
                                    if (!acc[h.account]) acc[h.account] = [];
                                    acc[h.account].push(h);
                                    return acc;
                                }, {})
                            ).map(([account, historyList]: [string, any]) => (
                                <div key={account} className="p-4 rounded-2xl bg-black/20 border border-white/5">
                                    <h4 className="text-[8px] font-black uppercase tracking-[0.2em] text-text-muted/40 mb-3">
                                        Cierres Cuenta: {account}
                                    </h4>
                                    <div className="space-y-1.5 font-mono">
                                        {historyList.map((h: any) => (
                                            <div key={h.id} className="flex items-center justify-between py-2 px-3 rounded-lg bg-white/[0.02] hover:bg-white/[0.05] transition-all">
                                                <div className="flex items-center gap-3">
                                                    <span className={`font-black w-6 text-xs ${h.type === 'BUY' ? 'text-success' : 'text-danger'}`}>{h.type === 'BUY' ? 'B' : 'S'}</span>
                                                    <div className="flex items-center gap-3 text-white">
                                                        <span className="text-xs font-black">{(h.lots || 0).toFixed(2)}</span>
                                                        <span className="text-[10px] opacity-40">{h.symbol}</span>
                                                        <span className="text-[9px] opacity-20 hidden sm:inline italic">#{h.ticket}</span>
                                                    </div>
                                                </div>
                                                <div className={`font-black text-sm ${(h.profit || 0) >= 0 ? 'text-success' : 'text-danger'}`}>
                                                    {(h.profit || 0) >= 0 ? '+' : ''}{(h.profit || 0).toFixed(2)} $
                                                </div>
                                            </div>
                                        ))}
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
