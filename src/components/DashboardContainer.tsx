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
    const groupedBots: Record<string, any[]> = {};
    
    purchases.forEach(p => {
        const name = p.botProduct.name.toUpperCase();
        let key = "Otros";
        if (name.includes("ORO") || name.includes("XAU") || name.includes("AMETRA") || name.includes("EVOLUTION")) key = "GOLD (Oro)";
        else if (name.includes("BTC") || name.includes("BITCOIN")) key = "BTC (Bitcoin)";
        else if (name.includes("EUR") || name.includes("EURO")) key = "EUR (Euro)";
        else if (name.includes("YEN") || name.includes("JPY")) key = "JPY (Yen)";
        
        if (!groupedBots[key]) groupedBots[key] = [];
        groupedBots[key].push(p);
    });

    const categories = [...Object.keys(groupedBots), "⚙️ AJUSTES"];
    const [activeCategory, setActiveCategory] = useState(categories[0] || "");
    const [copiedId, setCopiedId] = useState<string | null>(null);

    const handleCopy = (id: string) => {
        navigator.clipboard.writeText(id);
        setCopiedId(id);
        setTimeout(() => setCopiedId(null), 2000);
    };

    const selectedPurchases = groupedBots[activeCategory] || [];

    return (
        <div className="flex flex-col gap-8">
            {/* Top Navigation Tabs - Better for Centering */}
            <div className="w-full">
                <div className="flex flex-wrap justify-center gap-2 pb-6 border-b border-white/5">
                    {categories.map(cat => (
                        <button
                            key={cat}
                            onClick={() => setActiveCategory(cat)}
                            className={`px-4 py-3 rounded-xl text-left transition-all whitespace-nowrap md:whitespace-normal font-black uppercase tracking-tighter text-xs border ${
                                activeCategory === cat 
                                ? 'bg-brand/20 border-brand-light text-white shadow-[0_0_20px_rgba(168,85,247,0.2)]' 
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
                {selectedPurchases.map((purchase: any) => {
                    const theme = getBotTheme(purchase.botProduct.name);
                    const isTrial = purchase.status === "TRIAL";
                    const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
                    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
                    const accountTypeLabel = hasRealSync ? "CUENTA REAL" : "CUENTA DEMO";
                    const accountTypeColor = hasRealSync ? "bg-success/20 text-success border-success/40" : "bg-orange-500/20 text-orange-400 border-orange-500/40";
                    
                    const normalizeVer = (v: string) => parseFloat(v.replace(/[^0-9.]/g, '')) || 0;
                    const hasUpdate = normalizeVer(purchase.botProduct.version) > normalizeVer(purchase.lastDownloadedVersion || "0.0");

                    return (
                        <div key={purchase.id} className="animate-in fade-in slide-in-from-bottom-4 duration-500 mb-8">
                            <Card className={`relative overflow-hidden glass-card ${theme.border} bg-black/90 shadow-2xl rounded-3xl border-2`}>
                                <div className={`absolute inset-0 bg-gradient-to-b ${theme.gradient} pointer-events-none opacity-40`} />
                                
                                <CardHeader className="relative z-10 border-b border-white/5 pb-6">
                                    <div className="flex flex-col sm:flex-row justify-between items-start gap-4">
                                        <div>
                                            <div className="flex items-center gap-3 mb-2">
                                                <span className={`px-3 py-1 rounded-full text-[10px] font-black border ${accountTypeColor} tracking-widest`}>
                                                    {accountTypeLabel}
                                                </span>
                                                {isTrial ? (
                                                     <span className="px-3 py-1 rounded-full text-[10px] font-black bg-white/10 text-white border border-white/20 tracking-widest">
                                                        VERSIÓN DE PRUEBA
                                                     </span>
                                                ) : (
                                                    <span className="px-3 py-1 rounded-full text-[10px] font-black bg-success/20 text-success border border-success/30 tracking-widest">
                                                        LICENCIA LIFETIME
                                                     </span>
                                                )}
                                            </div>
                                            <div className="flex flex-wrap gap-2 mb-4">
                                                {(() => {
                                                    const hasRealSync = (purchase.activePositions || []).some((pos: any) => pos.isReal);
                                                    const accountTypeLabel = hasRealSync ? "CUENTA REAL ✨" : "CUENTA DEMO 🧪";
                                                    const accountTypeColor = hasRealSync ? "border-success/40 text-success bg-success/10" : "border-orange-500/40 text-orange-400 bg-orange-500/10";
                                                    
                                                    const botNameUpper = (purchase.botProduct.name || "").toUpperCase();
                                                    const isUniversal = botNameUpper.includes("UNIVERSAL");
                                                    const isCent = botNameUpper.includes("CENT");
                                                    const currencyLabel = isUniversal ? "MODO UNIVERSAL (AUTO) 💎" : (isCent ? "MODO CENT" : "MODO USD $");
                                                    const currencyColor = isUniversal ? "border-amber-500/40 text-amber-300 bg-amber-500/10" : (isCent ? "border-cyan-500/30 text-cyan-400 bg-cyan-500/5" : "border-brand/30 text-brand-light bg-brand/5");

                                                    return (
                                                        <>
                                                            <span className={`px-4 py-1.5 rounded-full text-[10px] font-black border-2 ${accountTypeColor} tracking-widest`}>
                                                                {accountTypeLabel}
                                                            </span>
                                                            <span className={`px-4 py-1.5 rounded-full text-[10px] font-black border-2 ${currencyColor} tracking-widest shadow-lg`}>
                                                                {currencyLabel}
                                                            </span>
                                                        </>
                                                    );
                                                })()}
                                                <span className="px-4 py-1.5 rounded-full text-[10px] font-bold bg-white/5 border border-white/10 text-gray-400 tracking-widest uppercase">
                                                    {purchase.botProduct.instrument}
                                                </span>
                                            </div>
                                            <CardTitle className="text-3xl sm:text-4xl font-black text-white tracking-tighter leading-tight mb-2 uppercase">
                                                {purchase.botProduct.name}
                                            </CardTitle>
                                            <p className="text-text-muted text-xs opacity-60">
                                                {purchase.botProduct.description || "Optimizado para trading automático de alta precisión."}
                                            </p>
                                        </div>

                                        <div className="w-full sm:w-auto p-4 px-6 rounded-2xl bg-black/60 border border-white/10 flex flex-col items-center justify-center min-w-32">
                                            <span className="text-[9px] font-black uppercase tracking-[0.2em] opacity-40 mb-1">Hoy</span>
                                            <span className={`text-2xl font-black font-mono ${dailyProfit >= 0 ? 'text-success' : 'text-danger'} drop-shadow-[0_0_15px_rgba(34,197,94,0.3)]`}>
                                                {dailyProfit >= 0 ? '+' : ''}{dailyProfit.toFixed(2)} $
                                            </span>
                                        </div>
                                    </div>
                                </CardHeader>

                                <CardContent className="relative z-10 p-6 space-y-8">
                                    {/* CONTROLES Y ESTADO */}
                                    <div className="grid lg:grid-cols-2 gap-8">
                                        <div className="space-y-6">
                                            <BotRemoteControl 
                                                purchaseId={purchase.id} 
                                                botName={purchase.botProduct.name} 
                                                isOnline={purchase.lastSync && (new Date().getTime() - new Date(purchase.lastSync).getTime()) < 150000}
                                                theme={theme}
                                            />
                                            
                                            <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-white/5 border border-white/5">
                                                <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                                                <CleanupButton purchaseId={purchase.id} />
                                            </div>
                                        </div>

                                        <div className="space-y-6">
                                             {/* SECCIÓN DE DESCARGAS */}
                                            <div className={`p-6 rounded-2xl bg-gradient-to-br from-white/10 to-transparent border border-white/10 shadow-xl`}>
                                                <h4 className="text-xs font-black uppercase tracking-widest text-white mb-4">Área de Descargas</h4>
                                                <div className="flex flex-col gap-3">
                                                    <a href={`/api/download/${purchase.id}?type=ex5`} className="group">
                                                        <Button fullWidth size="lg" className="bg-white text-black hover:bg-white/90 font-black tracking-tight flex items-center justify-between px-6 py-6 h-auto">
                                                            <div className="text-left">
                                                                 <div className="text-xs uppercase font-black">Descargar Bot (.EX5)</div>
                                                                <div className="text-[10px] opacity-60 font-bold uppercase tracking-tighter">Versión actual: {purchase.botProduct.version}</div>
                                                            </div>
                                                            <span className="text-xl group-hover:translate-x-1 transition-transform">📥</span>
                                                        </Button>
                                                    </a>
                                                    {hasUpdate && (
                                                        <div className="text-[10px] text-brand-light text-center font-black animate-pulse uppercase tracking-widest mt-1">
                                                            🚀 ¡Hay una actualización disponible!
                                                        </div>
                                                    )}
                                                </div>
                                            </div>

                                            {/* ID DE VÍNCULO (Copiable) */}
                                            <div className="p-5 rounded-2xl bg-black/40 border-l-4 border-brand-light shadow-2xl">
                                                <p className="text-[9px] text-text-muted/60 uppercase tracking-widest mb-2 font-black">ID Vínculo (LICENSE KEY)</p>
                                                <div className="flex items-center gap-2">
                                                    <code className="text-sm sm:text-base font-black font-mono text-brand-light select-all break-all tracking-tighter uppercase p-2 bg-white/5 rounded-lg flex-1">
                                                        {purchase.id}
                                                    </code>
                                                    <Button 
                                                        size="sm" 
                                                        className={`transition-all h-9 w-9 p-0 flex items-center justify-center shrink-0 ${copiedId === purchase.id ? 'bg-success text-white' : 'bg-white/10 text-white hover:bg-white/20'}`}
                                                        onClick={() => handleCopy(purchase.id)}
                                                    >
                                                        {copiedId === purchase.id ? <CheckCircle2 size={16} /> : <Copy size={16} />}
                                                    </Button>
                                                </div>
                                                <p className="mt-2 text-[9px] text-text-muted/40 italic">
                                                    Copia este ID y pégalo en el parámetro "ID Vínculo" de tu bot en MT5.
                                                </p>
                                            </div>
                                        </div>
                                    </div>

                                    {/* OPERACIONES ABIERTAS */}
                                    {(purchase.activePositions?.length || 0) > 0 && (
                                        <div className="p-6 rounded-3xl bg-black/40 border border-white/10">
                                            <h4 className={`text-sm font-black uppercase tracking-widest ${theme.accent} mb-6`}>Operaciones en Vivo</h4>
                                            <div className="space-y-4">
                                                {purchase.activePositions.map((pos: any) => (
                                                    <div key={pos.id} className="flex items-center justify-between p-4 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 transition-all group">
                                                        <div className="flex items-center gap-4">
                                                            <div className={`w-10 h-10 rounded-full flex items-center justify-center font-black ${pos.type === 'BUY' ? 'bg-success/20 text-success' : 'bg-danger/20 text-danger'}`}>
                                                                {pos.type === 'BUY' ? 'BUY' : 'SELL'}
                                                            </div>
                                                            <div>
                                                                <div className="flex items-center gap-2">
                                                                    <span className="text-white font-black text-xl leading-none">{(pos.lots || 0).toFixed(2)} {pos.symbol}</span>
                                                                    <span className="text-[10px] opacity-30 font-mono">#{pos.ticket}</span>
                                                                </div>
                                                                <div className="text-xs text-text-muted/60 mt-1 uppercase font-black tracking-widest">
                                                                    Cuenta: <span className="text-white/80">{pos.account}</span> • @ {(pos.openPrice || 0).toFixed(2)}
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className={`text-2xl font-black font-mono ${(pos.profit || 0) >= 0 ? 'text-success' : 'text-danger'} drop-shadow-lg`}>
                                                            {(pos.profit || 0) >= 0 ? '+' : ''}{(pos.profit || 0).toFixed(2)} $
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    )}

                                    {/* HISTORIAL (Solo se muestra si no hay crossover o si queremos verlo) */}
                                    {(purchase.pastTrades?.length || 0) > 0 && (
                                         <div className="p-6 rounded-3xl bg-black/40 border border-white/10">
                                            <h4 className="text-[10px] font-black uppercase tracking-[0.3em] text-text-muted/40 mb-4">Cierres de Hoy</h4>
                                            <div className="space-y-2">
                                                {purchase.pastTrades.map((h: any) => (
                                                    <div key={h.id} className="flex items-center justify-between py-3 px-4 rounded-xl bg-white/[0.02] hover:bg-white/[0.05] transition-all">
                                                        <div className="flex items-center gap-4">
                                                            <span className={`font-black w-8 text-sm ${h.type === 'BUY' ? 'text-success' : 'text-danger'}`}>{h.type === 'B' ? 'B' : 'S'}</span>
                                                            <div>
                                                                <div className="flex items-center gap-2 text-white font-black">
                                                                    <span className="text-sm">{(h.lots || 0).toFixed(2)}</span>
                                                                    <span className="text-xs opacity-60 font-mono">{h.symbol}</span>
                                                                </div>
                                                                <div className="text-[9px] opacity-40 font-mono">Ticket #{h.ticket}</div>
                                                            </div>
                                                        </div>
                                                        <div className={`font-black text-lg font-mono ${(h.profit || 0) >= 0 ? 'text-success' : 'text-danger'}`}>
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
