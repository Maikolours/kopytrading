"use client";

import { useEffect, useRef, Suspense } from "react";
import { usePathname, useSearchParams } from "next/navigation";
import { useSession } from "next-auth/react";

function VisitorTrackerInternal() {
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const { data: session } = useSession();
    const lastTrackedPath = useRef<string | null>(null);

    useEffect(() => {
        // No rastrear llamadas a la propia administración para no contaminar estadísticas
        if (!pathname || pathname.startsWith("/admin") || pathname.startsWith("/api")) {
            return;
        }

        const currentFullPath = pathname + (searchParams?.toString() ? `?${searchParams.toString()}` : "");

        // Evitar doble registro en el mismo render
        if (lastTrackedPath.current === currentFullPath) {
            return;
        }
        lastTrackedPath.current = currentFullPath;

        // Comprobar parámetros de cliente o campaña
        const clientTag = searchParams?.get("cliente") || searchParams?.get("ref") || searchParams?.get("utm_campaign") || null;
        const referrer = typeof document !== "undefined" ? document.referrer : "";
        const userEmail = session?.user?.email || null;

        // Enviar evento de tracking al servidor de forma asíncrona
        const trackHit = async () => {
            try {
                await fetch("/api/analytics/track", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        path: pathname,
                        referrer: referrer,
                        clientTag: clientTag,
                        userEmail: userEmail,
                    }),
                    keepalive: true,
                });
            } catch {
                // Silencioso para no interferir con la navegación del usuario
            }
        };

        const timer = setTimeout(trackHit, 800);
        return () => clearTimeout(timer);
    }, [pathname, searchParams, session]);

    return null;
}

export function VisitorTracker() {
    return (
        <Suspense fallback={null}>
            <VisitorTrackerInternal />
        </Suspense>
    );
}
