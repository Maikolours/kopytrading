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
        const purchaseId = (body.purchaseId || body.license || "").trim().toLowerCase().split("-")[0];
        const account = (body.account || body.acc || "").toString().trim();
        const { positions, history, isReal, balance, equity, status } = body;

        if (!purchaseId || !account) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: text.substring(0, 1000), error: "Missing purchaseId or account" }
            });
            return NextResponse.json({ error: "Missing purchaseId or account" }, { status: 400 });
        }

        // 3. Verificar que la compra existe y cargar su producto (Búsqueda Robusta)
        let purchase = await prisma.purchase.findUnique({
            where: { id: purchaseId },
            include: { botProduct: true }
        });

        // FALLBACK: Si no lo encuentra por CUID, buscar por email del usuario (Usabilidad Supreme)
        if (!purchase && purchaseId.includes("@")) {
            const userPurchase = await prisma.purchase.findFirst({
                where: { 
                    user: { email: purchaseId },
                    botProduct: { productKey: body.licenseKey || undefined } 
                },
                include: { botProduct: true },
                orderBy: { createdAt: 'desc' }
            });
            if (userPurchase) purchase = userPurchase;
        }

        if (!purchase) {
            // v13.0 MASTER BYPASS: Sakura Industrial Pass (Refined to support multiple products)
            const isSakuraMaster = purchaseId === "viajaconsakura" || purchaseId.includes("viajaconsakura") || purchaseId === "elite_sniper_master" || purchaseId.startsWith("cmn9h");
            if (isSakuraMaster) {
                const targetKey = body.productKey || body.licenseKey || "SNIPER-ELITE";
                purchase = await prisma.purchase.findFirst({
                    where: { 
                        userId: { in: ["viajaconsakura", "cmmb2z6ml000dvhhoj1s9zmnf"] },
                        botProduct: {
                            OR: [
                                { productKey: targetKey },
                                { name: { contains: targetKey } }
                            ]
                        }
                    },
                    include: { botProduct: true }
                });
            }
        }

        if (!purchase) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: "License not found: " + purchaseId }
            });
            return NextResponse.json({ error: "INVALID_LICENSE", msg: "Licencia no encontrada" }, { status: 200 });
        }

        const officialPurchaseId = purchase.id;

        // VERIFICACIÓN DE PRODUCTO (Opcional): Si el bot envía licenseKey (XAU-MG, etc)
        if (body.licenseKey && purchase.botProduct.productKey && purchase.botProduct.productKey !== body.licenseKey) {
            await prisma.requestLog.create({
                data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: `ProductKey mismatch: Bot ${body.licenseKey} vs License ${purchase.botProduct.productKey}` }
            });
            return NextResponse.json({ error: "License product mismatch" }, { status: 403 });
        }

        // VALIDACIÓN DE CRUCE
        const botSymbol = (positions && positions.length > 0 ? positions[0].symbol : (body.symbol || purchase.botProduct.instrument || "XAUUSD")).toUpperCase();
        const expectedInstrument = (purchase.botProduct.instrument || "").toUpperCase();
        const isOwner = purchase.userId === "cmmb2z6ml000dvhhoj1s9zmnf" || purchase.userId === "viajaconsakura";

        if (!isOwner && expectedInstrument && !botSymbol.includes(expectedInstrument) && !expectedInstrument.includes(botSymbol)) {
            const isXAU = (botSymbol.includes("XAU") || botSymbol.includes("GOLD")) && (expectedInstrument.includes("XAU") || expectedInstrument.includes("GOLD"));
            if (!isXAU) {
                await prisma.requestLog.create({
                    data: { path: "/api/sync-positions", method: "POST", body: JSON.stringify(body), error: `Crossover detected: Bot ${botSymbol} syncing to ${expectedInstrument} license.` }
                });
                return NextResponse.json({ error: "License type mismatch (Crossover detected)" }, { status: 403 });
            }
        }

        // Actualizar latido de conexión y telemetría (Sincro Supreme v1.5)
        await prisma.purchase.update({
            where: { id: officialPurchaseId },
            data: { 
                lastSync: new Date(),
                balance: balance ? Number(balance) : undefined,
                equity: equity ? Number(equity) : undefined,
                lastStatus: status || undefined
            }
        });

        // Sincronizar posiciones abiertas
        await prisma.$transaction([
            prisma.livePosition.deleteMany({ 
                where: { purchaseId: officialPurchaseId, account } 
            }),
            ...(positions || []).map((pos: any) => 
                prisma.livePosition.create({
                    data: {
                        purchaseId: officialPurchaseId,
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

        // Historial
        if (history && history.length > 0) {
            for (const h of history) {
                const exists = await prisma.tradeHistory.findFirst({
                    where: { purchaseId: officialPurchaseId, account, ticket: String(h.ticket) }
                });
                if (!exists) {
                    await prisma.tradeHistory.create({
                        data: {
                            purchaseId: officialPurchaseId,
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

        // Sincro de Configuración y Memoria
        const DEFAULT_SETTINGS = {
            net_cycle: 5.0,
            hedge_trigger: 3.0,
            lote_manual: 0.01,
            lote_rescate: 0.01,
            max_dd: 20.0,
            trailling_stop: 1.2,
            limit_dist: 500,
            timeframe: "M15",
            lkb: 4,
            colchon: 1000,
            b1_be: 0.8, b1_gar: 0.5, b1_tra: 1.2,
            b2_be: 0.8, b2_gar: 0.5, b2_tra: 1.0,
            gr_be: 1.0, gr_gar: 0.8, gr_tra: 1.5,
            casOn: false,
            autoRA: true,
            giroOn: false
        };

        const telemetry = {
            balance: Number(body.balance) || 0,
            equity: Number(body.equity) || 0,
            pnl_today: Number(body.pnl_today) || 0,
            lkb: Number(body.lkb) || 4,
            trend: body.trend || "UNKNOWN",
            armed: body.armed === true || body.armed === "true",
            p00: body.p00 !== undefined ? Number(body.p00) : 0,
            p50: body.p50 !== undefined ? Number(body.p50) : 0,
            p62: body.p62 !== undefined ? Number(body.p62) : 0,
            p78: body.p78 !== undefined ? Number(body.p78) : 0,
            p100: body.p100 !== undefined ? Number(body.p100) : 0,
            b1_be: Number(body.b1_be), b1_gar: Number(body.b1_gar), b1_tra: Number(body.b1_tra),
            b2_be: Number(body.b2_be), b2_gar: Number(body.b2_gar), b2_tra: Number(body.b2_tra),
            gr_be: Number(body.gr_be), gr_gar: Number(body.gr_gar), gr_tra: Number(body.gr_tra),
            isOnline: true,
            lastUpdate: new Date().toISOString()
        };

        let currentSettings = null;
        try {
            const existingRecord = await prisma.botSettings.findUnique({
                where: { purchaseId_account: { purchaseId: officialPurchaseId, account: String(account) } }
            });
            const rawSettings = existingRecord ? (existingRecord.settings as any) : DEFAULT_SETTINGS;
            const symbol = (body.symbol || "UNKNOWN").toUpperCase();
            const timeframe = (body.tf || body.timeframe || "M5").toUpperCase();
            const memoryKey = `${symbol}_${timeframe}`;
            const memories = rawSettings.memories || {};
            const specificMemory = memories[memoryKey] || {};

            const updatedSettings = {
                ...rawSettings,
                ...(body.proposedSettings || {}),
                ...telemetry,
                balance: telemetry.balance,
                equity: telemetry.equity,
                pnl_today: telemetry.pnl_today,
                lots: Number(body.lots) || rawSettings.lots || 0.08,
                casOn: (body.cascada !== undefined || body.casOn !== undefined) ? (body.cascada === true || body.cascada === "true" || body.casOn === true || body.casOn === "true") : rawSettings.casOn,
                giroOn: (body.giro !== undefined || body.giroOn !== undefined) ? (body.giro === true || body.giro === "true" || body.giroOn === true || body.giroOn === "true") : rawSettings.giroOn,
                fearOn: (body.fear !== undefined || body.fearOn !== undefined) ? (body.fear === true || body.fear === "true" || body.fearOn === true || body.fearOn === "true") : rawSettings.fearOn,
            };

            const newMemories = {
                ...memories,
                [memoryKey]: {
                    ...specificMemory,
                    lkb: Number(body.lkb) || specificMemory.lkb || rawSettings.lkb,
                    casOn: updatedSettings.casOn,
                    giroOn: updatedSettings.giroOn,
                    b1_be: telemetry.b1_be || specificMemory.b1_be || rawSettings.b1_be,
                    b1_gar: telemetry.b1_gar || specificMemory.b1_gar || rawSettings.b1_gar,
                    b1_tra: telemetry.b1_tra || specificMemory.b1_tra || rawSettings.b1_tra,
                    b2_be: telemetry.b2_be || specificMemory.b2_be || rawSettings.b2_be,
                    b2_gar: telemetry.b2_gar || specificMemory.b2_gar || rawSettings.b2_gar,
                    b2_tra: telemetry.b2_tra || specificMemory.b2_tra || rawSettings.b2_tra,
                    gr_be: telemetry.gr_be || specificMemory.gr_be || rawSettings.gr_be,
                    gr_gar: telemetry.gr_gar || specificMemory.gr_gar || rawSettings.gr_gar,
                    gr_tra: telemetry.gr_tra || specificMemory.gr_tra || rawSettings.gr_tra,
                }
            };
            updatedSettings.memories = newMemories;

            if (purchaseId === "viajaconsakura" || purchaseId.includes("viajaconsakura")) {
                const allSakuraPurchases = await prisma.purchase.findMany({
                    where: { userId: { in: ["viajaconsakura", "cmmb2z6ml000dvhhoj1s9zmnf"] } }
                });
                for (const pur of allSakuraPurchases) {
                    await prisma.botSettings.upsert({
                        where: { purchaseId_account: { purchaseId: pur.id, account: String(account) } },
                        update: { settings: updatedSettings },
                        create: { purchaseId: pur.id, account: String(account), settings: updatedSettings }
                    });
                }
            } else {
                currentSettings = await prisma.botSettings.upsert({
                    where: { purchaseId_account: { purchaseId: officialPurchaseId, account: String(account) } },
                    update: { settings: updatedSettings },
                    create: { purchaseId: officialPurchaseId, account: String(account), settings: updatedSettings }
                });
            }

            if (updatedSettings.pendingCmd && updatedSettings.pendingCmd !== "NONE") {
                await prisma.botSettings.update({
                    where: { id: currentSettings.id },
                    data: { settings: { ...updatedSettings, pendingCmd: "NONE" } }
                });
            }
        } catch (sErr) {
            console.error("Error syncing settings/telemetry:", sErr);
        }

        return NextResponse.json({ 
            success: true, 
            settings: currentSettings?.settings || DEFAULT_SETTINGS,
            cmd: (currentSettings?.settings as any)?.pendingCmd || "NONE"
        });
    } catch (err: any) {
        console.error("Sync Positions Error:", err);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
