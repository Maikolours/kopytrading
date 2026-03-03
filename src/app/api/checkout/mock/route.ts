import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";

export async function POST(req: Request) {
    try {
        const formData = await req.formData();
        const botId = formData.get("botId") as string;
        const email = formData.get("email") as string;

        const bot = await prisma.botProduct.findUnique({ where: { id: botId } });
        if (!bot) return NextResponse.json({ error: "Bot not found" }, { status: 404 });

        // Buscar o crear usuario
        let user = await prisma.user.findUnique({ where: { email } });
        if (!user) {
            // Creamos una contraseña por defecto simplificada (solo para mock local)
            const hashedPassword = await bcrypt.hash("123456", 10);
            user = await prisma.user.create({
                data: {
                    email,
                    name: email.split("@")[0],
                    password: hashedPassword,
                }
            });
        }

        // Registrar compra
        const purchase = await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                amount: bot.price,
                status: "COMPLETED"
            }
        });

        // Devolver credenciales en JSON para que el frontend inicie sesión
        return NextResponse.json({
            success: true,
            message: "Compra exitosa",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: "123456" // Contraseña default del mock local
            }
        });

    } catch (error) {
        console.error("Error en checkout", error);
        return NextResponse.json({ error: "Error procesando el pago" }, { status: 500 });
    }
}
