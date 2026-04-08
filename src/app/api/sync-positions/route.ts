import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
    let body = null;
    let text = "";
    try {
        text = await req.text();
        // Limpiar posibles caracteres nulos al final (común en MQL5) y espacios
        const cleanText = text.replace(/\0/g, '').trim();
        
        try {
            body = JSON.parse(cleanText);
        } catch (e) {
            // ROBUSTEZ: Si falla el parseo, intentamos extraer solo el primer objeto JSON {...}
            // Útil para buffers de MT5 que vienen con basura extra al final
            const firstBrace = cleanText.indexOf('{');
            const lastBrace = cleanText.lastIndexOf('}');
            if (firstBrace !== -1 && lastBrace !== -1) {
                try {
                    body = JSON.parse(cleanText.substring(firstBrace, lastBrace + 1));
                } catch (innerE) {
                    throw new Error("Invalid JSON structure even after extraction");
                }
            } else {
                throw e;
            }
        }
        
        // NORMALIZACIÓN: Asegurar que el purchaseId sea siempre minúsculas y limpiar sufijos
        // Algunos bots envían cmmv3...-btccent o cmmv3...-oro
        let purchaseId = body.purchaseId ? body.purchaseId.trim().toLowerCase() : null;
        if (purchaseId && purchaseId.includes("-")) {
            purchaseId = purchaseId.split("-")[0]; // Nos quedamos solo con el CUID
        }
        
        const account = body.account ? String(body.account).trim() : null;
        const { positions, history, isReal } = body;

        if (!purchaseId || !account) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: text.substring(0, 1000), error: "Missing purchaseId or account" }
            });
            return NextResponse.json({ error: "Missing purchaseId or account" }, { status: 400 });
        }

        // 3. Verificar que la compra existe (Búsqueda Robusta)
        let purchase = await prisma.purchase.findUnique({
            where: { id: purchaseId },
            include: { botProduct: true }
        });

        // REINTENTO: Si no lo encuentra por ID exacto, lo buscamos en la base de datos sin importar mayúsculas
        if (!purchase) {
             const allPurchases = await prisma.purchase.findMany({
                 select: { id: true }
             });
             const matchingId = allPurchases.find((p: { id: string }) => p.id.toLowerCase() === purchaseId.toLowerCase())?.id;
             if (matchingId) {
                 purchase = await prisma.purchase.findUnique({
                     where: { id: matchingId },
                     include: { botProduct: true }
                 });
             }
        }

        if (!purchase) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: "Purchase not found (Robust Search Failed): " + purchaseId }
            });
            return NextResponse.json({ error: "Purchase not found" }, { status: 404 });
        }

        // 3b. VERIFICACIÓN DE PRODUCTO (Opcional): Si el bot envía licenseKey (XAU-MG, etc)
        if (body.licenseKey && purchase.botProduct.productKey && purchase.botProduct.productKey !== body.licenseKey) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: `ProductKey mismatch: Bot ${body.licenseKey} vs License ${purchase.botProduct.productKey}` }
            });
            return NextResponse.json({ error: "License product mismatch" }, { status: 403 });
        }

        // VALIDACIÓN DE CRUCE: Verificar que el instrumento coincide (ej: XAUUSD no puede entrar en un bot de BTC)
        const botSymbol = (positions && positions.length > 0 ? positions[0].symbol : (body.symbol || "XAUUSD")).toUpperCase();
        const expectedInstrument = (purchase.botProduct.instrument || "").toUpperCase();

        if (expectedInstrument && !botSymbol.includes(expectedInstrument) && !expectedInstrument.includes(botSymbol)) {
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

        // 4. SINCRO DE CONFIGURACIÓN Y TELEMETRÍA (v11.5)
        const DEFAULT_SETTINGS = {
            net_cycle: 5.0,
            hedge_trigger: 3.0,
            lote_manual: 0.08,
            lote_rescate: 0.02,
            max_dd: 50.0,
            trailling_stop: 3.0,
            limit_dist: 500,
            timeframe: "M5",
            lkb: 12,
            b1_be: 7.0, b1_gar: 4.0,
            b2_be: 8.0, b2_gar: 5.0,
            gr_be: 8.0, gr_gar: 5.0,
            casOn: true,
            autoRA: true
        };

        const telemetry = {
            balance: Number(body.balance) || 0,
            equity: Number(body.equity) || 0,
            pnl_today: Number(body.pnl_today) || 0,
            lkb: Number(body.lkb) || 12,
            trend: body.trend || "UNKNOWN",
            armed: body.armed === true || body.armed === "true",
            isOnline: true,
            lastUpdate: new Date().toISOString()
        };

        let currentSettings = null;
        try {
            // Buscamos settings existentes
            const existingRecord = await prisma.botSettings.findUnique({
                where: { purchaseId_account: { purchaseId, account: String(account) } }
            });

            const baseSettings = existingRecord ? (existingRecord.settings as any) : DEFAULT_SETTINGS;
            
            // Unificamos settings propuestos por el bot + telemetría
            const updatedSettings = {
                ...baseSettings,
                ...(body.proposedSettings || {}),
                ...telemetry,
                // Conservar campos específicos del Sniper si vienen en la raíz
                lots: Number(body.lots) || baseSettings.lots,
                casOn: body.cascada !== undefined ? (body.cascada === true || body.cascada === "true") : baseSettings.casOn,
                giroOn: body.giro !== undefined ? (body.giro === true || body.giro === "true") : baseSettings.giroOn,
                fearOn: body.fear !== undefined ? (body.fear === true || body.fear === "true") : baseSettings.fearOn,
            };

            currentSettings = await prisma.botSettings.upsert({
                where: { purchaseId_account: { purchaseId, account: String(account) } },
                update: { settings: updatedSettings },
                create: { purchaseId, account: String(account), settings: updatedSettings }
            });

        } catch (sErr) {
            console.error("Error syncing settings/telemetry:", sErr);
        }

        return NextResponse.json({ 
            success: true, 
            settings: currentSettings?.settings || DEFAULT_SETTINGS 
        });
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
