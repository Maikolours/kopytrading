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
    const [error, setError] = useState<string | null>(null);

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
        if (!levelsData || (!levelsData.p50 && levelsData.balance === undefined)) return;

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
            // Esperar a que el contenedor tenga tamaño real
            if (chartContainerRef.current.clientWidth === 0 && retryCount < 20) {
                retryCount++;
                setTimeout(init, 150);
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

                // NORMALIZACIÓN DE SÍMBOLO BINANCE
                let cleanSymbol = (symbol || "BTCUSDT").toUpperCase().replace(/USD|USDT|\//g, "");
                if (cleanSymbol.includes("XAU") || cleanSymbol.includes("GOLD")) cleanSymbol = "PAXG";
                const apiSymbol = cleanSymbol + "USDT";

                console.log(`[CHART] Fetching klines via PROXY for: ${apiSymbol}`);

                const res = await fetch(`/api/market-data?symbol=${apiSymbol}`);
                if (res.ok) {
                    const data = await res.json();
                    if (data.error) throw new Error(data.error);
                    
                    candlestickSeries.setData(data.map((d: any) => ({
                        time: d[0] / 1000, 
                        open: parseFloat(d[1]), 
                        high: parseFloat(d[2]), 
                        low: parseFloat(d[3]), 
                        close: parseFloat(d[4]),
                    })));
                    setError(null);
                } else {
                    const errData = await res.json().catch(() => ({}));
                    setError(errData.error || "Mercado no disponible");
                }
                setLoading(false);
                fetchTelemetry();
            } catch (err) { 
                console.error("[CHART-ERROR]", err);
                setError("Error de Sincronización");
                setLoading(false); 
            }
        };

        init();
        const interval = setInterval(fetchTelemetry, 7000);
        const handleResize = () => { if (chartContainerRef.current && chart) chart.applyOptions({ width: chartContainerRef.current.clientWidth }); };
        window.addEventListener('resize', handleResize);

        return () => {
            window.removeEventListener('resize', handleResize);
            clearInterval(interval);
            if (chart) { try { chart.remove(); } catch (e) {} }
        };
    }, [symbol, purchaseId, account]);

    return (
        <div className="relative w-full rounded-3xl overflow-hidden border border-white/5 bg-black/40 backdrop-blur-md shadow-2xl min-h-[350px]">
            {loading && (
                <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/60">
                    <div className="flex flex-col items-center gap-3">
                        <div className="w-8 h-8 border-4 border-brand border-t-transparent rounded-full animate-spin" />
                        <span className="text-[10px] font-black text-white/40 uppercase tracking-widest">CARGANDO MERCADO...</span>
                    </div>
                </div>
            )}
            {error && !loading && (
                <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/80">
                    <div className="p-4 rounded-xl bg-danger/10 border border-danger/20 text-center max-w-[80%]">
                        <p className="text-xs font-black text-danger uppercase mb-1">DATA ERROR</p>
                        <p className="text-[10px] text-white/60 uppercase">{error}: {symbol}</p>
                    </div>
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
