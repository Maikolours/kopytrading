import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";
import { sendWelcomeEmail } from "@/lib/email";

export async function POST(req: Request) {
    try {
        const formData = await req.formData();
        const botId = formData.get("botId") as string;
        const email = formData.get("email") as string;
        const paypalOrderId = formData.get("paypalOrderId") as string;

        if (!botId || !email || !paypalOrderId) {
            return NextResponse.json({ error: "Datos incompletos" }, { status: 400 });
        }

        const bot = await prisma.botProduct.findUnique({ where: { id: botId } });
        if (!bot) return NextResponse.json({ error: "Bot not found" }, { status: 404 });

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

        // 2. Registrar compra
        const purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                amount: bot.price,
                status: "COMPLETED",
                productKey: bot.productKey // Snapshot
            }
        });

        // 3. Generar la Clave Única (Usaremos el ID de compra para simplificar, o un sufijo)
        const cleanId = purchase.id.split("-")[0].toUpperCase();
        const licenseKey = `${bot.productKey || 'BOT'}-${cleanId}`;

        // 4. Enviar Correo de Bienvenida
        await sendWelcomeEmail(email, licenseKey, bot.name, purchase.id);

        // 5. Devolver éxito
        return NextResponse.json({
            success: true,
            message: "Compra exitosa",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: isNewUser ? "123456" : undefined // Solo enviamos password si es nuevo para autologin
            }
        });

    } catch (error) {
        console.error("Error en checkout/paypal:", error);
        return NextResponse.json({ error: "Error procesando el pago y activación" }, { status: 500 });
    }
}
