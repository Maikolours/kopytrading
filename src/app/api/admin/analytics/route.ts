import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export async function GET() {
    const session = await getServerSession(authOptions);

    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        const now = new Date();
        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const startOfMonth = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        // Conteos generales
        const [
            totalHits,
            todayHits,
            weekHits,
            monthHits,
            recentHits,
            allHitsLast30Days
        ] = await Promise.all([
            prisma.visitorHit.count(),
            prisma.visitorHit.count({ where: { createdAt: { gte: startOfToday } } }),
            prisma.visitorHit.count({ where: { createdAt: { gte: startOfWeek } } }),
            prisma.visitorHit.count({ where: { createdAt: { gte: startOfMonth } } }),
            prisma.visitorHit.findMany({
                orderBy: { createdAt: "desc" },
                take: 60,
                select: {
                    id: true,
                    path: true,
                    country: true,
                    countryCode: true,
                    city: true,
                    device: true,
                    browser: true,
                    os: true,
                    source: true,
                    clientTag: true,
                    userEmail: true,
                    visitorHash: true,
                    createdAt: true
                }
            }),
            prisma.visitorHit.findMany({
                where: { createdAt: { gte: startOfMonth } },
                orderBy: { createdAt: "desc" },
                select: {
                    id: true,
                    country: true,
                    countryCode: true,
                    city: true,
                    device: true,
                    browser: true,
                    os: true,
                    source: true,
                    path: true,
                    visitorHash: true,
                    clientTag: true,
                    userEmail: true,
                    createdAt: true
                }
            })
        ]);

        // Calcular Visitantes Únicos y Métricas
        const uniqueTodaySet = new Set<string>();
        const uniqueWeekSet = new Set<string>();
        const uniqueMonthSet = new Set<string>();

        const countryMap = new Map<string, { country: string; code: string; count: number }>();
        const cityMap = new Map<string, { city: string; country: string; count: number }>();
        const sourceMap = new Map<string, number>();
        const deviceMap = new Map<string, number>();
        const pathMap = new Map<string, number>();

        // Agrupación inteligente por persona / sesión continua
        // Ordenamos cronológicamente para asociar cada navegación a su sesión correspondiente
        const sortedHitsForGrouping = [...allHitsLast30Days].sort(
            (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
        );

        interface VisitorSession {
            id: string;
            visitorHash: string;
            country: string;
            countryCode: string;
            city: string;
            device: string;
            browser: string;
            os: string;
            clientTag: string | null;
            userEmail: string | null;
            firstVisit: Date;
            lastVisit: Date;
            lastTimeMs: number;
            totalHits: number;
            distinctDaysSet: Set<string>;
            distinctPagesSet: Set<string>;
            sourcesSet: Set<string>;
            journey: Array<{ id: string; path: string; createdAt: Date; source: string }>;
        }

        const sessionsList: VisitorSession[] = [];

        for (const hit of sortedHitsForGrouping) {
            const hitTime = new Date(hit.createdAt).getTime();
            const cityName = hit.city && hit.city !== "Desconocida" ? hit.city : "";
            const cCode = hit.countryCode || "ES";
            const cName = hit.country || "España";
            const dev = hit.device || "desktop";

            // Países
            if (!countryMap.has(cCode)) {
                countryMap.set(cCode, { country: cName, code: cCode, count: 0 });
            }
            countryMap.get(cCode)!.count += 1;

            // Ciudades
            if (cityName) {
                const cityKey = `${cityName}_${cCode}`;
                if (!cityMap.has(cityKey)) {
                    cityMap.set(cityKey, { city: cityName, country: cName, count: 0 });
                }
                cityMap.get(cityKey)!.count += 1;
            }

            // Fuentes de tráfico
            const src = hit.source || "Directo";
            sourceMap.set(src, (sourceMap.get(src) || 0) + 1);

            // Dispositivos
            deviceMap.set(dev, (deviceMap.get(dev) || 0) + 1);

            // Páginas más vistas
            const p = hit.path || "/";
            pathMap.set(p, (pathMap.get(p) || 0) + 1);

            // Buscar si este hit pertenece a una sesión abierta del mismo visitante
            const matchedSession = sessionsList.find(s => {
                if (hit.userEmail && s.userEmail === hit.userEmail) return true;
                if (hit.clientTag && s.clientTag === hit.clientTag) return true;
                if (hit.visitorHash && s.visitorHash === hit.visitorHash) return true;
                // Si proviene de la misma ciudad y país en una ventana continua de 45 minutos
                if (
                    cityName &&
                    s.city === cityName &&
                    s.countryCode === cCode &&
                    Math.abs(hitTime - s.lastTimeMs) <= 45 * 60 * 1000
                ) {
                    return true;
                }
                return false;
            });

            if (matchedSession) {
                matchedSession.totalHits += 1;
                matchedSession.lastVisit = hit.createdAt;
                matchedSession.lastTimeMs = hitTime;
                matchedSession.distinctDaysSet.add(new Date(hit.createdAt).toISOString().split("T")[0]);
                matchedSession.distinctPagesSet.add(hit.path);
                if (hit.source) matchedSession.sourcesSet.add(hit.source);
                if (hit.clientTag && !matchedSession.clientTag) matchedSession.clientTag = hit.clientTag;
                if (hit.userEmail && !matchedSession.userEmail) matchedSession.userEmail = hit.userEmail;
                matchedSession.journey.push({
                    id: hit.id,
                    path: hit.path,
                    createdAt: hit.createdAt,
                    source: hit.source || "Directo"
                });
            } else {
                const newSession: VisitorSession = {
                    id: hit.id,
                    visitorHash: hit.visitorHash || "anon_" + hit.id,
                    country: cName,
                    countryCode: cCode,
                    city: cityName || "Ciudad Desconocida",
                    device: dev,
                    browser: hit.browser || "Chrome",
                    os: hit.os || "Windows",
                    clientTag: hit.clientTag || null,
                    userEmail: hit.userEmail || null,
                    firstVisit: hit.createdAt,
                    lastVisit: hit.createdAt,
                    lastTimeMs: hitTime,
                    totalHits: 1,
                    distinctDaysSet: new Set([new Date(hit.createdAt).toISOString().split("T")[0]]),
                    distinctPagesSet: new Set([hit.path]),
                    sourcesSet: new Set(hit.source ? [hit.source] : ["Directo"]),
                    journey: [{
                        id: hit.id,
                        path: hit.path,
                        createdAt: hit.createdAt,
                        source: hit.source || "Directo"
                    }]
                };
                sessionsList.push(newSession);
            }
        }

        // Ordenar listas
        const topCountries = Array.from(countryMap.values())
            .sort((a, b) => b.count - a.count)
            .slice(0, 10);

        const topCities = Array.from(cityMap.values())
            .sort((a, b) => b.count - a.count)
            .slice(0, 10);

        const topSources = Array.from(sourceMap.entries())
            .map(([source, count]) => ({ source, count }))
            .sort((a, b) => b.count - a.count);

        const devices = Array.from(deviceMap.entries())
            .map(([device, count]) => ({ device, count }));

        const topPages = Array.from(pathMap.entries())
            .map(([path, count]) => ({ path, count }))
            .sort((a, b) => b.count - a.count)
            .slice(0, 10);

        // Convertir sesiones en array ordenado por última visita
        const groupedVisitors = sessionsList
            .map(v => ({
                visitorHash: v.visitorHash,
                country: v.country,
                countryCode: v.countryCode,
                city: v.city,
                device: v.device,
                browser: v.browser,
                os: v.os,
                clientTag: v.clientTag,
                userEmail: v.userEmail,
                firstVisit: v.firstVisit,
                lastVisit: v.lastVisit,
                totalHits: v.totalHits,
                distinctDays: v.distinctDaysSet.size,
                distinctPages: v.distinctPagesSet.size,
                primarySource: Array.from(v.sourcesSet)[0] || "Directo",
                journey: v.journey.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
            }))
            .sort((a, b) => new Date(b.lastVisit).getTime() - new Date(a.lastVisit).getTime());

        // Visitantes únicos por ventana de tiempo
        const uniqueToday = sessionsList.filter(s => s.lastVisit >= startOfToday).length;
        const uniqueWeek = sessionsList.filter(s => s.lastVisit >= startOfWeek).length;
        const uniqueMonth = sessionsList.length;

        // Clientes identificados o con etiquetas personalizadas (?cliente= o usuario logueado)
        const identifiedVisits = recentHits.filter(h => h.clientTag || h.userEmail);

        return NextResponse.json({
            success: true,
            summary: {
                totalHits,
                todayHits,
                weekHits,
                monthHits,
                uniqueToday,
                uniqueWeek,
                uniqueMonth
            },
            topCountries,
            topCities,
            topSources,
            devices,
            topPages,
            groupedVisitors,
            recentHits,
            identifiedVisits
        });

    } catch (error: any) {
        console.error("Admin Analytics API Error:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}

// DELETE: Reiniciar historial de visitas de prueba
export async function DELETE() {
    const session = await getServerSession(authOptions);

    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        await prisma.visitorHit.deleteMany({});
        return NextResponse.json({ success: true, message: "Historial de analítica reiniciado con éxito." });
    } catch (error: any) {
        console.error("Admin Analytics Delete Error:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
