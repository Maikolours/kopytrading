
"use client";

import { useState, useEffect } from "react";

interface CountdownProps {
    targetDate: string; // ISO string or date string
}

export function Countdown({ targetDate }: CountdownProps) {
    const [timeLeft, setTimeLeft] = useState({
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0
    });

    useEffect(() => {
        const calculateTimeLeft = () => {
            const difference = +new Date(targetDate) - +new Date();
            let timeLeft = {
                days: 0,
                hours: 0,
                minutes: 0,
                seconds: 0
            };

            if (difference > 0) {
                timeLeft = {
                    days: Math.floor(difference / (1000 * 60 * 60 * 24)),
                    hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
                    minutes: Math.floor((difference / 1000 / 60) % 60),
                    seconds: Math.floor((difference / 1000) % 60)
                };
            }

            return timeLeft;
        };

        const timer = setInterval(() => {
            setTimeLeft(calculateTimeLeft());
        }, 1000);

        // Initial call
        setTimeLeft(calculateTimeLeft());

        return () => clearInterval(timer);
    }, [targetDate]);

    return (
        <div className="flex gap-2 font-mono text-xl sm:text-2xl font-black text-white">
            <div className="flex flex-col items-center">
                <span className="bg-black/40 px-3 py-1 rounded-lg border border-white/10">{timeLeft.days}d</span>
            </div>
            <div className="flex flex-col items-center">
                <span className="bg-black/40 px-3 py-1 rounded-lg border border-white/10">{timeLeft.hours}h</span>
            </div>
            <div className="flex flex-col items-center">
                <span className="bg-black/40 px-3 py-1 rounded-lg border border-white/10">{timeLeft.minutes}m</span>
            </div>
            <div className="flex flex-col items-center">
                <span className="bg-black/40 px-3 py-1 rounded-lg border border-white/10 text-brand-light">{timeLeft.seconds}s</span>
            </div>
        </div>
    );
}
