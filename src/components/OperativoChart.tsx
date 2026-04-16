"use client";

import React, { useEffect, useRef, useState } from 'react';

interface OperativoChartProps {
    symbol?: string;
    purchaseId: string;
    account: string;
    theme?: any;
    activePositions?: any[];
}

export const OperativoChart: React.FC<OperativoChartProps> = ({ 
    symbol = "BTCUSDT", 
    theme,
}) => {
    const [loading, setLoading] = useState(true);
    
    // Normalización de símbolo para TradingView
    // Si viene BTCUSD -> BINANCE:BTCUSDT
    // Si viene XAUUSD -> OANDA:XAUUSD
    let tvSymbol = symbol.toUpperCase().replace(/USDT/g, "USD");
    if (!tvSymbol.includes(":")) {
        if (tvSymbol.includes("BTC") || tvSymbol.includes("ETH")) {
            tvSymbol = `BINANCE:${tvSymbol}T`; // BTCUSDT
        } else if (tvSymbol.includes("XAU") || tvSymbol.includes("GOLD")) {
            tvSymbol = "OANDA:XAUUSD";
        } else {
            tvSymbol = `FOREXCOM:${tvSymbol}`;
        }
    }

    useEffect(() => {
        const timer = setTimeout(() => setLoading(false), 2000);
        return () => clearTimeout(timer);
    }, [symbol]);

    return (
        <div className="relative w-full rounded-3xl overflow-hidden border border-white/5 bg-black shadow-2xl min-h-[350px]">
            {loading && (
                <div className="absolute inset-0 z-20 flex items-center justify-center bg-black">
                    <div className="flex flex-col items-center gap-3">
                        <div className="w-8 h-8 border-4 border-brand border-t-transparent rounded-full animate-spin" />
                        <span className="text-[10px] font-black text-white/40 uppercase tracking-widest">ENLAZANDO CON TRADINGVIEW...</span>
                    </div>
                </div>
            )}
            
            <iframe 
                id="tradingview_sniper"
                src={`https://s.tradingview.com/widgetembed/?frameElementId=tradingview_sniper&symbol=${tvSymbol}&interval=1&hidesidetoolbar=1&hidetoptoolbar=1&symboledit=0&saveimage=0&toolbarbg=transparent&studies=%5B%5D&theme=dark&style=1&timezone=Etc%2FUTC&studies_overrides=%7B%7D&overrides=%7B%22paneProperties.background%22%3A%22%23000000%22%2C%22paneProperties.vertGridProperties.color%22%3A%22rgba(42%2C%2046%2C%2057%2C%200)%22%2C%22paneProperties.horzGridProperties.color%22%3A%22rgba(42%2C%2046%2C%2057%2C%200)%22%7D&enabled_features=%5B%5D&disabled_features=%5B%5D&locale=es&utm_source=kopytrading.vercel.app&utm_medium=widget&utm_campaign=chart&utm_term=${tvSymbol}`}
                width="100%"
                height="350px"
                style={{ border: 'none' }}
                onLoad={() => setLoading(false)}
            />

            <div className="absolute top-4 left-4 z-10 flex flex-col gap-1 pointer-events-none">
                <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-brand animate-pulse shadow-[0_0_10px_#24cecb]" />
                    <span className="text-[10px] font-black text-white/90 uppercase tracking-widest">PRO LIVE FEED: {tvSymbol.split(':')[1] || tvSymbol}</span>
                </div>
            </div>
            
            {/* Overlay sutil para matching estético con el resto del dashboard */}
            <div className="absolute inset-0 pointer-events-none border border-white/5 rounded-3xl" />
        </div>
    );
};
