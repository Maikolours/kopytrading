"use client";

import { useState, useTransition } from "react";
import { Button } from "./ui/Button";
import { useRouter } from "next/navigation";

interface CleanupButtonProps {
    purchaseId: string;
}

export function CleanupButton({ purchaseId }: CleanupButtonProps) {
    const [loading, setLoading] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);
    const [isPending, startTransition] = useTransition();
    const router = useRouter();

    const handleCleanup = async () => {
        if (!showConfirm) {
            setShowConfirm(true);
            setTimeout(() => setShowConfirm(false), 3000); // Reset after 3s
            return;
        }

        setLoading(true);
        try {
            const res = await fetch("/api/dashboard/cleanup", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ purchaseId })
            });

            if (res.ok) {
                // Refrescar la página sin bloquear la UI
                startTransition(() => {
                    router.refresh();
                });
                setShowConfirm(false);
            } else {
                alert("Error al limpiar el historial.");
            }
        } catch (error) {
            alert("Error de conexión.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <Button 
            variant="outline" 
            size="sm" 
            onClick={handleCleanup}
            loading={loading || isPending}
            className={`text-[10px] font-black uppercase tracking-tighter h-7 px-3 transition-all shadow-lg ${
                showConfirm 
                ? 'bg-amber-500/20 border-amber-500/50 text-amber-400 animate-pulse' 
                : 'bg-red-500/10 border-red-500/30 text-red-500 hover:bg-red-500/20 shadow-red-500/10'
            }`}
        >
            {showConfirm ? "⚠️ ¿CONFIRMAR LIMPIEZA?" : "🧹 LIMPIAR DASHBOARD"}
        </Button>
    );
}
