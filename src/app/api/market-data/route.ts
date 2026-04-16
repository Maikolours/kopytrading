import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url);
    const symbol = (searchParams.get("symbol") || "BTCUSDT").toUpperCase();
    
    // Lista de mirrors de Binance para máxima redundancia
    const origins = [
        "https://api.binance.com",
        "https://api1.binance.com",
        "https://api2.binance.com",
        "https://api3.binance.com"
    ];

    let lastError = "";

    for (const origin of origins) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 4000); // 4s timeout

            const response = await fetch(`${origin}/api/v3/klines?symbol=${symbol}&interval=1m&limit=80`, {
                next: { revalidate: 0 },
                signal: controller.signal
            });

            clearTimeout(timeoutId);

            if (response.ok) {
                const data = await response.json();
                return NextResponse.json(data);
            } else {
                lastError = `Origin ${origin} returned ${response.status}`;
            }
        } catch (error: any) {
            lastError = `Connection failed to ${origin}: ${error.message}`;
        }
    }

    // Auditoría de Error en la Base de Datos para depuración remota
    try {
        await prisma.requestLog.create({
            data: {
                path: "/api/market-data",
                method: "GET",
                body: `SYM:${symbol}`,
                error: `BINANCE_BLOCK: ${lastError}`
            }
        });
    } catch (e) {}

    return NextResponse.json({ error: "No se pudo conectar con el mercado", detail: lastError }, { status: 502 });
}
