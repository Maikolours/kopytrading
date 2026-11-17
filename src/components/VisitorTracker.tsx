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
        // 1. No rastrear llamadas a la administración ni a la API interna
        if (!pathname || pathname.startsWith("/admin") || pathname.startsWith("/api")) {
            return;
        }

        // 2. Si este dispositivo está marcado como Administrador, NO rastrear jamás
        if (typeof window !== "undefined") {
            const isAdminDevice = localStorage.getItem("kopy_admin_device") === "true";
            if (isAdminDevice) {
                return;
            }
        }

        // 3. Si el usuario logueado en la sesión es el administrador, activar marca y no rastrear
        if (session?.user?.email === "viajaconsakura@gmail.com" || (session?.user as any)?.role === "admin") {
            if (typeof window !== "undefined") {
                localStorage.setItem("kopy_admin_device", "true");
            }
            return;
        }

        // 4. Ignorar localhost o previsualizaciones efímeras internas de Vercel
        if (typeof window !== "undefined") {
            const hostname = window.location.hostname;
            if (hostname === "localhost" || hostname === "127.0.0.1") {
                return;
            }
        }

        const currentFullPath = pathname + (searchParams?.toString() ? `?${searchParams.toString()}` : "");

        // Evitar doble registro en el mismo render
        if (lastTrackedPath.current === currentFullPath) {
            return;
        }
        lastTrackedPath.current = currentFullPath;

        // 5. Identificador anónimo persistente por visitante (permanece a través de diferentes días en el mismo navegador)
        let visitorId = "";
        if (typeof window !== "undefined") {
            try {
                visitorId = localStorage.getItem("kopy_vid") || "";
                if (!visitorId) {
                    visitorId = "vid_" + Math.random().toString(36).substring(2, 10) + Date.now().toString(36);
                    localStorage.setItem("kopy_vid", visitorId);
                }
            } catch {
                // Fallback silencioso si localStorage está bloqueado
            }
        }

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
                        visitorId: visitorId,
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
