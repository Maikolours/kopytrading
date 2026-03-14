"use client";

import { useState, useEffect } from "react";

const BOTS = ["La Ametralladora v5.0", "Euro Precision Flow", "Yen Ninja Ghost", "BTC Storm Rider v6.0"];
const OUTCOMES = [
    { text: "operación ganadora", emoji: "✅", color: "text-success", bg: "bg-success/10", border: "border-success/30" },
    { text: "Take Profit alcanzado", emoji: "🎯", color: "text-success", bg: "bg-success/10", border: "border-success/30" },
    { text: "Break Even activado", emoji: "🛡️", color: "text-brand-light", bg: "bg-brand/10", border: "border-brand/30" },
    { text: "Cierre por Trailing", emoji: "📉", color: "text-success", bg: "bg-success/10", border: "border-success/30" }
];

export function LiveSalesPopup() {
    const [visible, setVisible] = useState(false);
    const [data, setData] = useState({ name: "", bot: "", profit: "", action: OUTCOMES[0] });

    // Nombres aleatorios
    const generateRandomEvent = () => {
        const names = ["Carlos M.", "Alejandro T.", "David P.", "Sofia R.", "Marcos G.", "Ivan F.", "Sara L.", "Javier R.", "Elena V."];
        const name = names[Math.floor(Math.random() * names.length)];
        const bot = BOTS[Math.floor(Math.random() * BOTS.length)];
        let profit = (Math.random() * 50 + 10).toFixed(2);

        // Sesgar un poco hacia Take profit o operación ganadora
        let actionItem = OUTCOMES[Math.floor(Math.random() * OUTCOMES.length)];

        // Evitar que el Bitcoin "gane" si está aburrido como hoy
        if (bot === "BTC Storm Rider" && Math.random() > 0.3) {
            actionItem = OUTCOMES[2]; // Break even
            profit = "0.00";
        }

        setData({ name, bot, profit, action: actionItem });
        setVisible(true);

        // Ocultar a los 5 segundos
        setTimeout(() => {
            setVisible(false);
        }, 5000);
    };

    useEffect(() => {
        // Primer popup a los 10 segundos
        const initialTimer = setTimeout(() => {
            generateRandomEvent();
        }, 10000);

        // Luego cada 30 - 60 segundos
        const interval = setInterval(() => {
            if (Math.random() > 0.5) {
                generateRandomEvent();
            }
        }, 45000);

        return () => {
            clearTimeout(initialTimer);
            clearInterval(interval);
        };
    }, []);

    if (!visible) return null;

    return (
        <div className="fixed bottom-24 sm:bottom-6 left-4 z-[900] animate-slide-right pointer-events-none">
            <div className={`glass-card border ${data.action.border} ${data.action.bg} rounded-2xl p-4 shadow-2xl flex items-center gap-4 max-w-sm`}>
                <div className="text-3xl filter drop-shadow-md bg-white/10 rounded-full w-12 h-12 flex items-center justify-center">
                    {data.action.emoji}
                </div>
                <div>
                    <p className="text-white text-sm font-semibold flex items-center gap-1">
                        {data.name}
                        <span className="text-text-muted text-xs font-normal">ha conseguido</span>
                    </p>
                    <p className={`font-bold ${data.action.color} text-sm`}>
                        {data.action.text}
                        {data.profit !== "0.00" && ` ($${data.profit})`}
                    </p>
                    <p className="text-xs text-brand-light mt-0.5 font-medium flex items-center gap-1">
                        🤖 con {data.bot}
                    </p>
                </div>
            </div>
        </div>
    );
}
