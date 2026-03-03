import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";

export async function POST(req: Request) {
    try {
        const formData = await req.formData();
        const botId = formData.get("botId") as string;
        const email = formData.get("email") as string;

        if (!botId || !email) {
            return NextResponse.json({ error: "Faltan datos requeridos" }, { status: 400 });
        }

        const bot = await prisma.botProduct.findUnique({ where: { id: botId } });
        if (!bot) return NextResponse.json({ error: "Bot no encontrado" }, { status: 404 });

        // Buscar o crear usuario
        let user = await prisma.user.findUnique({ where: { email } });

        let password = "123456"; // Default password for local mock

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
                return NextResponse.json({ error: "Ya tienes una prueba gratuita activa de este bot." }, { status: 400 });
            } else if (existingPurchase.status === 'COMPLETED') {
                return NextResponse.json({ error: "Ya posees la licencia completa de este bot." }, { status: 400 });
            }
        }

        // Registrar compra tipo TRIAL (vence en 30 días, o ETERNO para cuentas de test)
        const isEternalUser = ["user@example.com", "viajaconsakura"].some(e => email.toLowerCase().includes(e.toLowerCase()));
        const expiresAt = new Date();

        if (isEternalUser) {
            expiresAt.setFullYear(expiresAt.getFullYear() + 100); // 100 años para pruebas eternas de devs
        } else {
            expiresAt.setDate(expiresAt.getDate() + 30);
        }

        await prisma.purchase.create({
            data: {
                userId: user.id,
                botProductId: bot.id,
                amount: 0,
                status: "TRIAL",
                expiresAt: expiresAt
            }
        });

        // Devolver credenciales en JSON para que el frontend inicie sesión
        return NextResponse.json({
            success: true,
            message: "Prueba de 30 días activada con éxito",
            redirectUrl: "/dashboard",
            autoLogin: {
                email: user.email,
                password: password
            }
        });

    } catch (error) {
        console.error("DEBUG: Error activando prueba gratuita", error);
        return NextResponse.json({
            error: "Error procesando la activación",
            details: error instanceof Error ? error.message : String(error)
        }, { status: 500 });
    }
}
