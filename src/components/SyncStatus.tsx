"use client";

import { useState, useEffect } from "react";

interface SyncStatusProps {
    initialLastSync: string | null;
}

export function SyncStatus({ initialLastSync }: SyncStatusProps) {
    const [lastSync, setLastSync] = useState<Date | null>(initialLastSync ? new Date(initialLastSync) : null);
    const [isOnline, setIsOnline] = useState(false);
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    useEffect(() => {
        const checkStatus = () => {
            if (!lastSync) {
                setIsOnline(false);
                return;
            }
            const now = new Date().getTime();
            const diff = now - lastSync.getTime();
            // Consideramos online si hubo sync en los últimos 15 segundos
            setIsOnline(diff < 15000);
        };

        checkStatus();
        const interval = setInterval(checkStatus, 5000); // Check cada 5s
        return () => clearInterval(interval);
    }, [lastSync]);

    if (!mounted || !lastSync) {
        return (
            <div className="mt-4 flex items-center gap-2 px-3 py-1.5 rounded-lg bg-surface-light/30 border border-white/5 w-fit">
                <div className="w-1.5 h-1.5 rounded-full bg-text-muted/30" />
                <span className="text-[10px] font-bold uppercase tracking-wider text-text-muted/60">
                    { !mounted ? 'Sincronizando...' : 'SIN CONEXIÓN MT5' }
                </span>
            </div>
        );
    }

    return (
        <div className="mt-4 flex items-center gap-2 px-3 py-1.5 rounded-lg bg-surface-light/30 border border-white/5 w-fit">
            <div className={`w-1.5 h-1.5 rounded-full ${isOnline ? 'bg-success animate-pulse' : 'bg-text-muted/30'}`} />
            <span className={`text-[10px] font-bold uppercase tracking-wider ${isOnline ? 'text-success' : 'text-text-muted/60'}`}>
                {isOnline ? '📡 LINK MT5: OK' : '📡 LINK MT5: OFFLINE'}
            </span>
            <span className="text-[9px] text-text-muted/40 italic ml-2">
                Ult. Sinc: {lastSync.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
            </span>
            {!isOnline && (
                <button 
                    onClick={() => window.location.reload()} 
                    className="ml-2 text-[8px] text-brand-light hover:underline uppercase font-bold"
                >
                    Refrescar
                </button>
            )}
        </div>
    );
}
