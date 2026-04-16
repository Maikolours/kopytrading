"use client";

import React, { useEffect, useRef, useState } from 'react';
import { createChart, IChartApi, ISeriesApi, IPriceLine } from 'lightweight-charts';

interface OperativoChartProps {
    symbol?: string;
    purchaseId: string;
    account: string;
    theme?: any;
    activePositions?: any[];
}

export const OperativoChart: React.FC<OperativoChartProps> = ({ 
    symbol = "BTCUSDT", 
    purchaseId, 
    account,
    theme,
    activePositions = []
}) => {
    const chartContainerRef = useRef<HTMLDivElement>(null);
    const chartRef = useRef<IChartApi | null>(null);
    const seriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
    const priceLinesRef = useRef<IPriceLine[]>([]);
    const [loading, setLoading] = useState(true);

    const positionLinesRef = useRef<IPriceLine[]>([]);

    const updatePositionLines = (positions: any[]) => {
        if (!seriesRef.current) return;
        positionLinesRef.current.forEach(line => { try { seriesRef.current?.removePriceLine(line); } catch (e) {} });
        positionLinesRef.current = [];
        if (!positions || positions.length === 0) return;

        positions.forEach(pos => {
            const price = Number(pos.openPrice);
            if (!price || price <= 0) return;
            const isSell = pos.type?.toUpperCase().includes("SELL");
            const color = isSell ? "#ef4444" : "#10b981";
            try {
                const line = seriesRef.current?.createPriceLine({
                    price: price, color: color, lineWidth: 2, lineStyle: 0, axisLabelVisible: true, title: ` ${pos.lots} @ ${price.toFixed(2)}`,
                });
                if (line) positionLinesRef.current.push(line);
                if (pos.tp && Number(pos.tp) > 0) {
                    const tpLine = seriesRef.current?.createPriceLine({ price: Number(pos.tp), color: "#10b981", lineWidth: 1, lineStyle: 2, axisLabelVisible: true, title: "TP" });
                    if (tpLine) positionLinesRef.current.push(tpLine);
                }
                if (pos.sl && Number(pos.sl) > 0) {
                    const slLine = seriesRef.current?.createPriceLine({ price: Number(pos.sl), color: "#ef4444", lineWidth: 1, lineStyle: 1, axisLabelVisible: true, title: "SL" });
                    if (slLine) positionLinesRef.current.push(slLine);
                }
            } catch (e) {}
        });
    };

    const updateFiboLevels = (data: any) => {
        if (!seriesRef.current) return;
        priceLinesRef.current.forEach(line => { try { seriesRef.current?.removePriceLine(line); } catch (e) {} });
        priceLinesRef.current = [];
        if (!data) return;
        const levelsData = data.settings || data; 
        if (!levelsData || !levelsData.p50) return;

        const levels = [
            { price: Number(levelsData.p100), color: 'rgba(255,255,255,0.4)', label: 'ORIGEN [100]' },
            { price: Number(levelsData.p78), color: '#ef4444', label: 'STOP [78.6]' },
            { price: Number(levelsData.p62), color: '#f59e0b', label: 'ENTRY [61.8]' },
            { price: Number(levelsData.p50), color: '#3b82f6', label: 'GATILLO [50]' },
            { price: Number(levelsData.p00), color: '#10b981', label: 'TARGET [0.0]' },
        ];

        levels.forEach(lvl => {
            if (lvl.price > 0) {
                try {
                    const line = seriesRef.current?.createPriceLine({
                        price: lvl.price, color: lvl.color, lineWidth: 2, lineStyle: 2, axisLabelVisible: true, title: lvl.label,
                    });
                    if (line) priceLinesRef.current.push(line);
                } catch (e) {}
            }
        });
    };

    const fetchTelemetry = async () => {
        try {
            const res = await fetch(`/api/purchase/${purchaseId}/settings?account=${account}`);
            if (res.ok) {
                const data = await res.json();
                updateFiboLevels(data);
            }
        } catch (error) {}
    };

    useEffect(() => {
        updatePositionLines(activePositions);
    }, [activePositions]);

    useEffect(() => {
        let chart: IChartApi | null = null;
        let retryCount = 0;

        const init = async () => {
            if (!chartContainerRef.current) return;
            if (chartContainerRef.current.clientWidth === 0 && retryCount < 15) {
                retryCount++;
                setTimeout(init, 250);
                return;
            }

            try {
                chart = createChart(chartContainerRef.current, {
                    width: chartContainerRef.current.clientWidth || 300,
                    height: 350,
                    layout: { background: { color: 'transparent' }, textColor: '#d1d5db' },
                    grid: { vertLines: { color: 'rgba(255, 255, 255, 0.05)' }, horzLines: { color: 'rgba(255, 255, 255, 0.05)' } },
                    rightPriceScale: { borderColor: 'rgba(255, 255, 255, 0.1)' },
                    timeScale: { visible: false },
                });

                const candlestickSeries = chart.addCandlestickSeries({ upColor: '#10b981', downColor: '#ef4444', borderVisible: false });
                chartRef.current = chart;
                seriesRef.current = candlestickSeries;

                const apiSymbol = symbol.includes("XAU") ? "PAXGUSDT" : symbol.replace(/USD|USDT|\//g, "") + "USDT";
                const res = await fetch(`https://api.binance.com/api/v3/klines?symbol=${apiSymbol}&interval=1m&limit=80`);
                if (res.ok) {
                    const data = await res.json();
                    candlestickSeries.setData(data.map((d: any) => ({
                        time: d[0] / 1000, open: parseFloat(d[1]), high: parseFloat(d[2]), low: parseFloat(d[3]), close: parseFloat(d[4]),
                    })));
                }
                setLoading(false);
                fetchTelemetry();
            } catch (err) { setLoading(false); }
        };

        init();
        const interval = setInterval(fetchTelemetry, 10000);
        const handleResize = () => { if (chartContainerRef.current && chart) chart.applyOptions({ width: chartContainerRef.current.clientWidth }); };
        window.addEventListener('resize', handleResize);

        return () => {
            window.removeEventListener('resize', handleResize);
            clearInterval(interval);
            if (chart) { try { chart.remove(); } catch (e) {} }
        };
    }, [symbol, purchaseId, account]);

    return (
        <div className="relative w-full rounded-3xl overflow-hidden border border-white/5 bg-black/40 backdrop-blur-md shadow-2xl">
            {loading && (
                <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/60">
                    <div className="w-8 h-8 border-4 border-brand border-t-transparent rounded-full animate-spin" />
                </div>
            )}
            <div ref={chartContainerRef} className="w-full" style={{ height: '350px' }} />
            <div className="absolute top-4 left-4 z-10 flex flex-col gap-1 pointer-events-none">
                <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-brand animate-pulse shadow-[0_0_10px_#24cecb]" />
                    <span className="text-[10px] font-black text-white/90 uppercase tracking-widest">LIVE SNIPER CHART</span>
                </div>
            </div>
        </div>
    );
};
