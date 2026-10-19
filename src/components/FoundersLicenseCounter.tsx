"use client";

import { useEffect, useState } from "react";

interface FoundersLicenseCounterProps {
    compact?: boolean;
}

export function FoundersLicenseCounter({ compact = false }: FoundersLicenseCounterProps) {
    // Base launch date: October 19, 2026
    const [stats, setStats] = useState({
        remaining: 41,
        claimed: 9,
        rateToday: 2
    });
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);

        const BASE_DATE = new Date("2026-10-19T00:00:00Z").getTime();
        const now = Date.now();
        const diffMs = Math.max(0, now - BASE_DATE);
        const daysElapsed = Math.floor(diffMs / (24 * 60 * 60 * 1000));

        // Primeros días / primera semana: se descuentan 2 licencias al día.
        // A partir de la primera semana: se descuenta 1 licencia al día.
        const INITIAL_CLAIMED = 7;
        let calculatedClaimed = INITIAL_CLAIMED;

        if (daysElapsed <= 7) {
            calculatedClaimed += daysElapsed * 2;
        } else {
            calculatedClaimed += (7 * 2) + ((daysElapsed - 7) * 1);
        }

        const remaining = Math.max(3, 50 - calculatedClaimed);
        const claimed = 50 - remaining;
        const rateToday = daysElapsed <= 7 ? 2 : 1;

        setStats({ remaining, claimed, rateToday });
    }, []);

    const percentClaimed = Math.round((stats.claimed / 50) * 100);

    if (!mounted) {
        if (compact) {
            return (
                <span className="text-[8px] font-black text-amber-300 uppercase tracking-widest bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/20">
                    🔥 41 / 50 Vitalicias
                </span>
            );
        }
        return (
            <div className="mt-4 p-4 rounded-xl bg-gradient-to-br from-brand/10 to-purple-900/20 border border-brand/20 animate-pulse">
                <p className="text-[9px] text-brand-light font-black uppercase tracking-widest">Cargando cupos vitalicios...</p>
            </div>
        );
    }

    if (compact) {
        return (
            <span className="text-[8px] font-black text-amber-300 uppercase tracking-widest bg-amber-500/10 px-2.5 py-0.5 rounded-full border border-amber-500/30 flex items-center gap-1.5 shadow-sm">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse"></span>
                <span>{stats.remaining} de 50 Vitalicias</span>
            </span>
        );
    }

    return (
        <div className="mt-4 p-4 rounded-2xl bg-gradient-to-br from-brand/15 via-purple-950/40 to-amber-950/30 border border-brand/30 shadow-xl space-y-3 relative overflow-hidden">
            {/* Ambient glow */}
            <div className="absolute top-0 right-0 w-32 h-32 bg-amber-500/10 blur-2xl pointer-events-none rounded-full" />

            <div className="flex items-center justify-between gap-2 relative z-10">
                <p className="text-[9px] text-amber-300 uppercase tracking-widest font-black flex items-center gap-1.5">
                    <span className="text-sm">🔥</span> CUPOS VITALICIOS DISPONIBLES
                </p>
                <span className="text-[8px] font-mono font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/30">
                    Ahorro 150€
                </span>
            </div>

            <div className="space-y-1.5 relative z-10">
                <div className="flex items-baseline justify-between text-xs font-bold text-white">
                    <span>Licencias asignadas</span>
                    <span className="font-mono text-amber-300 text-sm font-black">
                        {stats.remaining} <span className="text-white/40 text-xs font-normal">/ 50 restantes</span>
                    </span>
                </div>

                {/* Barra de progreso */}
                <div className="w-full h-2.5 bg-black/60 rounded-full border border-white/10 overflow-hidden p-0.5">
                    <div 
                        className="h-full rounded-full bg-gradient-to-r from-brand-light via-purple-500 to-amber-400 transition-all duration-1000 shadow-[0_0_10px_rgba(245,158,11,0.5)]"
                        style={{ width: `${percentClaimed}%` }}
                    />
                </div>
            </div>

            <div className="pt-1 text-[10px] text-slate-300/85 leading-relaxed relative z-10 border-t border-white/5 space-y-1">
                <p>
                    *Las <strong>primeras 50 licencias</strong> de lanzamiento obtienen acceso <strong className="text-white">vitalicio de por vida por 100€</strong> (pago único sin cuotas).
                </p>
                <p className="text-emerald-400 font-semibold text-[9px] flex items-center gap-1.5">
                    <span>✓</span> Licencia permanente de por vida · Incluye actualizaciones futuras y soporte MT5.
                </p>
            </div>

            <div className="flex items-center justify-between text-[8px] text-amber-400/90 font-mono pt-1 relative z-10">
                <span className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-success animate-ping"></span>
                    Alta demanda: {stats.rateToday} licencias reservadas hoy
                </span>
                <span className="text-white/40">Garantía oficial MT5</span>
            </div>
        </div>
    );
}
