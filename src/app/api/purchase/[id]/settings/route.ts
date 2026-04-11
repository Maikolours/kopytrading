import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET(
    req: Request, 
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params;
        const session = await getServerSession(authOptions);
        if (!session?.user) return new NextResponse("No autorizado", { status: 401 });

        const { searchParams } = new URL(req.url);
        const account = searchParams.get("account") || "unknown";
        const symbol = searchParams.get("symbol")?.toUpperCase();
        const timeframe = searchParams.get("timeframe")?.toUpperCase();

        // @ts-ignore - Handle possible generation delay
        let record = await prisma.botSettings.findUnique({
            where: { purchaseId_account: { purchaseId: id, account } }
        });

        // 🛡️ SAKURA MASTER FETCH: Si eres tú, buscamos tu balance más fresco en todo el sistema.
        const isSakura = session.user.email?.includes("viajaconsakura") || id.includes("viajaconsakura");
        if (isSakura) {
            const freshestRecord = await prisma.botSettings.findFirst({
                where: { 
                    purchase: { user: { email: { contains: "viajaconsakura" } } },
                    account: account !== "unknown" ? account : undefined
                },
                orderBy: { updatedAt: 'desc' }
            });
            if (freshestRecord) record = freshestRecord;
        }

        // FALLBACK: Si pide "unknown" pero hay datos de una cuenta real, servimos esos
        if (!record && account === "unknown") {
            record = await prisma.botSettings.findFirst({
                where: { purchaseId: id },
                orderBy: { updatedAt: 'desc' }
            });
        }

        if (!record) return NextResponse.json({});

        const settings = record.settings as any;
        
        // LÓGICA DE MEMORIA TÁCTICA v12.0 (GET)
        if (symbol && timeframe) {
            const memoryKey = `${symbol}_${timeframe}`;
            const memories = settings.memories || {};
            // Si hay memoria específica la devolvemos, si no, devolvemos los globales
            if (memories[memoryKey]) {
                return NextResponse.json({
                    ...settings,
                    ...memories[memoryKey],
                    isMemory: true,
                    memoryKey
                });
            }
        }

        return NextResponse.json(settings);
    } catch (error) {
        console.error("GET Settings Error:", error);
        return new NextResponse("Error interno", { status: 500 });
    }
}

export async function PATCH(
    req: Request, 
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params;
        const session = await getServerSession(authOptions);
        if (!session?.user) return new NextResponse("No autorizado", { status: 401 });

        const body = await req.json();
        const { account, settings: newSettings, symbol, timeframe } = body;

        if (!account) return new NextResponse("Falta cuenta", { status: 400 });

        // @ts-ignore - Handle possible generation delay
        const existingRecord = await prisma.botSettings.findUnique({
            where: { purchaseId_account: { purchaseId: id, account: String(account) } }
        });

        let finalSettings = newSettings;

        // LÓGICA DE MEMORIA TÁCTICA v12.0 (PATCH)
        if (existingRecord && symbol && timeframe) {
            const currentSettings = existingRecord.settings as any;
            const memoryKey = `${symbol.toUpperCase()}_${timeframe.toUpperCase()}`;
            const memories = currentSettings.memories || {};
            
            // Solo guardamos en la memoria específica los campos tácticos
            const newMemories = {
                ...memories,
                [memoryKey]: {
                    ...newSettings, // Guardamos el estado actual como memoria de este gráfico
                }
            };
            
            finalSettings = {
                ...currentSettings,
                ...newSettings, // También actualizamos el estado "global/último"
                memories: newMemories
            };
        }

        const updated = await prisma.botSettings.upsert({
            where: { purchaseId_account: { purchaseId: id, account: String(account) } },
            update: { settings: finalSettings },
            create: { purchaseId: id, account: String(account), settings: finalSettings }
        });

        return NextResponse.json(updated);
    } catch (error) {
        console.error("PATCH Settings Error:", error);
        return new NextResponse("Error interno", { status: 500 });
    }
}
