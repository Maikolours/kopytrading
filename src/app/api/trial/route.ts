import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";
import { sendWelcomeEmail } from "@/lib/email";

export async function POST(req: Request) {
    try {
        let botId = "";
        let email = "";

        const contentType = req.headers.get("content-type") || "";
        if (contentType.includes("application/json")) {
            const body = await req.json();
            botId = body.botId || "";
            email = body.email || "";
        } else {
            const formData = await req.formData();
            botId = (formData.get("botId") as string) || "";
            email = (formData.get("email") as string) || "";
        }

        if (!email) {
            return NextResponse.json({ error: "El correo electrónico es obligatorio" }, { status: 400 });
        }

        // Buscar el bot por ID, productKey o el primer bot activo
        let bot = null;
        if (botId) {
            bot = await prisma.botProduct.findFirst({
                where: { OR: [{ id: botId }, { productKey: botId }] }
            });
        }
        if (!bot) {
            bot = await prisma.botProduct.findFirst({ where: { isActive: true } });
        }

        if (!bot) {
            return NextResponse.json({ error: "No hay bots disponibles para prueba en este momento" }, { status: 404 });
        }

        // Buscar o crear usuario
        let user = await prisma.user.findUnique({ where: { email } });

        let password = "123456"; // Contraseña de acceso por defecto

        if (!user) {
            const hashedPassword = await bcrypt.hash(password, 10);
            user = await prisma.user.create({
                data: {
                    email,
                    name: email.split("@")[0],
                    password: hashedPassword,
                }
            });
        }

        // Verificar si el usuario ya tiene esta prueba o una compra completa
        const existingPurchase = await prisma.purchase.findFirst({
            where: {
                userId: user.id,
                botProductId: bot.id
            }
        });

        if (existingPurchase) {
            if (existingPurchase.status === 'TRIAL') {
                return NextResponse.json({ 
                    success: true, 
                    message: "Ya posees una prueba activa. Te hemos habilitado el acceso VIP.",
                    redirectUrl: "/dashboard" 
                });
            } else if (existingPurchase.status === 'COMPLETED') {
                return NextResponse.json({ 
                    success: true, 
                    message: "Ya posees la licencia completa de este bot.",
                    redirectUrl: "/dashboard" 
                });
            }
        }

        // Registrar compra tipo TRIAL (vence en 30 días, o ETERNO para cuentas de test)
        const isEternalUser = ["user@example.com", "viajaconsakura"].some(e => email.toLowerCase().includes(e.toLowerCase()));
        const expiresAt = new Date();

        if (isEternalUser) {
            expiresAt.setFullYear(expiresAt.getFullYear() + 100);
        } else {
            expiresAt.setDate(expiresAt.getDate() + 30);
        }

        const purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                productKey: bot.productKey || "BAYESIAN-PRO",
                amount: 0,
                status: "TRIAL",
                expiresAt: expiresAt
            }
        });

        const licenseKey = `KP-${Math.random().toString(36).substring(2, 9).toUpperCase()}-${user.id.substring(0, 4).toUpperCase()}`;

        // Enviar correo de bienvenida con credenciales e instalador
        try {
            await sendWelcomeEmail(user.email, licenseKey, bot.name, purchase.id);
        } catch (emailErr) {
            console.error("Error enviando email de bienvenida de prueba:", emailErr);
        }

        return NextResponse.json({
            success: true,
            message: "Prueba gratuita activada con éxito. Revisa tu correo electrónico.",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: password
            }
        });

    } catch (error) {
        console.error("DEBUG: Error activando prueba gratuita", error);
        return NextResponse.json({
            error: "Error procesando la activación de la prueba",
            details: error instanceof Error ? error.message : String(error)
        }, { status: 500 });
    }
}
