import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
    try {
        console.log("--- ACTIVANDO RUTA DE EMERGENCIA SAKURA ---");
        
        // 1. Limpieza de telemetría vieja
        const deleted = await prisma.botSettings.deleteMany({
            where: { 
                purchase: { 
                    user: { email: { contains: "viajaconsakura" } } 
                } 
            }
        });

        // 2. Limpieza de registros de sesiones antiguas si las hubiera
        await prisma.licenseSession.deleteMany({
            where: { 
                purchase: { 
                    user: { email: { contains: "viajaconsakura" } } 
                } 
            }
        });

        return NextResponse.json({ 
            success: true, 
            message: `Limpieza completada. Se eliminaron ${deleted.count} registros. El Sniper v13 ya puede sincronizar.` 
        });
    } catch (error) {
        console.error("Error en Ruta de Emergencia:", error);
        return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
    }
}
