import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";
import { sendWelcomeEmail } from "@/lib/email";

// IDs y emails de referencia
const GOLD_DEMO_BOT_ID = "cmn9hf8yc0000vhbcq9hbxk0j";
const DEVELOPER_EMAILS = ["viajaconsakura@gmail.com", "viajaconsakura"];

export async function POST(req: Request) {
    try {
        const formData = await req.formData();
        const botId = formData.get("botId") as string;
        const email = formData.get("email") as string;
        const paypalOrderId = formData.get("paypalOrderId") as string;

        if (!botId || !email || !paypalOrderId) {
            return NextResponse.json({ error: "Datos incompletos" }, { status: 400 });
        }

        // Validación básica del email para evitar inyecciones
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return NextResponse.json({ error: "Email inválido" }, { status: 400 });
        }

        const bot = await prisma.botProduct.findUnique({ where: { id: botId } });
        if (!bot) return NextResponse.json({ error: "Bot not found" }, { status: 404 });

        // Solo permitir checkout del bot activo (Gold Demo). El resto están en prelanzamiento.
        if (bot.status !== "ACTIVE") {
            // Bot en prelanzamiento: redirigir amigablemente a la página de detalle
        return NextResponse.json({
            error: "no_disponible",
            message: bot.status === 'MAINTENANCE'
                ? `${bot.name} está actualmente en mantenimiento. Vuelve pronto.`
                : `${bot.name} aún no está disponible. Está en fase de lanzamiento.`,
            redirectUrl: `/bots/${bot.id}`,
        }, { status: 200 });
        }

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
        const isDeveloper = DEVELOPER_EMAILS.includes(email.toLowerCase());

        // 3. Calcular estado y expiración
        let purchaseStatus = "COMPLETED";
        let expiresAt: Date | null = null;

        if (isDemo) {
            purchaseStatus = "TRIAL";
            if (!isDeveloper) {
                // 30 días exactos de acceso
                expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
            }
            // Si es desarrollador: expiresAt queda null = acceso ilimitado de prueba
        }

        // 4. Registrar compra
        const purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                amount: bot.price,
                status: purchaseStatus,
                expiresAt: expiresAt,
                productKey: bot.productKey // Snapshot
            }
        });

        // 5. Generar la Clave Única (usamos el ID de compra como base)
        const cleanId = purchase.id.split("-")[0].toUpperCase();
        const licenseKey = `${bot.productKey || 'BOT'}-${cleanId}`;

        // 6. Enviar Correo de Bienvenida
        await sendWelcomeEmail(email, licenseKey, bot.name, purchase.id);

        // 7. Devolver éxito
        return NextResponse.json({
            success: true,
            message: "Compra exitosa",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: isNewUser ? "123456" : undefined
            }
        });

    } catch (error) {
        console.error("Error en checkout/paypal:", error);
        return NextResponse.json({ error: "Error procesando el pago y activación" }, { status: 500 });
    }
}
