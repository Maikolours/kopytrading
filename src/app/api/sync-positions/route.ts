import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
    let body = null;
    try {
        body = await req.json();
        const { purchaseId, account, positions, history } = body;

        if (!purchaseId || !account) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: "Missing purchaseId or account" }
            });
            return NextResponse.json({ error: "Missing purchaseId or account" }, { status: 400 });
        }

        // Verificar que la compra existe
        const purchase = await prisma.purchase.findUnique({
            where: { id: purchaseId }
        });

        if (!purchase) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: "Purchase not found: " + purchaseId }
            });
            return NextResponse.json({ error: "Purchase not found" }, { status: 404 });
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
                        type: pos.type,
                        symbol: pos.symbol,
                        lots: Number(pos.lots),
                        openPrice: Number(pos.openPrice),
                        tp: Number(pos.tp),
                        sl: Number(pos.sl),
                        profit: Number(pos.profit)
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
                            type: h.type,
                            symbol: h.symbol,
                            lots: Number(h.lots),
                            openPrice: Number(h.openPrice),
                            closePrice: Number(h.closePrice),
                            profit: Number(h.profit),
                            closedAt: new Date()
                        }
                    });
                }
            }
        }

        // Registrar éxito silencioso (opcional, pero ayuda a depurar)
        /*
        await prisma.requestLog.create({
            data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body).substring(0, 500) }
        });
        */

        return NextResponse.json({ success: true });
    } catch (err: any) {
        console.error("Sync Positions Error:", err);
        await prisma.requestLog.create({
            data: { 
                path: "/api/sync-positions", 
                method: "POST", 
                body: JSON.stringify(body), 
                error: err.message || "Unknown error" 
            }
        });
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
