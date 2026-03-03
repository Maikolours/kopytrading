"use client";

import { useState, useEffect } from "react";

interface CountdownProps {
    targetDate: string | Date;
}

export function Countdown({ targetDate }: CountdownProps) {
    const [mounted, setMounted] = useState(false);
    const [timeLeft, setTimeLeft] = useState<{
        days: number;
        hours: number;
        minutes: number;
        seconds: number;
    } | null>(null);

    useEffect(() => {
        setMounted(true);

        const calculateTimeLeft = () => {
            const now = new Date().getTime();
            const target = new Date(targetDate).getTime();

            if (isNaN(target)) return null;

            const difference = target - now;

            if (difference <= 0) {
                return null;
            }

            return {
                days: Math.floor(difference / (1000 * 60 * 60 * 24)),
                hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
                minutes: Math.floor((difference / 1000 / 60) % 60),
                seconds: Math.floor((difference / 1000) % 60),
            };
        };

        setTimeLeft(calculateTimeLeft());

        const timer = setInterval(() => {
            const calculated = calculateTimeLeft();
            setTimeLeft(calculated);
            if (!calculated) clearInterval(timer);
        }, 1000);

        return () => clearInterval(timer);
    }, [targetDate]);

    // Evitar hidratación incorrecta mostrando un placeholder sutil hasta que el cliente tome el control
    if (!mounted) {
        return <span className="text-text-muted/40 animate-pulse text-[10px]">Calculando...</span>;
    }

    if (!timeLeft) {
        return <span className="text-danger font-bold text-xs">¡PRUEBA EXPIRADA!</span>;
    }

    return (
        <span className="font-mono text-xs text-brand-bright font-bold bg-brand/10 px-2 py-0.5 rounded border border-brand/20">
            {timeLeft.days}d {timeLeft.hours}h {timeLeft.minutes}m {timeLeft.seconds}s
        </span>
    );
}
