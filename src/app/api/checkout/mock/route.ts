import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";

// IDs y emails de referencia
const GOLD_DEMO_BOT_ID = "cmn9hf8yc0000vhbcq9hbxk0j";
const DEVELOPER_EMAILS = ["viajaconsakura@gmail.com", "viajaconsakura"];

export async function POST(req: Request) {
    try {
        const formData = await req.formData();
        const botId = formData.get("botId") as string;
        const email = formData.get("email") as string;

        // Validación básica del email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!botId || !email || !emailRegex.test(email)) {
            return NextResponse.json({ error: "Datos incompletos o inválidos" }, { status: 400 });
        }

        const bot = await prisma.botProduct.findUnique({ where: { id: botId } });
        if (!bot) return NextResponse.json({ error: "Bot not found" }, { status: 404 });

        // Solo permitir checkout del bot activo. El resto están en prelanzamiento.
        if (bot.status !== "ACTIVE") {
            // Bot en prelanzamiento: redirigir amigablemente
        return NextResponse.json({
            error: "no_disponible",
            message: bot.status === 'MAINTENANCE'
                ? `${bot.name} está actualmente en mantenimiento. Vuelve pronto.`
                : `${bot.name} aún no está disponible. Está en fase de lanzamiento.`,
            redirectUrl: `/bots/${bot.id}`,
        }, { status: 200 });
        }

        // Buscar o crear usuario
        let user = await prisma.user.findUnique({ where: { email } });
        if (!user) {
            const hashedPassword = await bcrypt.hash("123456", 10);
            user = await prisma.user.create({
                data: {
                    email,
                    name: email.split("@")[0],
                    password: hashedPassword,
                }
            });
        }

        // Determinar si es una compra de Demo
        const isDemo = botId === GOLD_DEMO_BOT_ID || bot.name.toUpperCase().includes("DEMO");
        const isDeveloper = DEVELOPER_EMAILS.includes(email.toLowerCase());

        // Calcular estado y expiración
        let purchaseStatus = "COMPLETED";
        let expiresAt: Date | null = null;

        if (isDemo) {
            purchaseStatus = "TRIAL";
            if (!isDeveloper) {
                expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
            }
        }

        // Registrar compra
        await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                amount: bot.price,
                status: purchaseStatus,
                expiresAt: expiresAt,
            }
        });

        return NextResponse.json({
            success: true,
            message: "Compra exitosa",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: "123456"
            }
        });

    } catch (error) {
        console.error("Error en checkout", error);
        return NextResponse.json({ error: "Error procesando el pago" }, { status: 500 });
    }
}
