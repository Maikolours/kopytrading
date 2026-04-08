"use client";

import React, { useEffect, useRef, memo } from 'react';
import { createChart, ColorType, ISeriesApi, IChartApi } from 'lightweight-charts';

interface OperativoChartProps {
    fiboLevels?: {
        p00: number;
        p50: number;
        p62: number;
        p78: number;
        p100: number;
    };
    trend?: string;
}

const OperativoChart: React.FC<OperativoChartProps> = ({ fiboLevels, trend }) => {
    const chartContainerRef = useRef<HTMLDivElement>(null);
    const chartRef = useRef<IChartApi | null>(null);
    const candleSeriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);

    useEffect(() => {
        if (!chartContainerRef.current) return;

        const chart = createChart(chartContainerRef.current, {
            layout: {
                background: { type: ColorType.Solid, color: 'transparent' },
                textColor: 'rgba(255, 255, 255, 0.5)',
            },
            grid: {
                vertLines: { color: 'rgba(255, 255, 255, 0.05)' },
                horzLines: { color: 'rgba(255, 255, 255, 0.05)' },
            },
            width: chartContainerRef.current.clientWidth,
            height: 400,
            timeScale: {
                borderColor: 'rgba(255, 255, 255, 0.1)',
                timeVisible: true,
                secondsVisible: false,
            },
        });

        const candleSeries = chart.addCandlestickSeries({
            upColor: '#10b981',
            downColor: '#ef4444',
            borderVisible: false,
            wickUpColor: '#10b981',
            wickDownColor: '#ef4444',
        });

        chartRef.current = chart;
        candleSeriesRef.current = candleSeries;

        // Fetch initial data (Binance Public 1h)
        fetch('https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100')
            .then(res => res.json())
            .then(data => {
                const formattedData = data.map((d: any) => ({
                    time: d[0] / 1000,
                    open: parseFloat(d[1]),
                    high: parseFloat(d[2]),
                    low: parseFloat(d[3]),
                    close: parseFloat(d[4]),
                }));
                candleSeries.setData(formattedData);
            });

        const handleResize = () => {
            chart.applyOptions({ width: chartContainerRef.current?.clientWidth });
        };

        window.addEventListener('resize', handleResize);

        return () => {
            window.removeEventListener('resize', handleResize);
            chart.remove();
        };
    }, []);

    // Effect to update Fibonacci Lines
    useEffect(() => {
        if (!candleSeriesRef.current || !fiboLevels) return;

        // Limpiar líneas anteriores (una forma simple es guardarlas, pero aquí usaremos el mecanismo de lightweight)
        // Por ahora, añadimos las líneas si los niveles son válidos
        const { p00, p50, p62, p78, p100 } = fiboLevels;
        
        if (p00 > 0) {
            // Eliminar todas las lineas de precio previas si fuera necesario
            // candleSeriesRef.current.createPriceLine({...})
            
            // TARGET TP (0.0)
            candleSeriesRef.current.createPriceLine({
                price: p00,
                color: '#10b981',
                lineWidth: 2,
                lineStyle: 0, // Solid
                axisLabelVisible: true,
                title: 'TARGET TP (0.0)',
            });

            // GATILLO (50.0)
            candleSeriesRef.current.createPriceLine({
                price: p50,
                color: '#f59e0b',
                lineWidth: 1,
                lineStyle: 2, // Dashed
                axisLabelVisible: true,
                title: 'GATILLO (50.0)',
            });

            // ENTRADA (61.8)
            candleSeriesRef.current.createPriceLine({
                price: p62,
                color: '#fbbf24',
                lineWidth: 2,
                lineStyle: 0,
                axisLabelVisible: true,
                title: 'ENTRADA (61.8)',
            });

            // STOP LOSS (78.6)
            candleSeriesRef.current.createPriceLine({
                price: p78,
                color: '#ef4444',
                lineWidth: 2,
                lineStyle: 0,
                axisLabelVisible: true,
                title: 'STOP LOSS (78.6)',
            });

             // ORIGEN (100.0)
             candleSeriesRef.current.createPriceLine({
                price: p100,
                color: '#9ca3af',
                lineWidth: 1,
                lineStyle: 2,
                axisLabelVisible: true,
                title: 'ORIGEN (100.0)',
            });
        }
    }, [fiboLevels]);

    return (
        <div className="relative w-full rounded-2xl overflow-hidden border border-white/5 bg-black/40">
            <div ref={chartContainerRef} className="w-full" />
            <div className="absolute top-4 left-4 flex flex-col gap-1 pointer-events-none">
                <span className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em]">Elite Sniper v11.3.9</span>
                <span className={`text-[12px] font-black uppercase tracking-widest ${trend === 'BULL' ? 'text-emerald-400' : 'text-rose-400'}`}>
                    Market: {trend === 'BULL' ? 'ALCISTA' : 'BAJISTA'}
                </span>
            </div>
        </div>
    );
};

export default memo(OperativoChart);
