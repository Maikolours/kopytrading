"use client";

import { useEffect, useState } from "react";

interface OfferCountdownProps {
    compact?: boolean;
}

export function OfferCountdown({ compact = false }: OfferCountdownProps) {
    const [timeLeft, setTimeLeft] = useState({
        days: 14,
        hours: 23,
        minutes: 59,
        seconds: 59
    });
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
        // Epoch base: October 19, 2026 00:00:00 UTC
        const EPOCH = new Date("2026-10-19T00:00:00Z").getTime();
        const PERIOD_MS = 15 * 24 * 60 * 60 * 1000; // 15 días en milisegundos

        const updateTimer = () => {
            const now = Date.now();
            const elapsed = (now - EPOCH) % PERIOD_MS;
            const safeElapsed = elapsed < 0 ? elapsed + PERIOD_MS : elapsed;
            const remaining = PERIOD_MS - safeElapsed;

            const days = Math.floor(remaining / (24 * 60 * 60 * 1000));
            const hours = Math.floor((remaining % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000));
            const minutes = Math.floor((remaining % (60 * 60 * 1000)) / (60 * 1000));
            const seconds = Math.floor((remaining % (60 * 1000)) / 1000);

            setTimeLeft({ days, hours, minutes, seconds });
        };

        updateTimer();
        const interval = setInterval(updateTimer, 1000);
        return () => clearInterval(interval);
    }, []);

    if (!mounted) {
        if (compact) {
            return (
                <div className="inline-flex items-center gap-1.5 text-[8px] text-amber-300 font-bold bg-amber-500/10 px-2 py-0.5 rounded-md border border-amber-500/20">
                    <span>⏳</span> Oferta expira en: 14d 23h 59m
                </div>
            );
        }
        return (
            <div className="p-3 bg-amber-500/10 rounded-xl border border-amber-500/20 text-center animate-pulse">
                <span className="text-xs text-amber-300 font-bold">Cargando oferta...</span>
            </div>
        );
    }

    if (compact) {
        return (
            <div className="inline-flex items-center gap-1 text-[8px] text-amber-300 font-bold bg-amber-500/10 px-2 py-0.5 rounded-md border border-amber-500/20 tracking-wider">
                <span className="animate-pulse">⏳</span>
                <span>OFERTA EXPIRA:</span>
                <span className="font-mono text-white">{timeLeft.days}d</span>
                <span className="font-mono text-white">{String(timeLeft.hours).padStart(2, '0')}h</span>
                <span className="font-mono text-white">{String(timeLeft.minutes).padStart(2, '0')}m</span>
                <span className="font-mono text-amber-400">{String(timeLeft.seconds).padStart(2, '0')}s</span>
            </div>
        );
    }

    return (
        <div className="p-3 sm:p-4 bg-gradient-to-r from-amber-500/10 via-brand/10 to-amber-500/10 rounded-2xl border border-amber-500/30 text-center space-y-2 shadow-lg w-full max-w-full overflow-hidden">
            <div className="flex items-center justify-center gap-1 text-[8px] sm:text-[9px] font-black uppercase tracking-[0.15em] text-amber-300 leading-tight">
                <span className="animate-bounce">🔥</span>
                <span>Oferta de Lanzamiento · Primeros 15 Días</span>
                <span className="animate-bounce">🔥</span>
            </div>

            <div className="flex items-center justify-center gap-1 sm:gap-2 w-full max-w-full">
                <div className="flex-1 bg-black/60 border border-white/10 rounded-xl py-1.5 px-1 text-center min-w-0">
                    <div className="text-base sm:text-xl font-black font-mono text-white leading-none">
                        {timeLeft.days}
                    </div>
                    <div className="text-[7px] uppercase font-bold text-text-muted mt-1">Días</div>
                </div>

                <span className="text-amber-400 font-black text-sm sm:text-base flex-shrink-0">:</span>

                <div className="flex-1 bg-black/60 border border-white/10 rounded-xl py-1.5 px-1 text-center min-w-0">
                    <div className="text-base sm:text-xl font-black font-mono text-white leading-none">
                        {String(timeLeft.hours).padStart(2, '0')}
                    </div>
                    <div className="text-[7px] uppercase font-bold text-text-muted mt-1">Horas</div>
                </div>

                <span className="text-amber-400 font-black text-sm sm:text-base flex-shrink-0">:</span>

                <div className="flex-1 bg-black/60 border border-white/10 rounded-xl py-1.5 px-1 text-center min-w-0">
                    <div className="text-base sm:text-xl font-black font-mono text-white leading-none">
                        {String(timeLeft.minutes).padStart(2, '0')}
                    </div>
                    <div className="text-[7px] uppercase font-bold text-text-muted mt-1">Min</div>
                </div>

                <span className="text-amber-400 font-black text-sm sm:text-base flex-shrink-0">:</span>

                <div className="flex-1 bg-black/60 border border-amber-500/30 rounded-xl py-1.5 px-1 text-center min-w-0 shadow-sm shadow-amber-500/20">
                    <div className="text-base sm:text-xl font-black font-mono text-amber-400 leading-none">
                        {String(timeLeft.seconds).padStart(2, '0')}
                    </div>
                    <div className="text-[7px] uppercase font-bold text-amber-300/80 mt-1">Seg</div>
                </div>
            </div>

            <p className="text-[9px] text-text-muted font-medium">
                Tarifa promocional activa garantizada. Posteriormente volverá a su precio oficial de <span className="line-through text-white/50">250€</span>.
            </p>
        </div>
    );
}
