"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export function DashboardRefresher() {
    const router = useRouter();

    useEffect(() => {
        // Refrescar los datos del servidor cada 10 segundos
        const interval = setInterval(() => {
            router.refresh();
        }, 10000);

        return () => clearInterval(interval);
    }, [router]);

    return null; // Componente invisible
}
