import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
    let body = null;
    let text = "";
    try {
        text = await req.text();
        // Limpiar posibles caracteres nulos al final (común en MQL5) y espacios
        const cleanText = text.replace(/\0/g, '').trim();
        body = JSON.parse(cleanText);
        
        const { purchaseId, account, positions, history, isReal } = body;

        if (!purchaseId || !account) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: text.substring(0, 1000), error: "Missing purchaseId or account" }
            });
            return NextResponse.json({ error: "Missing purchaseId or account" }, { status: 400 });
        }

        // Verificar que la compra existe y cargar su producto
        const purchase = await prisma.purchase.findUnique({
            where: { id: purchaseId },
            include: { botProduct: true }
        });

        if (!purchase) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: "Purchase not found: " + purchaseId }
            });
            return NextResponse.json({ error: "Purchase not found" }, { status: 404 });
        }

        // VALIDACIÓN DE CRUCE: Verificar que el instrumento coincide (ej: XAUUSD no puede entrar en un bot de BTC)
        // El bot envía el símbolo en las posiciones. Si no hay posiciones, enviamos el símbolo principal esperado.
        const botSymbol = positions && positions.length > 0 ? positions[0].symbol : body.symbol;
        const expectedInstrument = purchase.botProduct.instrument;

        if (botSymbol && expectedInstrument && !botSymbol.toUpperCase().includes(expectedInstrument.toUpperCase()) && !expectedInstrument.toUpperCase().includes(botSymbol.toUpperCase())) {
            // Permitir casos especiales (XAUUSD vs GOLD)
            const isXAU = (botSymbol.includes("XAU") || botSymbol.includes("GOLD")) && (expectedInstrument.includes("XAU") || expectedInstrument.includes("GOLD"));
            if (!isXAU) {
                await prisma.requestLog.create({
                    data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: `Crossover detected: Bot ${botSymbol} syncing to ${expectedInstrument} license.` }
                });
                return NextResponse.json({ error: "License type mismatch (Crossover detected)" }, { status: 403 });
            }
        }

        // Actualizar latido de conexión
        await prisma.purchase.update({
            where: { id: purchaseId },
            data: { lastSync: new Date() }
        });

        // Sincronizar posiciones abiertas: Borramos SOLO las de esta cuenta y creamos las nuevas
        await prisma.$transaction([
            prisma.livePosition.deleteMany({ 
                where: { purchaseId, account } 
            }),
            ...(positions || []).map((pos: any) => 
                prisma.livePosition.create({
                    data: {
                        purchaseId,
                        account,
                        ticket: String(pos.ticket),
                        type: pos.type || "UNKNOWN",
                        symbol: pos.symbol || "XAUUSD",
                        lots: Number(pos.lots) || 0.01,
                        openPrice: Number(pos.openPrice) || 0,
                        tp: Number(pos.tp) || 0,
                        sl: Number(pos.sl) || 0,
                        profit: Number(pos.profit) || 0,
                        isReal: Boolean(isReal)
                    }
                })
            )
        ]);

        // Guardar historial (solo si no existe el ticket para esta compra y cuenta)
        if (history && history.length > 0) {
            for (const h of history) {
                const exists = await prisma.tradeHistory.findFirst({
                    where: { purchaseId, account, ticket: String(h.ticket) }
                });

                if (!exists) {
                    await prisma.tradeHistory.create({
                        data: {
                            purchaseId,
                            account,
                            ticket: String(h.ticket),
                            type: h.type || "UNKNOWN",
                            symbol: h.symbol || "UNKNOWN",
                            lots: Number(h.lots) || 0,
                            openPrice: Number(h.openPrice) || 0,
                            closePrice: Number(h.closePrice) || 0,
                            profit: Number(h.profit) || 0,
                            isReal: Boolean(isReal),
                            closedAt: h.closedAt ? new Date(h.closedAt) : new Date()
                        }
                    });
                }
            }
        }

        // Registrar éxito silencioso (opcional, pero ayuda a depurar)
        await prisma.requestLog.create({
            data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body).substring(0, 500) }
        });

        return NextResponse.json({ success: true });
    } catch (err: any) {
        console.error("Sync Positions Error:", err);
        await prisma.requestLog.create({
            data: { 
                path: "/api/sync-positions", 
                method: "POST", 
                body: text.substring(0, 1000), 
                error: (err.message || "Unknown error") + " (Raw: " + text.substring(0, 100) + ")"
            }
        });
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
