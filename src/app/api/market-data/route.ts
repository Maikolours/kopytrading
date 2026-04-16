import { NextResponse } from "next/server";

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url);
    const symbol = searchParams.get("symbol") || "BTCUSDT";
    
    try {
        // Log de auditoría para ver qué se pide
        console.log(`[MARKET-DATA] Proxied request for: ${symbol}`);
        
        const response = await fetch(`https://api.binance.com/api/v3/klines?symbol=${symbol.toUpperCase()}&interval=1m&limit=80`, {
            next: { revalidate: 0 } // No cache para datos en vivo
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error(`[MARKET-DATA] Binance Error: ${response.status} - ${errorText}`);
            return NextResponse.json({ error: "Binance API unreachable" }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error("[MARKET-DATA] Critical Proxy Error:", error);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
