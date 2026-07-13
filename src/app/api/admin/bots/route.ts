import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { sendVersionUpdateEmail } from "@/lib/email";

// GET: Obtener todos los bots en la base de datos
export async function GET(req: Request) {
    const session = await getServerSession(authOptions);
    
    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        const bots = await prisma.botProduct.findMany({
            orderBy: { createdAt: "desc" }
        });
        return NextResponse.json({ success: true, bots });
    } catch (e: any) {
        console.error("GET Bots API Error:", e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}

// POST: Publicar nuevo bot
export async function POST(req: Request) {
    const session = await getServerSession(authOptions);
    
    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        const formData = await req.formData();
        const name = formData.get("name") as string;
        const price = parseFloat(formData.get("price") as string);
        const instrument = formData.get("instrument") as string;
        const strategyType = formData.get("strategyType") as string;
        const description = formData.get("description") as string;
        const riskLevel = formData.get("riskLevel") as string;
        const timeframes = formData.get("timeframes") as string;
        const minCapital = parseFloat(formData.get("minCapital") as string) || 0;

        const bot = await prisma.botProduct.create({
            data: {
                name,
                price,
                instrument,
                strategyType,
                description,
                riskLevel,
                timeframes,
                minCapital,
                isActive: true,
                status: "UPCOMING"
            }
        });

        return NextResponse.json({ success: true, bot });
    } catch (e: any) {
        console.error("Publish Bot API Error:", e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}

// PUT: Actualizar versión del bot y notificar por email a los usuarios con licencia
export async function PUT(req: Request) {
    const session = await getServerSession(authOptions);
    
    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        const body = await req.json();
        const { botProductId, version, sendEmails, changelog, isUrgent, ex5FilePath, pdfFilePath } = body;

        if (!botProductId || !version) {
            return NextResponse.json({ success: false, error: "Faltan parámetros requeridos (botProductId, version)" }, { status: 400 });
        }

        // 1. Actualizar versión del producto de bot en base de datos
        const bot = await prisma.botProduct.update({
            where: { id: botProductId },
            data: {
                version,
                ex5FilePath: ex5FilePath || undefined,
                pdfFilePath: pdfFilePath || undefined
            }
        });

        let emailsSent = 0;
        const errors: any[] = [];

        // 2. Si se activa la notificación por email, buscamos licenciatarios activos
        if (sendEmails) {
            // Buscamos todas las compras finalizadas de este bot
            const purchases = await prisma.purchase.findMany({
                where: {
                    botProductId,
                    status: "COMPLETED"
                },
                include: {
                    user: true
                }
            });

            // Agrupar por email para no duplicar correos (si tienen múltiples licencias de la misma EA)
            const uniqueUsers = new Map<string, { email: string; purchaseId: string }>();
            purchases.forEach(p => {
                if (p.user && p.user.email) {
                    const emailKey = p.user.email.trim().toLowerCase();
                    if (!uniqueUsers.has(emailKey)) {
                        uniqueUsers.set(emailKey, {
                            email: p.user.email,
                            purchaseId: p.id
                        });
                    }
                }
            });

            // Enviar correos secuencialmente
            for (const [_, userInfo] of uniqueUsers.entries()) {
                try {
                    await sendVersionUpdateEmail(userInfo.email, bot.name, version, userInfo.purchaseId, changelog, isUrgent);
                    emailsSent++;
                } catch (emailErr: any) {
                    console.error(`Error enviando correo de actualización a ${userInfo.email}:`, emailErr);
                    errors.push({ email: userInfo.email, error: emailErr.message || "Unknown error" });
                }
            }
        }

        return NextResponse.json({
            success: true,
            bot,
            emailsSent,
            errors: errors.length > 0 ? errors : undefined
        });

    } catch (e: any) {
        console.error("Update Bot Version API Error:", e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}
