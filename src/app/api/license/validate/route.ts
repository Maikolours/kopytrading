import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

/**
 * Endpoint de validación de licencias para los nuevos bots DeepSeek.
 * Maneja validación de producto, expiración y prevención de multi-cuenta.
 */
export async function POST(req: Request) {
    try {
        const body = await req.json();
        const { purchaseId, licenseKey, account } = body;

        // 1. MODO DEMO: Si no hay purchaseId o se usa la key de trial genérica
        if (!purchaseId || purchaseId === "TRIAL-2026") {
            return NextResponse.json({ 
                valid: true, 
                type: 'DEMO_30', 
                message: 'Modo Demo activo (30 días de prueba local)' 
            });
        }

        // 2. NORMALIZACIÓN: Limpiar el purchaseId (CUID)
        const cleanId = purchaseId.trim().toLowerCase().split("-")[0];
        
        // 3. BÚSQUEDA DE LICENCIA: Incluimos el producto y la sesión activa
        const purchase = await prisma.purchase.findUnique({
            where: { id: cleanId },
            include: { 
                botProduct: true,
                licenseSessions: {
                    where: { isActive: true }
                }
            }
        });

        if (!purchase) {
            return NextResponse.json({ 
                valid: false, 
                message: 'Licencia no válida o no encontrada en el servidor' 
            }, { status: 401 });
        }

        // 4. VERIFICACIÓN DE PRODUCTO: Asegurar que el bot corresponde a la compra
        // El bot envía 'XAU-MG', 'BTC-SR', etc. en licenseKey
        if (licenseKey && purchase.botProduct.productKey !== licenseKey && purchase.productKey !== licenseKey) {
             return NextResponse.json({ 
                valid: false, 
                message: `Licencia de ${purchase.botProduct.name} no válida para ${licenseKey}` 
            }, { status: 403 });
        }

        // 5. VERIFICACIÓN DE EXPIRACIÓN
        if (purchase.expiresAt && new Date() > new Date(purchase.expiresAt)) {
            return NextResponse.json({ 
                valid: false, 
                message: 'Tu suscripción ha expirado. Por favor, renueva en kopytrading.com' 
            }, { status: 401 });
        }

        // 6. CONTROL MULTI-CUENTA (CONFLICTO): Solo una cuenta activa por licencia
        const accountStr = account ? String(account).trim() : "unknown";
        const activeSession = purchase.licenseSessions[0];

        if (activeSession && activeSession.account !== accountStr) {
             // Comprobamos si el último latido fue hace más de 1 hora para permitir "reset" automático
             const oneHourAgo = new Date();
             oneHourAgo.setHours(oneHourAgo.getHours() - 1);
             
             if (activeSession.lastActivity > oneHourAgo) {
                 return NextResponse.json({ 
                    valid: false, 
                    message: `Esta licencia ya está activa en la cuenta MT5: ${activeSession.account}`,
                    conflict: true,
                    boundAccount: activeSession.account
                }, { status: 409 });
             }
        }

        // 7. ACTUALIZAR/CREAR SESIÓN DE LICENCIA
        await prisma.licenseSession.upsert({
            where: { purchaseId: cleanId },
            update: { 
                account: accountStr, 
                lastActivity: new Date(), 
                isActive: true 
            },
            create: { 
                purchaseId: cleanId, 
                account: accountStr, 
                lastActivity: new Date(), 
                isActive: true 
            }
        });

        // 8. ÉXITO
        return NextResponse.json({ 
            valid: true, 
            type: 'FULL', 
            message: 'Licencia validada correctamente. ¡Buen trading!', 
            boundAccount: accountStr 
        });

    } catch (error) {
        console.error("License Validation Error:", error);
        return NextResponse.json({ 
            valid: false, 
            message: 'Error interno en el servidor de licencias' 
        }, { status: 500 });
    }
}
