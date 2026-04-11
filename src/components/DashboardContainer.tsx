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
                label: 'ELITE GOLD AMETRALLADORA'
            };
        if (n.includes("BTC") || n.includes("BITCOIN"))
            return {
                border: 'border-purple-500/50',
                accent: 'text-purple-400',
                glow: 'bg-purple-500/20',
                gradient: 'from-brand/20 to-transparent',
                badge: 'bg-purple-500/20 text-purple-300 border-purple-500/30',
                label: 'ELITE SNIPER v13'
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

    // Memoizar la agrupación por categoría
    const categoryGroups = useMemo(() => {
        const groups: Record<string, any[]> = {};
        purchases.forEach(p => {
            const name = (p.botProduct?.name || "").toUpperCase();
            const instrument = (p.botProduct?.instrument || "").toUpperCase();
            let key = "Otros";
            
            if (instrument.includes("BTC") || instrument.includes("BITCOIN") || name.includes("BITCOIN") || name.includes("SNIPER")) key = "ELITE SNIPER v13";
            else if (instrument.includes("XAU") || instrument.includes("GOLD") || instrument.includes("ORO") || name.includes("AMETRA")) key = "ELITE GOLD AMETRALLADORA";
            else if (instrument.includes("EUR") || name.includes("EURO")) key = "Euro Precision 🎯";
            else if (instrument.includes("JPY") || name.includes("YEN")) key = "Ninja Ghost 🥷";
            else if (name.includes("EVOLUTION")) key = "ELITE GOLD AMETRALLADORA"; 
            
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

    // Memoizar la agrupación por Nombre Base + Real/Demo dentro de la categoría activa
    const botsByBaseName = useMemo(() => {
        const groups: Record<string, any[]> = {};
        const currentCategoryPurchases = categoryGroups[activeCategory] || [];
        currentCategoryPurchases.forEach(p => {
            let baseName = (p.botProduct?.name || "").toUpperCase();
            // Detectar si alguna posición activa o el bot en sí es Real para separar la tarjeta
            const hasRealSync = (p.activePositions || []).some((pos: any) => pos.isReal);
            const realityKey = hasRealSync ? "REAL" : "DEMO";
            
            // Limpieza agresiva de variantes para agrupar
            baseName = baseName.replace(/ULTRA|CÉNTIMOS|CENT|BTCUSD|XAUUSD|XAU|JPY|YEN|EUR|USD|GHOST|NINJA|\(|\)/gi, "").trim();
            const groupKey = `${baseName}_${realityKey}`;
            
            if (!groups[groupKey]) groups[groupKey] = [];
            groups[groupKey].push(p);
        });
        return groups;
    }, [categoryGroups, activeCategory]);

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
                {Object.entries(botsByBaseName).map(([baseName, variants]: [string, any[]]) => (
                    <BotCard
                        key={baseName}
                        baseName={baseName}
                        variants={variants}
                        selectedIndex={selectedBotIndices[baseName] || 0}
                        onSelectVariant={(idx) => setSelectedBotIndices(prev => ({ ...prev, [baseName]: idx }))}
                        theme={getBotTheme(variants[0].botProduct.name)}
                        onCopy={handleCopy}
                        copiedId={copiedId}
                        isOwner={isOwner}
                    />
                ))}

                {activeCategory === "📈 RENDIMIENTO" && (
                    <PerformanceSection purchases={purchases} />
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
