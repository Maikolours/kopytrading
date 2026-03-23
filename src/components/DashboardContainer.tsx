"use client";

import { useState } from "react";
import { Card, CardHeader, CardContent, CardTitle, CardFooter } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { Countdown } from "./ui/Countdown";
import { PasswordChangeForm } from "./PasswordChangeForm";
import { Copy, CheckCircle2 } from "lucide-react";

interface DashboardContainerProps {
    purchases: any[];
}

export function DashboardContainer({ purchases }: DashboardContainerProps) {
    // Helper para colores de bot (Interiorizado para evitar errores de Client Component)
    const getBotTheme = (name: string = "") => {
        const n = name.toUpperCase();
        if (n.includes("ORO") || n.includes("XAUUSD") || n.includes("AMETRA") || n.includes("EVOLUTION"))
            return {
                border: 'border-amber-500/50',
                accent: 'text-amber-400',
                glow: 'bg-amber-500/20',
                gradient: 'from-amber-600/40 via-amber-900/20 to-black',
                badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30'
            };
        if (n.includes("BTC") || n.includes("BITCOIN"))
            return {
                border: 'border-purple-500/50',
                accent: 'text-purple-400',
                glow: 'bg-purple-500/20',
                gradient: 'from-purple-600/40 via-purple-900/20 to-black',
                badge: 'bg-purple-500/20 text-purple-300 border-purple-500/30'
            };
        if (n.includes("YEN") || n.includes("JPY"))
            return {
                border: 'border-cyan-500/50',
                accent: 'text-cyan-400',
                glow: 'bg-cyan-500/20',
                gradient: 'from-cyan-600/40 via-cyan-900/20 to-black',
                badge: 'bg-cyan-500/20 text-cyan-300 border-cyan-500/30'
            };
        return {
            border: 'border-brand/50',
            accent: 'text-brand-light',
            glow: 'bg-brand/20',
            gradient: 'from-brand/30 via-brand-dark/20 to-black',
            badge: 'bg-brand/20 text-brand-light border-brand/30'
        };
    };

    // Agrupar compras por "Categoría" (Oro, BTC, etc)
    const categoryGroups: Record<string, any[]> = {};
    
    purchases.forEach(p => {
        const name = p.botProduct.name.toUpperCase();
        let key = "Otros";
        if (name.includes("ORO") || name.includes("XAU") || name.includes("AMETRA") || name.includes("EVOLUTION")) key = "GOLD (Oro)";
        else if (name.includes("BTC") || name.includes("BITCOIN")) key = "BTC (Bitcoin)";
        else if (name.includes("EUR") || name.includes("EURO")) key = "EUR (Euro)";
        else if (name.includes("YEN") || name.includes("JPY")) key = "JPY (Yen)";
        
        if (!categoryGroups[key]) categoryGroups[key] = [];
        categoryGroups[key].push(p);
    });

    const categories = [...Object.keys(categoryGroups), "⚙️ AJUSTES"];
    const [activeCategory, setActiveCategory] = useState(categories[0] || "");
    const [copiedId, setCopiedId] = useState<string | null>(null);
    const [selectedBotIndices, setSelectedBotIndices] = useState<Record<string, number>>({});

    const handleCopy = (id: string) => {
        navigator.clipboard.writeText(id);
        setCopiedId(id);
        setTimeout(() => setCopiedId(null), 2000);
    };

    // Agrupar los bots de la categoría activa por "Nombre Base" para el Switcher
    const currentCategoryPurchases = categoryGroups[activeCategory] || [];
    const botsByBaseName: Record<string, any[]> = {};
    
    currentCategoryPurchases.forEach(p => {
        const baseName = p.botProduct.name.split('(')[0].trim().toUpperCase();
        if (!botsByBaseName[baseName]) botsByBaseName[baseName] = [];
        botsByBaseName[baseName].push(p);
    });

    return (
        <div className="flex flex-col gap-6">
            {/* Top Navigation Tabs - Better for Centering */}
            <div className="w-full">
                <div className="flex flex-wrap justify-center gap-2 pb-4 border-b border-white/5">
                    {categories.map(cat => (
                        <button
                            key={cat}
                            onClick={() => setActiveCategory(cat)}
                            className={`px-4 py-2.5 rounded-xl text-left transition-all whitespace-nowrap md:whitespace-normal font-black uppercase tracking-tighter text-[10px] border ${
                                activeCategory === cat 
                                ? 'bg-brand/20 border-brand-light text-white shadow-[0_0_15px_rgba(168,85,247,0.2)]' 
                                : 'bg-white/5 border-white/10 text-white/40 hover:bg-white/10'
                            }`}
                        >
                            {cat}
                        </button>
                    ))}
                </div>
            </div>

            {/* Contenido Principal: Centrado y Optimizado */}
            <div className="flex-1 min-w-0 max-w-4xl mx-auto w-full">
                {Object.entries(botsByBaseName).map(([baseName, variants]: [string, any[]]) => {
                    const selectedIndex = selectedBotIndices[baseName] || 0;
                    const purchase = variants[selectedIndex] || variants[0];
                    const theme = getBotTheme(purchase.botProduct.name);
                    const isTrial = purchase.status === "TRIAL";
                    const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
                    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
                    const accountTypeLabel = hasRealSync ? "CUENTA REAL" : "CUENTA DEMO";
                    const accountTypeColor = hasRealSync ? "bg-success/20 text-success border-success/40" : "bg-orange-500/20 text-orange-400 border-orange-500/40";
                    
                    const normalizeVer = (v: string) => parseFloat(v.replace(/[^0-9.]/g, '')) || 0;
                    const hasUpdate = normalizeVer(purchase.botProduct.version) > normalizeVer(purchase.lastDownloadedVersion || "0.0");

                    return (
                        <div key={baseName} className="animate-in fade-in slide-in-from-bottom-4 duration-500 mb-6">
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
                                            
                                            {/* SWITCHER DE VARIANTES (Si hay más de una) */}
                                            {variants.length > 1 && (
                                                <div className="flex gap-1.5 mt-3 mb-1">
                                                    {variants.map((v, idx) => {
                                                        const isSel = selectedIndex === idx;
                                                        const vName = v.botProduct.name.toUpperCase();
                                                        let label = vName.includes("CENT") ? "CENT" : (vName.includes("ULTRA") ? "ULTRA" : `LIC ${idx+1}`);
                                                        return (
                                                            <button
                                                                key={v.id}
                                                                onClick={() => setSelectedBotIndices(prev => ({ ...prev, [baseName]: idx }))}
                                                                className={`px-3 py-1 rounded-md text-[9px] font-black uppercase transition-all border ${
                                                                    isSel 
                                                                    ? 'bg-white/20 border-white/40 text-white' 
                                                                    : 'bg-white/5 border-white/5 text-white/30 hover:bg-white/10'
                                                                }`}
                                                            >
                                                                {label}
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
                                                        onClick={() => handleCopy(purchase.id)}
                                                    >
                                                        {copiedId === purchase.id ? <CheckCircle2 size={12} /> : <Copy size={12} />}
                                                    </Button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* OPERACIONES ABIERTAS */}
                                    {(purchase.activePositions?.length || 0) > 0 && (
                                        <div className="p-4 rounded-2xl bg-black/40 border border-white/5">
                                            <h4 className={`text-[10px] font-black uppercase tracking-widest ${theme.accent} mb-4`}>Operaciones en Vivo</h4>
                                            <div className="space-y-3">
                                                {purchase.activePositions.map((pos: any) => (
                                                    <div key={pos.id} className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-all group">
                                                        <div className="flex items-center gap-3">
                                                            <div className={`w-8 h-8 rounded-lg flex items-center justify-center text-[10px] font-black ${pos.type === 'BUY' ? 'bg-success/20 text-success' : 'bg-danger/20 text-danger'}`}>
                                                                {pos.type === 'BUY' ? 'BUY' : 'SELL'}
                                                            </div>
                                                            <div>
                                                                <div className="flex items-center gap-2">
                                                                    <span className="text-white font-black text-sm leading-none">{(pos.lots || 0).toFixed(2)} {pos.symbol}</span>
                                                                    <span className="text-[9px] opacity-20 font-mono italic">#{pos.ticket}</span>
                                                                </div>
                                                                <div className="text-[10px] text-text-muted/60 mt-0.5 uppercase font-medium tracking-widest">
                                                                    Lote: <span className="text-white/80">{pos.account}</span> • @{(pos.openPrice || 0).toFixed(2)}
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
                                    )}

                                    {/* HISTORIAL */}
                                    {(purchase.pastTrades?.length || 0) > 0 && (
                                         <div className="p-4 rounded-2xl bg-black/20 border border-white/5">
                                            <h4 className="text-[9px] font-black uppercase tracking-[0.3em] text-text-muted/40 mb-3">Cierres de Hoy</h4>
                                            <div className="space-y-1.5 font-mono">
                                                {purchase.pastTrades.map((h: any) => (
                                                    <div key={h.id} className="flex items-center justify-between py-2 px-3 rounded-lg bg-white/[0.02] hover:bg-white/[0.05] transition-all">
                                                        <div className="flex items-center gap-3">
                                                            <span className={`font-black w-6 text-xs ${h.type === 'BUY' ? 'text-success' : 'text-danger'}`}>{h.type === 'B' ? 'B' : 'S'}</span>
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
                                    )}
                                </CardContent>
                            </Card>
                        </div>
                    );
                })}

                {activeCategory === "⚙️ AJUSTES" && (
                    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
                        <Card className="glass-card bg-black/90 border-brand/20 shadow-2xl rounded-3xl p-8 border-2">
                            <CardHeader className="px-0 pt-0 pb-6 border-b border-white/5">
                                <CardTitle className="text-3xl font-black text-white tracking-tighter">
                                    ⚙️ AJUSTES DE CUENTA
                                </CardTitle>
                                <p className="text-gray-400 mt-2">
                                    Gestiona tu contraseña y preferencias de acceso.
                                </p>
                            </CardHeader>
                            <CardContent className="px-0 pt-8 space-y-8">
                                <div className="grid md:grid-cols-2 gap-8">
                                    <div className="space-y-4">
                                        <h4 className="text-sm font-black uppercase tracking-widest text-brand-light">Seguridad</h4>
                                        <p className="text-sm text-gray-400 leading-relaxed">
                                            Tu contraseña temporal inicial es <span className="text-white font-mono bg-white/10 px-2 py-0.5 rounded">123456</span>. 
                                            Te recomendamos cambiarla si aún no lo has hecho.
                                        </p>
                                        <div className="p-4 rounded-2xl bg-white/5 border border-white/10 italic text-[11px] text-gray-500">
                                            Nota: Cambiar esta contraseña <b>no afecta</b> al funcionamiento de los bots en MT5.
                                        </div>
                                    </div>
                                    <div className="space-y-6">
                                        <PasswordChangeForm />
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                )}
            </div>
        </div>
    );
}
