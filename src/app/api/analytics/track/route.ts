import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import crypto from "crypto";

export const dynamic = "force-dynamic";

const COUNTRY_NAMES: Record<string, string> = {
    ES: "España",
    MX: "México",
    CO: "Colombia",
    AR: "Argentina",
    CL: "Chile",
    PE: "Perú",
    EC: "Ecuador",
    US: "Estados Unidos",
    VE: "Venezuela",
    UY: "Uruguay",
    PY: "Paraguay",
    BO: "Bolivia",
    CR: "Costa Rica",
    PA: "Panamá",
    DO: "Rep. Dominicana",
    GT: "Guatemala",
    HN: "Honduras",
    SV: "El Salvador",
    NI: "Nicaragua",
    GB: "Reino Unido",
    DE: "Alemania",
    FR: "Francia",
    IT: "Italia",
    PT: "Portugal",
    CH: "Suiza",
    AD: "Andorra",
};

export async function POST(req: Request) {
    try {
        const body = await req.json().catch(() => ({}));
        const { path = "/", referrer = "", clientTag = null, userEmail = null, visitorId = null } = body;

        // 1. Si es el administrador navegando, no inflar las métricas
        if (userEmail === "viajaconsakura@gmail.com" || userEmail === "viajaconsakura") {
            return NextResponse.json({ success: true, ignored: "admin" });
        }

        const userAgent = req.headers.get("user-agent") || "";
        const uaLower = userAgent.toLowerCase();

        // 2. Ignorar bots de rastreo automáticos (Googlebot, Bingbot, scrapers, headless)
        if (/bot|crawler|spider|googlebot|bingbot|slurp|duckduckbot|baiduspider|yandex|sogou|exabot|facebot|ia_archiver|semrush|ahrefs|headless|phantomjs/i.test(uaLower)) {
            return NextResponse.json({ success: true, ignored: "bot" });
        }

        // 3. Geometría y ubicación (headers automáticos de Vercel)
        const countryCode = (req.headers.get("x-vercel-ip-country") || "ES").toUpperCase();
        const countryName = COUNTRY_NAMES[countryCode] || countryCode;
        const rawCity = req.headers.get("x-vercel-ip-city");
        const city = rawCity ? decodeURIComponent(rawCity) : "Desconocida";

        // 4. Ignorar robots automáticos de verificación y capturas de Vercel (San José, Linux, etc.)
        const host = req.headers.get("host") || "";
        const forwardedHost = req.headers.get("x-forwarded-host") || "";
        if (
            (city === "San Jose" || city === "San Francisco") &&
            uaLower.includes("linux") &&
            (!referrer || host.includes("vercel.app") || forwardedHost.includes("vercel.app"))
        ) {
            return NextResponse.json({ success: true, ignored: "vercel_internal_preview_bot" });
        }

        // Obtener IP (para hash de respaldo)
        const forwarded = req.headers.get("x-forwarded-for");
        const ip = forwarded ? forwarded.split(",")[0].trim() : req.headers.get("x-real-ip") || "127.0.0.1";

        // 5. Identificador anónimo persistente por visitante:
        // Si el navegador envió visitorId, lo convertimos en un hash seguro y consistente en el tiempo.
        // Si no lo envió, usamos IP + UserAgent de forma estable (sin incluir la fecha) para que
        // si la misma persona regresa mañana o la semana que viene, se reconozca que es el mismo visitante.
        let visitorHash = "";
        if (visitorId && typeof visitorId === "string" && visitorId.length >= 5) {
            visitorHash = crypto.createHash("sha256").update(`kopy_${visitorId}`).digest("hex").slice(0, 16);
        } else {
            visitorHash = crypto.createHash("sha256").update(`${ip}_${userAgent}`).digest("hex").slice(0, 16);
        }

        // Detección de Dispositivo
        let device = "desktop";
        if (/tablet|ipad/i.test(uaLower)) {
            device = "tablet";
        } else if (/mobile|iphone|android|blackberry|iemobile|opera mini/i.test(uaLower)) {
            device = "mobile";
        }

        // Detección de Navegador
        let browser = "Otro";
        if (uaLower.includes("edg/")) browser = "Edge";
        else if (uaLower.includes("chrome") && !uaLower.includes("chromium")) browser = "Chrome";
        else if (uaLower.includes("safari") && !uaLower.includes("chrome")) browser = "Safari";
        else if (uaLower.includes("firefox")) browser = "Firefox";
        else if (uaLower.includes("opera") || uaLower.includes("opr/")) browser = "Opera";

        // Detección de Sistema Operativo
        let os = "Otro";
        if (uaLower.includes("windows")) os = "Windows";
        else if (uaLower.includes("android")) os = "Android";
        else if (uaLower.includes("iphone") || uaLower.includes("ipad") || uaLower.includes("ios")) os = "iOS";
        else if (uaLower.includes("macintosh") || uaLower.includes("mac os")) os = "macOS";
        else if (uaLower.includes("linux")) os = "Linux";

        // Detección de Origen del Tráfico
        const refLower = (referrer || req.headers.get("referer") || "").toLowerCase();
        let source = "Directo";

        if (clientTag) {
            source = `Cliente: ${clientTag}`;
        } else if (refLower.includes("instagram.com")) {
            source = "Instagram";
        } else if (refLower.includes("facebook.com") || refLower.includes("fb.me")) {
            source = "Facebook";
        } else if (refLower.includes("tiktok.com")) {
            source = "TikTok";
        } else if (refLower.includes("google.")) {
            source = "Google";
        } else if (refLower.includes("t.co") || refLower.includes("twitter.com") || refLower.includes("x.com")) {
            source = "Twitter/X";
        } else if (refLower.includes("whatsapp") || refLower.includes("wa.me")) {
            source = "WhatsApp";
        } else if (refLower.includes("telegram") || refLower.includes("t.me")) {
            source = "Telegram";
        } else if (refLower.includes("youtube.com") || refLower.includes("youtu.be")) {
            source = "YouTube";
        } else if (refLower.includes("kopytrading.com")) {
            source = "Navegación Interna";
        } else if (refLower.length > 0) {
            try {
                const u = new URL(refLower);
                source = u.hostname.replace("www.", "");
            } catch {
                source = "Otro";
            }
        }

        await prisma.visitorHit.create({
            data: {
                path: path.slice(0, 255),
                country: countryName,
                countryCode: countryCode,
                city: city,
                device: device,
                browser: browser,
                os: os,
                source: source,
                referrer: (referrer || "").slice(0, 500),
                clientTag: clientTag ? String(clientTag).slice(0, 100) : null,
                userEmail: userEmail ? String(userEmail).slice(0, 150) : null,
                visitorHash: visitorHash
            }
        });

        return NextResponse.json({ success: true });
    } catch (error: any) {
        console.error("Analytics Track Error:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
