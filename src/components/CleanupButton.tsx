"use client";

import { useState } from "react";
import { Button } from "./ui/Button";
import { useRouter } from "next/navigation";

interface CleanupButtonProps {
    purchaseId: string;
}

export function CleanupButton({ purchaseId }: CleanupButtonProps) {
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const handleCleanup = async () => {
        if (!confirm("¿Estás seguro de que quieres limpiar la lista de operaciones de este bot en el panel web? Esto no afectará a tu MetaTrader 5, solo refrescará la vista de la web.")) {
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
                // Refrescar la página para ver los cambios
                router.refresh();
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
            loading={loading}
            className="text-[10px] font-black uppercase tracking-tighter h-7 px-3 bg-red-500/10 border-red-500/30 text-red-500 hover:bg-red-500/20 transition-all shadow-lg shadow-red-500/10"
        >
            🧹 LIMPIAR DASHBOARD
        </Button>
    );
}
