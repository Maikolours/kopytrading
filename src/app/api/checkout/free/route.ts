import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";
import { sendWelcomeEmail } from "@/lib/email";

const GOLD_DEMO_BOT_ID = "cmn9hf8yc0000vhbcq9hbxk0j";
const DEVELOPER_EMAILS = ["viajaconsakura@gmail.com", "viajaconsakura"];
const VALID_PROMO_CODES = ["MAIKOFREE", "ACADEMIA100", "ACADEMIAPRO", "GOLD100", "SIMULACION", "VIPDEMO", "PRUEBA", "TEST"];

export async function POST(req: Request) {
    try {
        let botId = "";
        let email = "";
        let promoCode = "";

        const contentType = req.headers.get("content-type") || "";
        if (contentType.includes("application/json")) {
            const body = await req.json();
            botId = body.botId || GOLD_DEMO_BOT_ID;
            email = (body.email || "").trim().toLowerCase();
            promoCode = (body.promoCode || "").trim().toUpperCase();
        } else {
            const formData = await req.formData();
            botId = (formData.get("botId") as string) || GOLD_DEMO_BOT_ID;
            email = (formData.get("email") as string || "").trim().toLowerCase();
            promoCode = (formData.get("promoCode") as string || "").trim().toUpperCase();
        }

        if (!email) {
            return NextResponse.json({ error: "Datos incompletos: email requerido" }, { status: 400 });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return NextResponse.json({ error: "Email inválido" }, { status: 400 });
        }

        const isDev = DEVELOPER_EMAILS.includes(email);
        const isValidPromo = VALID_PROMO_CODES.includes(promoCode);

        if (!isDev && !isValidPromo) {
            return NextResponse.json({ error: "Código de cupón inválido o expirado" }, { status: 403 });
        }

        const bot = await prisma.botProduct.findUnique({ where: { id: botId } });
        if (!bot) return NextResponse.json({ error: "Bot no encontrado" }, { status: 404 });

        // 1. Buscar o crear usuario
        let user = await prisma.user.findUnique({ where: { email } });
        let isNewUser = false;

        if (!user) {
            isNewUser = true;
            const hashedPassword = await bcrypt.hash("123456", 10);
            user = await prisma.user.create({
                data: {
                    email,
                    name: email.split("@")[0],
                    password: hashedPassword,
                }
            });
        }

        // 2. Determinar si es una compra de Demo
        const isDemo = botId === GOLD_DEMO_BOT_ID || bot.name.toUpperCase().includes("DEMO");

        // 3. Registrar compra gratuita con estado TRIAL (30 días)
        const purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                amount: 0.00,
                status: "TRIAL",
                expiresAt: isDev ? null : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
                productKey: bot.productKey || "XAU-MG"
            }
        });

        // 4. Generar la Clave Única de Activación
        const cleanId = purchase.id.split("-")[0].toUpperCase();
        const licenseKey = `${bot.productKey || 'BOT'}-${cleanId}`;

        // 5. Enviar Correo de Bienvenida Real mediante Resend
        try {
            await sendWelcomeEmail(email, licenseKey, bot.name, purchase.id);
        } catch (emailErr) {
            console.error("Aviso: Error enviando email con Resend:", emailErr);
        }

        return NextResponse.json({
            success: true,
            message: "Demo activada con éxito",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: isNewUser ? "123456" : undefined
            }
        });

    } catch (error) {
        console.error("Error en checkout/free:", error);
        return NextResponse.json({ error: "Error procesando la activación gratuita" }, { status: 500 });
    }
}
