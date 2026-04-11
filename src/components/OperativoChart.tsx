"use client";

import React, { useEffect, useRef, useState } from 'react';
import { createChart, IChartApi, ISeriesApi, IPriceLine } from 'lightweight-charts';

interface OperativoChartProps {
    symbol?: string;
    purchaseId: string;
    account: string;
    theme?: any;
}

export const OperativoChart: React.FC<OperativoChartProps> = ({ 
    symbol = "BTCUSDT", 
    purchaseId, 
    account,
    theme 
}) => {
    const chartContainerRef = useRef<HTMLDivElement>(null);
    const chartRef = useRef<IChartApi | null>(null);
    const seriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
    const priceLinesRef = useRef<IPriceLine[]>([]);
    const [loading, setLoading] = useState(true);

    const updateFiboLevels = (data: any) => {
        if (!seriesRef.current) return;

        // Limpiar líneas anteriores de forma segura
        priceLinesRef.current.forEach(line => {
            try {
                seriesRef.current?.removePriceLine(line);
            } catch (e) {
                console.warn("Error removing price line:", e);
            }
        });
        priceLinesRef.current = [];

        if (!data) return;
        const levelsData = data.settings || data; 
        if (!levelsData) return;

        const p50 = Number(levelsData.p50);
        
        if (p50 && p50 > 0) {
            const levels = [
                { price: Number(levelsData.p100), color: 'rgba(255,255,255,0.4)', label: 'ORIGEN [100]' },
                { price: Number(levelsData.p78), color: '#ef4444', label: 'STOP [78.6]' },
                { price: Number(levelsData.p62), color: '#f59e0b', label: 'ENTRY [61.8]' },
                { price: p50, color: '#3b82f6', label: 'GATILLO [50]' },
                { price: Number(levelsData.p00), color: '#10b981', label: 'TARGET [0.0]' },
            ];

            levels.forEach(lvl => {
                if (lvl.price > 0) {
                    const line = seriesRef.current?.createPriceLine({
                        price: lvl.price,
                        color: lvl.color,
                        lineWidth: 2,
                        lineStyle: 2, // Dashed
                        axisLabelVisible: true,
                        title: lvl.label,
                    });
                    if (line) priceLinesRef.current.push(line);
                }
            });
        }
    };

    const fetchTelemetry = async () => {
        try {
            const res = await fetch(`/api/purchase/${purchaseId}/settings?account=${account}`);
            if (res.ok) {
                const data = await res.json();
                updateFiboLevels(data);
            }
        } catch (error) {
            console.error("Error fetching telemetry for chart:", error);
        }
    };

    useEffect(() => {
        if (!chartContainerRef.current) return;

        // Inicialización segura del gráfico
        const chart = createChart(chartContainerRef.current, {
            width: chartContainerRef.current.clientWidth,
            height: 350,
            layout: {
                background: { color: 'transparent' },
                textColor: '#d1d5db',
            },
            grid: {
                vertLines: { color: 'rgba(255, 255, 255, 0.05)' },
                horzLines: { color: 'rgba(255, 255, 255, 0.05)' },
            },
            crosshair: {
                mode: 0,
            },
            rightPriceScale: {
                borderColor: 'rgba(255, 255, 255, 0.1)',
            },
            timeScale: {
                borderColor: 'rgba(255, 255, 255, 0.1)',
                visible: false, // Ocultamos tiempo para simplificar
            },
        });

        const candlestickSeries = chart.addCandlestickSeries({
            upColor: '#10b981',
            downColor: '#ef4444',
            borderVisible: false,
            wickUpColor: '#10b981',
            wickDownColor: '#ef4444',
        });

        chartRef.current = chart;
        seriesRef.current = candlestickSeries;

        // Fetch de velas (Crypto via Binance, Forex via fallback)
        const fetchKlines = async () => {
            try {
                // Si no es un símbolo de Binance (Forex por ejemplo), manejamos el estado
                const isCrypto = symbol.includes("BTC") || symbol.includes("ETH") || symbol.includes("XAU") || symbol.includes("USDT");
                
                if (!isCrypto) {
                    console.log("Forex/Other asset detected, chart fallback mode active.");
                    setLoading(false);
                    return;
                }

                const apiSymbol = symbol.includes("XAU") ? "PAXGUSDT" : symbol.replace(/USD|USDT|\//g, "") + "USDT";
                
                const res = await fetch(`https://api.binance.com/api/v3/klines?symbol=${apiSymbol}&interval=1m&limit=100`);
                if (!res.ok) throw new Error("API Response Error");
                
                const data = await res.json();
                if (!data || !Array.isArray(data)) {
                    setLoading(false);
                    return;
                }

                const formattedData = data.map((d: any) => ({
                    time: d[0] / 1000,
                    open: parseFloat(d[1]),
                    high: parseFloat(d[2]),
                    low: parseFloat(d[3]),
                    close: parseFloat(d[4]),
                }));
                candlestickSeries.setData(formattedData);
                setLoading(false);
            } catch (err) {
                console.error("Error fetching candles:", err);
                setLoading(false);
            }
        };

        fetchKlines();
        fetchTelemetry();

        const interval = setInterval(fetchTelemetry, 5000);

        const handleResize = () => {
            if (chartContainerRef.current) {
                chart.applyOptions({ width: chartContainerRef.current.clientWidth });
            }
        };
        window.addEventListener('resize', handleResize);

        // CLEANUP: Esta es la clave para la estabilidad
        return () => {
            window.removeEventListener('resize', handleResize);
            clearInterval(interval);
            if (chartRef.current) {
                chartRef.current.remove();
                chartRef.current = null;
            }
        };
    }, [symbol, purchaseId, account]);

    return (
        <div className="relative w-full rounded-2xl overflow-hidden border border-white/5 bg-black/20 backdrop-blur-sm shadow-inner group">
            {loading && (
                <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/60 backdrop-blur-md">
                    <div className="flex flex-col items-center gap-3">
                        <div className="w-8 h-8 border-4 border-brand border-t-transparent rounded-full animate-spin" />
                        <span className="text-[10px] font-black uppercase tracking-widest text-white/40">Sincronizando...</span>
                    </div>
                </div>
            )}
            <div ref={chartContainerRef} className="w-full" style={{ height: '350px' }} />
            
            <div className="absolute top-4 left-4 z-10 flex flex-col gap-1 pointer-events-none">
                <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-brand animate-pulse shadow-[0_0_8px_var(--brand)]" />
                    <span className="text-[10px] font-black text-white/90 uppercase tracking-tighter">Live Telemetry</span>
                </div>
                <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-black/40 border border-white/10">
                    <span className="text-[9px] font-black text-white/60 uppercase">{symbol}</span>
                </div>
            </div>
        </div>
    );
};
