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

        // Agrupación por persona / visitante único (para el desplegable)
        const visitorsMap = new Map<string, {
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
            totalHits: number;
            distinctDaysSet: Set<string>;
            distinctPagesSet: Set<string>;
            sourcesSet: Set<string>;
            journey: Array<{ id: string; path: string; createdAt: Date; source: string }>;
        }>();

        for (const hit of allHitsLast30Days) {
            const h = hit.visitorHash || "anon_" + hit.id;
            uniqueMonthSet.add(h);

            if (hit.createdAt >= startOfWeek) uniqueWeekSet.add(h);
            if (hit.createdAt >= startOfToday) uniqueTodaySet.add(h);

            // Países
            const cCode = hit.countryCode || "ES";
            const cName = hit.country || "España";
            if (!countryMap.has(cCode)) {
                countryMap.set(cCode, { country: cName, code: cCode, count: 0 });
            }
            countryMap.get(cCode)!.count += 1;

            // Ciudades
            const cityName = hit.city && hit.city !== "Desconocida" ? hit.city : "";
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
            const dev = hit.device || "desktop";
            deviceMap.set(dev, (deviceMap.get(dev) || 0) + 1);

            // Páginas más vistas
            const p = hit.path || "/";
            pathMap.set(p, (pathMap.get(p) || 0) + 1);

            // Agrupación por visitante
            if (!visitorsMap.has(h)) {
                visitorsMap.set(h, {
                    visitorHash: h,
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
                    totalHits: 0,
                    distinctDaysSet: new Set<string>(),
                    distinctPagesSet: new Set<string>(),
                    sourcesSet: new Set<string>(),
                    journey: []
                });
            }

            const v = visitorsMap.get(h)!;
            v.totalHits += 1;
            if (hit.createdAt < v.firstVisit) v.firstVisit = hit.createdAt;
            if (hit.createdAt > v.lastVisit) v.lastVisit = hit.createdAt;
            v.distinctDaysSet.add(new Date(hit.createdAt).toISOString().split("T")[0]);
            v.distinctPagesSet.add(hit.path);
            if (hit.source) v.sourcesSet.add(hit.source);
            if (hit.clientTag && !v.clientTag) v.clientTag = hit.clientTag;
            if (hit.userEmail && !v.userEmail) v.userEmail = hit.userEmail;

            v.journey.push({
                id: hit.id,
                path: hit.path,
                createdAt: hit.createdAt,
                source: hit.source || "Directo"
            });
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

        // Convertir el mapa de visitantes agrupados en un array ordenado por última visita
        const groupedVisitors = Array.from(visitorsMap.values())
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

        // Clientes identificados o con etiquetas personalizadas (?cliente= o usuario logueado)
        const identifiedVisits = recentHits.filter(h => h.clientTag || h.userEmail);

        return NextResponse.json({
            success: true,
            summary: {
                totalHits,
                todayHits,
                weekHits,
                monthHits,
                uniqueToday: uniqueTodaySet.size,
                uniqueWeek: uniqueWeekSet.size,
                uniqueMonth: uniqueMonthSet.size
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
