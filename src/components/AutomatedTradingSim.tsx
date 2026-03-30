"use client";

import React, { useEffect, useState } from "react";
import { LineChart, Activity, TrendingUp, Cpu, Lock, Terminal } from "lucide-react";

export function AutomatedTradingSim() {
    const [dots, setDots] = useState<number[]>([]);
    const [logs, setLogs] = useState<string[]>([]);

    useEffect(() => {
        // Generate initial chart data
        const initial = Array.from({ length: 40 }, () => Math.floor(Math.random() * 50) + 20);
        setDots(initial);

        // Initial logs
        setLogs([
            "[SYSTEM] KopyTrading AI Core v3.2 initialized.",
            "[NETWORK] Connected to MT5 Server. Latency: 12ms",
            "[SCAN] Analyzing XAUUSD on M15 timeframe...",
        ]);

        const interval = setInterval(() => {
            setDots((prev) => {
                const next = [...prev.slice(1)];
                const last = prev[prev.length - 1];
                // random walk
                let newVal = last + (Math.random() * 20 - 10);
                if (newVal > 90) newVal = 90;
                if (newVal < 10) newVal = 10;
                next.push(newVal);
                return next;
            });

            // push random logs
            const possibleLogs = [
                "[INFO] Updating Trailing Stop: +$2.50",
                "[EXEC] Break Even Activated on Buy Order ticket #894231",
                "[SCAN] EMA Alignment Detected. Wait for RSI.",
                "[INFO] Spread optimal: 0.8 pips",
                "[EXEC] Buy XAUUSD @ 2050.40 | Lote 0.01",
                "[SYS] Memory usage: 45MB - All systems nominal.",
            ];
            if (Math.random() > 0.6) {
                setLogs((prev) => {
                    const randLog = possibleLogs[Math.floor(Math.random() * possibleLogs.length)];
                    const newLogs = [...prev, randLog];
                    if (newLogs.length > 6) return newLogs.slice(newLogs.length - 6);
                    return newLogs;
                });
            }
        }, 1000);

        return () => clearInterval(interval);
    }, []);

    return (
        <div className="w-full h-full bg-slate-900 flex flex-col font-mono text-xs text-slate-300 relative overflow-hidden group">
            {/* Background Grid */}
            <div
                className="absolute inset-0 opacity-20 pointer-events-none"
                style={{ backgroundImage: 'linear-gradient(#334155 1px, transparent 1px), linear-gradient(90deg, #334155 1px, transparent 1px)', backgroundSize: '2rem 2rem' }}
            />

            {/* Header Bar */}
            <div className="flex bg-slate-800/80 border-b border-white/10 p-2 items-center justify-between z-10 shrink-0">
                <div className="flex items-center gap-3">
                    <div className="flex gap-1.5">
                        <span className="w-2.5 h-2.5 rounded-full bg-red-500/80"></span>
                        <span className="w-2.5 h-2.5 rounded-full bg-yellow-500/80"></span>
                        <span className="w-2.5 h-2.5 rounded-full bg-green-500/80"></span>
                    </div>
                    <span className="font-bold text-slate-100 flex items-center gap-2">
                        <Cpu className="w-4 h-4 text-brand-light" />
                        KopyTrading Algorithmic Engine
                    </span>
                </div>
                <div className="flex gap-4 items-center">
                    <span className="text-success flex items-center gap-1.5"><span className="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></span> ONLINE</span>
                    <span className="text-slate-400">Ping: 12ms</span>
                </div>
            </div>

            <div className="flex flex-1 overflow-hidden z-10">
                {/* Left Sidebar */}
                <div className="w-48 bg-slate-800/40 border-r border-white/10 p-3 hidden sm:flex flex-col gap-4">
                    <div>
                        <div className="text-[10px] text-slate-500 mb-1 uppercase tracking-wider">Active Pairs</div>
                        <div className="flex justify-between items-center text-slate-200 bg-slate-800 rounded px-2 py-1 border border-white/5">
                            <span>XAUUSD</span>
                            <span className="text-success text-[10px]">+0.4%</span>
                        </div>
                        <div className="flex justify-between items-center text-slate-400 px-2 py-1 mt-1 hover:text-slate-200 transition-colors">
                            <span>EURUSD</span>
                            <span className="text-danger text-[10px]">-0.1%</span>
                        </div>
                    </div>

                    <div>
                        <div className="text-[10px] text-slate-500 mb-1 uppercase tracking-wider">Metrics</div>
                        <div className="space-y-1">
                            <div className="flex justify-between"><span className="text-slate-400">Profit</span><span className="text-success font-bold">+$124.50</span></div>
                            <div className="flex justify-between"><span className="text-slate-400">Drawdown</span><span>1.2%</span></div>
                            <div className="flex justify-between"><span className="text-slate-400">Win Rate</span><span>78%</span></div>
                        </div>
                    </div>
                </div>

                {/* Main Chart Area */}
                <div className="flex-1 flex flex-col relative p-4 gap-4">
                    <div className="flex justify-between items-end mb-2">
                        <div className="flex items-center gap-2">
                            <Activity className="w-5 h-5 text-brand-light" />
                            <h3 className="text-lg text-white font-bold tracking-tight">XAUUSD Live Action</h3>
                        </div>
                        <div className="flex gap-2">
                            <span className="px-2 py-0.5 rounded bg-brand/20 text-brand-light border border-brand/30">M15</span>
                            <span className="px-2 py-0.5 rounded bg-slate-800 text-slate-400 border border-white/10">Algorithms: ON</span>
                        </div>
                    </div>

                    {/* Animated Line Chart SVG */}
                    <div className="flex-1 relative bg-slate-900 border border-white/10 rounded-lg overflow-hidden flex items-end">
                        <svg width="100%" height="100%" preserveAspectRatio="none" className="absolute inset-0">
                            <defs>
                                <linearGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stopColor="rgba(167, 139, 250, 0.3)" />
                                    <stop offset="100%" stopColor="rgba(167, 139, 250, 0)" />
                                </linearGradient>
                            </defs>
                            <path
                                d={`M 0,100 ${dots.map((val, i) => `L ${(i / (dots.length - 1)) * 100},${100 - val}`).join(' ')} L 100,100 Z`}
                                fill="url(#chartGrad)"
                                className="transition-all duration-1000 ease-linear"
                                vectorEffect="non-scaling-stroke"
                            />
                            <path
                                d={`M 0,${100 - dots[0]} ${dots.map((val, i) => `L ${(i / (dots.length - 1)) * 100},${100 - val}`).join(' ')}`}
                                fill="none"
                                stroke="#a78bfa"
                                strokeWidth="2"
                                className="transition-all duration-1000 ease-linear"
                                vectorEffect="non-scaling-stroke"
                            />
                        </svg>

                        {/* Blinking Dot at the end */}
                        <div
                            className="absolute w-2.5 h-2.5 bg-brand-light rounded-full shadow-[0_0_10px_#a78bfa] transition-all duration-1000 ease-linear"
                            style={{
                                left: '100%',
                                bottom: `${dots[dots.length - 1]}%`,
                                transform: 'translate(-50%, 50%)'
                            }}
                        >
                            <div className="absolute inset-0 bg-brand-light rounded-full animate-ping opacity-75"></div>
                        </div>
                    </div>

                    {/* Terminal / Logs Area */}
                    <div className="h-28 sm:h-32 bg-black/50 border border-white/10 rounded-lg p-2 overflow-y-auto overflow-x-hidden flex flex-col justify-end min-w-0">
                        {logs.map((log, i) => (
                            <div key={i} className={`text-[9px] sm:text-xs md:text-sm break-words leading-tight mb-1 sm:mb-0 ${log.includes('[EXEC]') ? 'text-brand-light' : log.includes('[SCAN]') ? 'text-amber-400' : 'text-slate-400'} animate-fade-in-up`}>
                                <span className="opacity-50 mr-1.5 hidden sm:inline">{new Date().toLocaleTimeString()}</span>
                                <span className="opacity-50 mr-1.5 sm:hidden">{new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                {log}
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* Glare effect */}
            <div className="absolute inset-0 bg-gradient-to-tr from-white/5 via-transparent to-transparent pointer-events-none"></div>
        </div>
    );
}
