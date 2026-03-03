import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

/**
 * API para que los bots (.ex5) verifiquen si tienen permiso para operar.
 * El bot enviará su ID y el AccountNumber() de MetaTrader.
 */
export async function GET(req: Request) {
    try {
        const { searchParams } = new URL(req.url);
        const botId = searchParams.get("botId");
        const accountNumber = searchParams.get("accountNumber");
        const email = searchParams.get("email");
        const isDemo = searchParams.get("isDemo"); // Nuevo: el bot debe decir si es demo

        if (!botId || !accountNumber || !email) {
            return NextResponse.json({ authorized: false, message: "Missing params" }, { status: 400 });
        }

        // 1. Buscar el usuario por email
        const user = await prisma.user.findUnique({
            where: { email },
            include: {
                purchases: {
                    where: {
                        botProductId: botId,
                        status: { in: ["COMPLETED", "TRIAL"] }
                    }
                }
            }
        });

        if (!user) {
            return NextResponse.json({ authorized: false, message: "Usuario no registrado" });
        }

        // 2. Verificar si tiene una compra/trial activa
        const purchase = user.purchases[0];
        if (!purchase) {
            return NextResponse.json({ authorized: false, message: "No tienes una licencia activa para este bot" });
        }

        // 3. Verificar si el trial ha expirado
        if (purchase.status === "TRIAL" && purchase.expiresAt) {
            if (new Date() > purchase.expiresAt) {
                return NextResponse.json({ authorized: false, message: "Tu prueba gratuita de 30 días ha expirado" });
            }

            // 4. NUEVO: Restringir TRIAL solo a cuentas DEMO
            if (isDemo !== "true") {
                return NextResponse.json({
                    authorized: false,
                    message: "Las licencias de PRUEBA solo funcionan en cuentas DEMO. Adquiere una licencia FULL para operar en REAL."
                });
            }
        }

        // 5. Lógica de "Piratería": Vincular el AccountNumber
        // Podríamos guardar purchase.accountNumber en la DB si quisiéramos fijarlo.

        return NextResponse.json({
            authorized: true,
            status: purchase.status,
            expiresAt: purchase.expiresAt,
            message: purchase.status === "TRIAL" ? "Licencia de PRUEBA activa (Solo DEMO)" : "Licencia VITALICIA activa"
        });

    } catch (error) {
        console.error("Error in license check:", error);
        return NextResponse.json({ authorized: false, error: "Server error" }, { status: 500 });
    }
}
