"use client";

import { memo } from "react";
import { Card, CardHeader, CardContent, CardTitle } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { BotSettings } from "./BotSettings";
import { Copy, CheckCircle2, ShieldCheck, Settings2 } from "lucide-react";
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
    const [showSettings, setShowSettings] = useState(false);
    const purchase = variants[selectedIndex] || variants[0];
    const isTrial = purchase.status === "TRIAL";
    const isMaintenance = purchase.botProduct.status === "MAINTENANCE" && !isOwner;
    
    // Asignar tema visual según el instrumento
    const getBotTheme = (symbol: string) => {
        const s = (symbol || "").toUpperCase();
        if (s.includes("BTC")) return { class: "theme-btc", glow: "shadow-purple-500/30", border: "border-purple-500/40", text: "text-purple-400" };
        if (s.includes("XAU") || s.includes("GOLD")) return { class: "theme-gold", glow: "shadow-amber-500/30", border: "border-amber-500/40", text: "text-amber-400" };
        if (s.includes("EUR")) return { class: "theme-eur", glow: "shadow-emerald-500/30", border: "border-emerald-500/40", text: "text-emerald-400" };
        if (s.includes("JPY")) return { class: "theme-jpy", glow: "shadow-red-500/30", border: "border-red-500/40", text: "text-red-400" }; // Red Crimson
        return { class: "theme-btc", glow: "shadow-purple-500/30", border: "border-purple-500/40", text: "text-purple-400" };
    };

    const assetTheme = getBotTheme(purchase.botProduct.instrument);
    
    // Detectar tipo de cuenta real sincronizada
    const activeAcc = purchase.activePositions?.[0];
    const isCent = activeAcc?.isCent || purchase.botProduct.name.toUpperCase().includes("CENT") || baseName.toUpperCase().includes("CENT");
    const currency = isCent ? "USC" : "$";

    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
    
    // Etiqueta superior dinámica: DEMO | REAL USD | REAL CENT
    let accountTypeLabel = "CUENTA DEMO";
    let accountTypeColor = "bg-orange-500/20 text-orange-400 border-orange-500/40";
    
    if (hasRealSync) {
        accountTypeLabel = isCent ? "CUENTA REAL (CENT)" : "CUENTA REAL (USD)";
        accountTypeColor = "bg-success/20 text-success border-success/40";
    }
    
    const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
    
    const normalizeVer = (v: string) => parseFloat(v.replace(/[^0-9.]/g, '')) || 0;
    // const hasUpdate = normalizeVer(purchase.botProduct.version) > normalizeVer(purchase.lastDownloadedVersion || "0.0");

    return (
        <div className={`animate-in fade-in slide-in-from-bottom-6 duration-700 mb-8 ${assetTheme.class}`}>
            <Card className={`relative overflow-hidden glass-card ${assetTheme.border} bg-surface/60 backdrop-blur-3xl shadow-2xl rounded-[2.5rem] border premium-card-glow`}>
                <div className={`absolute inset-0 bg-gradient-to-b from-[var(--theme-color)]/10 to-[var(--theme-color)]/5 pointer-events-none opacity-40`} />
                
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
                                {purchase.botProduct.name.replace(/\(V5\.54\)|\(V1\.2\)/gi, "(UNIVERSAL)")}
                            </CardTitle>
                            
                            {/* SWITCHER DE VARIANTES */}
                            {variants.length > 1 && (
                                <div className="flex flex-wrap gap-1.5 mt-3 mb-1">
                                    {variants.map((v, idx) => {
                                        const isSel = selectedIndex === idx;
                                        const vName = (v.botProduct.name || "").toUpperCase();
                                        
                                        // Detectar cuenta para el label de la pestaña
                                        const accountNum = v.activePositions?.[0]?.account;
                                        const isUltra = vName.includes("ULTRA");
                                        const isCentV = vName.includes("CENT") || vName.includes("CÉNTIMOS");
                                        const isUniv = vName.includes("UNIVERSAL");
                                        
                                        let vShortName = "";
                                        if (isUltra && isCentV) vShortName = "ULTRA CENT";
                                        else if (isUltra) vShortName = "ULTRA USD";
                                        else if (isCentV) vShortName = "CENT";
                                        else if (isUniv) vShortName = "UNIVERSAL";
                                        
                                        let label = accountNum ? `Cuenta ${accountNum}${vShortName ? ` (${vShortName})` : ''}` : (vShortName || `LIC ${idx+1}`);
                                        
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

                        <div className="flex flex-col items-end gap-2">
                            <div className="p-3 px-5 rounded-xl bg-black/40 border border-white/5 flex flex-col items-center justify-center min-w-28 text-center premium-glass shadow-purple-500/10">
                                <span className="text-[8px] font-black uppercase tracking-[0.2em] opacity-40 mb-0.5">Total Hoy</span>
                                <span className={`text-xl font-black font-mono ${dailyProfit >= 0 ? 'text-success' : 'text-danger'}`}>
                                    {dailyProfit >= 0 ? '+' : ''}{dailyProfit.toFixed(2)} {currency}
                                </span>
                            </div>
                            
                            <div className={`flex items-center gap-2 p-1.5 px-3 rounded-lg bg-white/5 border ${assetTheme.border} animate-pulse-glow-heavy`}>
                                <span className={`text-[8px] font-black uppercase tracking-widest ${assetTheme.text}`}>ID:</span>
                                <code className="text-[10px] font-black font-mono text-white select-all">
                                    {purchase.id.slice(0, 8)}...
                                </code>
                                <Button 
                                    size="sm" 
                                    className={`h-5 w-5 p-0 flex items-center justify-center shrink-0 rounded ${copiedId === purchase.id ? 'bg-success text-white' : 'bg-white/10 text-white hover:bg-white/20'}`}
                                    onClick={() => onCopy(purchase.id)}
                                >
                                    {copiedId === purchase.id ? <CheckCircle2 size={10} /> : <Copy size={10} />}
                                </Button>
                            </div>
                        </div>
                    </div>
                </CardHeader>

                <CardContent className="relative z-10 p-4 sm:p-5 space-y-6">
                    <div className="grid lg:grid-cols-2 gap-6">
                        <div className={`space-y-4 ${isMaintenance ? 'blur-md grayscale pointer-events-none opacity-40' : ''}`}>
                            <div className="flex items-center gap-2">
                                <div className="flex-1">
                                    <BotRemoteControl 
                                        purchaseId={purchase.id} 
                                        botName={purchase.botProduct.name} 
                                        account={purchase.activePositions?.[0]?.account || "unknown"}
                                        isOnline={purchase.lastSync && (new Date().getTime() - new Date(purchase.lastSync).getTime()) < 150000}
                                        theme={theme}
                                    />
                                </div>
                                <button 
                                    onClick={() => setShowSettings(!showSettings)}
                                    className={`p-3 rounded-xl border-2 transition-all group ${
                                        showSettings 
                                        ? `bg-white/10 ${assetTheme.border} text-white ${assetTheme.glow}` 
                                        : 'bg-white/5 border-white/5 text-white/40 hover:bg-white/10'
                                    }`}
                                    title="Configuración Remota"
                                >
                                    <Settings2 size={24} className={showSettings ? 'animate-spin-slow' : 'group-hover:rotate-45 transition-transform'} />
                                </button>
                            </div>
                            
                            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 p-3 rounded-xl bg-white/5 border border-white/5">
                                <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                                <CleanupButton purchaseId={purchase.id} />
                            </div>

                            {showSettings && (
                                <BotSettings 
                                    purchaseId={purchase.id} 
                                    account={purchase.activePositions?.[0]?.account || "unknown"} 
                                    theme={theme}
                                    onClose={() => setShowSettings(false)}
                                />
                            )}
                        </div>

                        <div className="space-y-4">
                            <div className="p-4 rounded-xl bg-gradient-to-br from-white/5 to-transparent border border-white/5 relative">
                                <h4 className="text-[9px] font-black uppercase tracking-widest text-white/40 mb-3 text-center sm:text-left">Instalación</h4>
                                <div className="flex flex-col gap-2">
                                    {isMaintenance ? (
                                        <div className={`bg-white/5 border ${assetTheme.border} p-3 rounded-lg text-center backdrop-blur-xl animate-pulse`}>
                                            <p className={`text-[10px] font-black ${assetTheme.text} uppercase tracking-widest mb-1`}>En Mantenimiento</p>
                                            <p className="text-[8px] text-gray-400">Calibrando algoritmos TITAN...</p>
                                        </div>
                                    ) : (
                                        <a href={`/api/download/${purchase.id}?type=ex5`} className="group">
                                            <Button fullWidth className="bg-white text-black hover:bg-white/90 font-black tracking-tight flex items-center justify-between px-5 py-3 h-auto rounded-xl">
                                                <div className="text-left leading-tight">
                                                     <div className="text-[11px] uppercase font-black">Descargar última versión</div>
                                                     <div className="text-[8px] opacity-40 font-bold tracking-tighter uppercase italic">Archivo .EX5 para MetaTrader 5</div>
                                                </div>
                                                <span className="text-xl group-hover:translate-x-1 transition-transform font-none">📥</span>
                                            </Button>
                                        </a>
                                    )}
                                </div>
                            </div>

                            <div className="p-4 rounded-xl bg-black/60 border border-brand/20 shadow-2xl premium-glass">
                                <div className="flex items-center justify-between mb-3">
                                    <p className="text-[9px] text-brand-light uppercase tracking-widest font-black flex items-center gap-2">
                                        <ShieldCheck size={12} /> LICENCIA MT5 COMPLETA
                                    </p>
                                    <span className="text-[8px] text-white/40 font-bold uppercase">Copiar para MT5</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <code className="text-[12px] font-black font-mono text-white select-all break-all tracking-tight uppercase p-3 bg-white/5 rounded-lg border border-white/10 flex-1 shadow-inner">
                                        {purchase.id}
                                    </code>
                                    <Button 
                                        size="lg" 
                                        className={`transition-all h-12 w-12 p-0 flex items-center justify-center shrink-0 rounded-xl border-2 ${copiedId === purchase.id ? 'bg-success border-success text-white' : `bg-white/5 ${assetTheme.border} text-white hover:bg-white/20`}`}
                                        onClick={() => onCopy(purchase.id)}
                                    >
                                        {copiedId === purchase.id ? <CheckCircle2 size={20} /> : <Copy size={20} />}
                                    </Button>
                                </div>
                                <p className="text-[8px] text-white/30 mt-3 italic text-center uppercase tracking-tighter">
                                    Introduce este ID en el parámetro "PurchaseID" del bot en MT5 para sincronizar.
                                </p>
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
                                    <div key={account} className="p-4 rounded-2xl bg-black/40 border border-white/5 shadow-2xl overflow-hidden relative group/acc">
                                        <div className="absolute top-0 right-0 p-3">
                                            <div className="flex flex-col items-end">
                                                <span className="text-[8px] font-black text-brand-light/40 uppercase tracking-widest">Estado</span>
                                                <span className="text-[10px] font-black text-success flex items-center gap-1.5">
                                                    <div className="w-1.5 h-1.5 bg-success rounded-full animate-pulse" />
                                                    SYNC OK
                                                </span>
                                            </div>
                                        </div>

                                        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-5 border-b border-white/5 pb-3">
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-xl bg-brand-light/10 border border-brand-light/20 flex items-center justify-center">
                                                    <ShieldCheck className="text-brand-light" size={20} />
                                                </div>
                                                <div>
                                                    <h4 className="text-xs font-black text-white uppercase tracking-tight flex items-center gap-2">
                                                        Cuenta: <span className="bg-brand-light/20 px-2 py-0.5 rounded text-[10px] font-mono">{account}</span>
                                                    </h4>
                                                    <p className="text-[9px] text-text-muted/60 font-black uppercase tracking-widest mt-1">
                                                        {posList.length} Operaciones Activas
                                                    </p>
                                                </div>
                                            </div>

                                            <div className="flex gap-4">
                                                <div className="text-right">
                                                    <p className="text-[8px] font-black text-white/20 uppercase tracking-widest">Flotante</p>
                                                    <p className={`text-xs font-black font-mono ${posList.reduce((a:any,p:any)=>a+p.profit,0) >= 0 ? 'text-success' : 'text-danger'}`}>
                                                        {posList.reduce((a:any,p:any)=>a+p.profit,0) >= 0 ? '+' : ''}{posList.reduce((a:any,p:any)=>a+p.profit,0).toFixed(2)} {currency}
                                                    </p>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-[8px] font-black text-white/20 uppercase tracking-widest">Balance Hoy</p>
                                                    <p className={`text-xs font-black font-mono ${(purchase.pastTrades || []).filter((h:any)=>h.account===account).reduce((a:any,p:any)=>a+p.profit,0) >= 0 ? 'text-success' : 'text-danger'}`}>
                                                        {(purchase.pastTrades || []).filter((h:any)=>h.account===account).reduce((a:any,p:any)=>a+p.profit,0) >= 0 ? '+' : ''}{(purchase.pastTrades || []).filter((h:any)=>h.account===account).reduce((a:any,p:any)=>a+p.profit,0).toFixed(2)} {currency}
                                                    </p>
                                                </div>
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
                                                        {(pos.profit || 0) >= 0 ? '+' : ''}{(pos.profit || 0).toFixed(2)} {currency}
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
                                                    {(h.profit || 0) >= 0 ? '+' : ''}{(h.profit || 0).toFixed(2)} {currency}
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
