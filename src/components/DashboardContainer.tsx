"use client";

import { useState, useMemo } from "react";
import { Card, CardHeader, CardContent, CardTitle, CardFooter } from "./ui/Card";
import { Button } from "./ui/Button";
import { BotRemoteControl } from "./BotRemoteControl";
import { SyncStatus } from "./SyncStatus";
import { CleanupButton } from "./CleanupButton";
import { Countdown } from "./ui/Countdown";
import { PasswordChangeForm } from "./PasswordChangeForm";
import { BotCard } from "./BotCard";
import { PerformanceSection } from "./PerformanceSection";
import { useSession } from "next-auth/react";
import { ErrorBoundary } from "./ErrorBoundary";

interface DashboardContainerProps {
    purchases: any[];
}

export function DashboardContainer({ purchases }: DashboardContainerProps) {
    const { data: session } = useSession();
    const isOwner = session?.user?.email === "viajaconsakura@gmail.com" || session?.user?.email === "viajaconsakura";
    // Helper para colores de bot (Interiorizado para evitar errores de Client Component)
    const getBotTheme = (name: string = "") => {
        const n = name.toUpperCase();
        if (n.includes("ORO") || n.includes("XAUUSD") || n.includes("AMETRA") || n.includes("EVOLUTION") || n.includes("GOLD"))
            return {
                border: 'border-amber-500/50',
                accent: 'text-amber-400',
                glow: 'bg-amber-500/20',
                gradient: 'from-amber-500/20 to-transparent',
                badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
                label: 'MAIKO SNIPER PRO ✨'
            };
        if (n.includes("BTC") || n.includes("BITCOIN") || n.includes("WEEKEND"))
            return {
                border: 'border-purple-500/50',
                accent: 'text-purple-400',
                glow: 'bg-purple-500/20',
                gradient: 'from-brand/20 to-transparent',
                badge: 'bg-purple-500/20 text-purple-300 border-purple-500/30',
                label: 'MAIKO BTC WEEKEND'
            };
        if (n.includes("YEN") || n.includes("JPY") || n.includes("CENT") || n.includes("PRO CENT"))
            return {
                border: 'border-cyan-500/50',
                accent: 'text-cyan-400',
                glow: 'bg-cyan-500/20',
                gradient: 'from-cyan-600/40 via-cyan-900/20 to-black',
                badge: 'bg-cyan-500/20 text-cyan-300 border-cyan-500/30',
                label: 'MAIKO SNIPER PRO CENT'
            };
        return {
            border: 'border-brand/50',
            accent: 'text-brand-light',
            glow: 'bg-brand/20',
            gradient: 'from-brand/30 via-brand-dark/20 to-black',
            badge: 'bg-brand/20 text-brand-light border-brand/30',
            label: 'MAIKO SNIPER PRO'
        };
    };

    // Memoizar la agrupación por categoría
    const categoryGroups = useMemo(() => {
        const groups: Record<string, any[]> = {};
        purchases.forEach(p => {
            const name = (p.botProduct?.name || "").toUpperCase();
            const instrument = (p.botProduct?.instrument || "").toUpperCase();
            let key = "MAIKO SNIPER PRO 🎯";
            
            if (instrument.includes("BTC") || name.includes("BTC")) {
                key = "MAIKO SNIPER PRO BTC ₿";
            } else if (name.includes("CENT")) {
                key = "MAIKO SNIPER PRO GOLD CENT ⚡";
            } else if (instrument.includes("XAU") || name.includes("GOLD") || name.includes("ORO")) {
                key = "MAIKO SNIPER PRO GOLD 🏆";
            }
            
            if (!groups[key]) groups[key] = [];
            groups[key].push(p);
        });
        return groups;
    }, [purchases]);

    const categories = useMemo(() => [...Object.keys(categoryGroups), "📈 RENDIMIENTO", "⚙️ AJUSTES"], [categoryGroups]);
    const [activeCategory, setActiveCategory] = useState(categories[0] || "");
    const [copiedId, setCopiedId] = useState<string | null>(null);
    const [selectedBotIndices, setSelectedBotIndices] = useState<Record<string, number>>({});

    const handleCopy = (id: string) => {
        navigator.clipboard.writeText(id);
        setCopiedId(id);
        setTimeout(() => setCopiedId(null), 2000);
    };

    // Estado para controlar qué bot específico está seleccionado para visualización completa
    const [selectedPurchaseId, setSelectedPurchaseId] = useState<string | null>(null);

    const handleCategoryChange = (cat: string) => {
        setActiveCategory(cat);
        setSelectedPurchaseId(null);
    };

    // Memoizar la agrupación de bots individuales por ID de compra en lugar de agruparlos de forma agresiva
    const botsByBaseName = useMemo(() => {
        const groups: Record<string, any[]> = {};
        const currentCategoryPurchases = categoryGroups[activeCategory] || [];
        currentCategoryPurchases.forEach(p => {
            // Usamos el ID de la compra como clave para garantizar que cada una sea su propia tarjeta independiente
            const groupKey = p.id;
            groups[groupKey] = [p];
        });
        return groups;
    }, [categoryGroups, activeCategory]);

    const activeCategoryPurchases = categoryGroups[activeCategory] || [];

    return (
        <div className="flex flex-col gap-6">
            {/* Top Navigation Tabs - Better for Centering */}
            <div className="w-full">
                <div className="flex flex-wrap justify-center gap-2 pb-4 border-b border-white/5">
                    {categories.map(cat => (
                        <button
                            key={cat}
                            onClick={() => handleCategoryChange(cat)}
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
                {activeCategory !== "📈 RENDIMIENTO" && activeCategory !== "⚙️ AJUSTES" && (
                    <ErrorBoundary fallbackTitle="Error en Selector de Bots">
                        {selectedPurchaseId === null ? (
                            /* ================= CATÁLOGO DE MINI-TARJETAS (VISTA PRINCIPAL) ================= */
                            <div className="space-y-6">
                                <div className="text-center md:text-left">
                                    <h3 className="text-xl sm:text-2xl font-black text-white tracking-tighter uppercase italic">
                                        🖥️ Panel de Control de Algoritmos
                                    </h3>
                                    <p className="text-xs text-gray-400 mt-1 italic">
                                        Selecciona un bot para abrir su dashboard exclusivo de operaciones en vivo y telemetría.
                                    </p>
                                </div>

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-2">
                                    {activeCategoryPurchases.map((p: any) => {
                                        const botProduct = p.botProduct || { name: "Bot Desconocido", instrument: "UNKNOWN" };
                                        const botTheme = getBotTheme(botProduct.name);
                                        const isOnline = p.lastSync && (Math.abs(Date.now() - new Date(p.lastSync).getTime()) < 300000);
                                        
                                        const isCent = botProduct.name.toUpperCase().includes("CENT");
                                        const currency = isCent ? "USC" : "$";
                                        
                                        const activeAcc = p.activePositions?.[0];
                                        const hasRealSync = (p.activePositions || []).some((pos: any) => pos.isReal);
                                        const accountTypeLabel = hasRealSync ? (isCent ? "REAL (CENT)" : "REAL (USD)") : "DEMO";
                                        const accountTypeColor = hasRealSync ? "bg-success/20 text-success border-success/40" : "bg-orange-500/20 text-orange-400 border-orange-500/40";

                                        // Cálculo de Expiración / Demo 30 días
                                        const now = new Date();
                                        const expiresAt = p.expiresAt ? new Date(p.expiresAt) : null;
                                        let daysRemaining = null;
                                        if (expiresAt) {
                                            const diffTime = expiresAt.getTime() - now.getTime();
                                            daysRemaining = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
                                        }

                                        // Cálculo de versión y actualizaciones
                                        const botSettings = p.botSettings?.[0]?.settings;
                                        const parsedSettings = botSettings ? (typeof botSettings === 'string' ? JSON.parse(botSettings) : botSettings) : null;
                                        const runningVersion = parsedSettings?.version;
                                        const latestVersion = botProduct.version || "1.0";
                                        const hasUpdate = runningVersion 
                                            ? (runningVersion !== latestVersion) 
                                            : (p.lastDownloadedVersion ? (p.lastDownloadedVersion !== latestVersion) : false);

                                        const displayBalance = parsedSettings?.balance !== undefined && parsedSettings?.balance !== null 
                                            ? Number(parsedSettings.balance) 
                                            : (p.balance && Number(p.balance) > 0 ? Number(p.balance) : null);

                                        return (
                                            <div 
                                                key={p.id}
                                                className={`group relative overflow-hidden rounded-[2rem] border ${hasUpdate ? 'border-amber-500/50 shadow-[0_0_25px_rgba(245,158,11,0.1)]' : botTheme.border} bg-surface/40 backdrop-blur-2xl p-6 transition-all duration-500 hover:scale-[1.02] hover:border-brand-light/50 hover:shadow-[0_15px_35px_rgba(168,85,247,0.15)] flex flex-col justify-between h-[260px]`}
                                            >
                                                {/* Glow de fondo decorativo */}
                                                <div className={`absolute top-0 right-0 w-32 h-32 ${hasUpdate ? 'bg-amber-500/20' : botTheme.glow} blur-[50px] -mr-10 -mt-10 rounded-full transition-all duration-700 opacity-30 group-hover:opacity-60`} />
                                                
                                                {/* Header de la Mini-Tarjeta */}
                                                <div className="space-y-3 relative z-10">
                                                    <div className="flex items-center justify-between">
                                                        <span className={`px-2 py-0.5 rounded-lg text-[8px] font-black border ${accountTypeColor} tracking-widest uppercase`}>
                                                            {accountTypeLabel}
                                                        </span>
                                                        <div className="flex items-center gap-1.5">
                                                            {hasUpdate && (
                                                                <span className="px-2 py-0.5 rounded-lg text-[8px] font-black bg-amber-500/20 text-amber-300 border border-amber-500/40 animate-pulse uppercase tracking-widest">
                                                                    ACTUALIZAR v{latestVersion} ⚠️
                                                                </span>
                                                            )}
                                                            <div className="flex items-center gap-1.5 bg-black/40 px-2 py-0.5 rounded-lg border border-white/5">
                                                                <div className={`w-1.5 h-1.5 rounded-full ${isOnline ? 'bg-success animate-pulse' : 'bg-white/20'}`} />
                                                                <span className={`text-[7px] font-black tracking-widest uppercase ${isOnline ? 'text-success' : 'text-white/30'}`}>
                                                                    {isOnline ? 'ONLINE' : 'OFFLINE'}
                                                                </span>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    
                                                    <div>
                                                        <h4 className="text-base font-black tracking-tighter text-white uppercase group-hover:text-brand-light transition-colors leading-tight">
                                                            {botProduct.name}
                                                        </h4>
                                                        <p className="text-[9px] font-bold text-white/40 tracking-wider mt-1 uppercase">
                                                            Activo: {botProduct.instrument} • ID: {p.id.substring(0, 8)}...
                                                        </p>
                                                    </div>
                                                </div>

                                                {/* Balance & Info de Prueba */}
                                                <div className="py-2 flex items-center justify-between border-t border-white/5 mt-auto relative z-10">
                                                    <div>
                                                        <p className="text-[7px] font-black uppercase tracking-widest text-white/25">Balance MT5</p>
                                                        <p className="text-lg font-black text-white font-mono leading-none mt-1">
                                                            {displayBalance !== null ? `${displayBalance.toFixed(2)} ${currency}` : <span className="text-xs text-white/40 font-normal">Sin Sincronizar</span>}
                                                        </p>
                                                    </div>

                                                    {/* Contador de Días Demo */}
                                                    <div className="text-right">
                                                        {botProduct.name.toUpperCase().includes("DEMO") ? (
                                                            isOwner ? (
                                                                <span className="text-[8px] font-black text-brand-light uppercase tracking-widest bg-brand/10 border border-brand/20 px-2 py-1 rounded">
                                                                    ♾️ ACCESO DEMO ILIMITADO
                                                                </span>
                                                            ) : expiresAt ? (
                                                                <span className={`text-[8px] font-black uppercase tracking-widest px-2 py-1 rounded border ${daysRemaining && daysRemaining > 5 ? 'text-orange-400 bg-orange-500/10 border-orange-500/20' : 'text-danger bg-danger/10 border-danger/20'}`}>
                                                                    ⏳ {daysRemaining} DÍAS RESTANTES
                                                                </span>
                                                            ) : (
                                                                <span className="text-[8px] font-black text-orange-400 uppercase tracking-widest bg-orange-500/10 border border-orange-500/20 px-2 py-1 rounded">
                                                                    ⏳ 30 DÍAS DEMO
                                                                </span>
                                                            )
                                                        ) : (
                                                            <span className="text-[8px] font-black text-white/20 uppercase tracking-widest">
                                                                LICENCIA COMPLETA
                                                            </span>
                                                        )}
                                                    </div>
                                                </div>

                                                {/* Botón de Entrada */}
                                                <button
                                                    onClick={() => setSelectedPurchaseId(p.id)}
                                                    className="w-full mt-4 py-2.5 rounded-xl text-[9px] font-black uppercase tracking-widest text-center text-black bg-white hover:bg-brand-light hover:text-white hover:shadow-[0_0_15px_rgba(168,85,247,0.4)] transition-all relative z-10 shrink-0"
                                                >
                                                    Entrar al Dashboard ⚡
                                                </button>
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>
                        ) : (
                            /* ================= DASHBOARD EXCLUSIVO DE UN SOLO BOT (NIVEL 2) ================= */
                            <div className="animate-in fade-in duration-500">
                                <button 
                                    onClick={() => setSelectedPurchaseId(null)}
                                    className="mb-6 flex items-center gap-2 px-5 py-2.5 rounded-xl text-[9px] font-black uppercase tracking-widest bg-white/5 border border-white/10 hover:bg-white/10 hover:border-brand-light/50 text-white transition-all shadow-lg"
                                >
                                    ← Volver al panel de bots
                                </button>

                                {Object.entries(botsByBaseName)
                                    .filter(([id]) => id === selectedPurchaseId)
                                    .map(([id, variants]: [string, any[]]) => (
                                        <BotCard
                                            key={id}
                                            baseName={variants[0]?.botProduct?.name || "BOT"}
                                            variants={variants}
                                            selectedIndex={0}
                                            onSelectVariant={() => {}}
                                            theme={getBotTheme(variants[0]?.botProduct?.name)}
                                            onCopy={handleCopy}
                                            copiedId={copiedId}
                                            isOwner={isOwner}
                                        />
                                    ))}
                            </div>
                        )}
                    </ErrorBoundary>
                )}

                {activeCategory === "📈 RENDIMIENTO" && (
                    <ErrorBoundary fallbackTitle="Error en Gráfico de Rendimiento">
                        <PerformanceSection purchases={purchases} />
                    </ErrorBoundary>
                )}

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
