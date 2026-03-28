import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
    try {
        console.log("--- Iniciando Fix de DB (Purchase Table) ---");
        
        // 1. Intentar añadir la columna productKey a la tabla Purchase
        // Usamos rawQuery para saltar las restricciones de Prisma cuando el esquema no coincide
        try {
            await prisma.$executeRawUnsafe(`ALTER TABLE Purchase ADD COLUMN productKey VARCHAR(191) DEFAULT 'LEGACY'`);
            console.log("✅ Columna productKey añadida a Purchase.");
        } catch (e: any) {
            console.log("⚠️ Nota: La columna Purchase.productKey podría ya existir o hubo un error: " + e.message);
        }

        // 2. Intentar añadir la columna productKey a BotProduct por si acaso
        try {
            await prisma.$executeRawUnsafe(`ALTER TABLE BotProduct ADD COLUMN productKey VARCHAR(191) UNIQUE`);
            console.log("✅ Columna productKey añadida a BotProduct.");
        } catch (e: any) {
            console.log("⚠️ Nota: La columna BotProduct.productKey podría ya existir.");
        }

        return NextResponse.json({ 
            success: true, 
            message: "Migración manual ejecutada. Por favor, recarga el panel de trading." 
        });
    } catch (error: any) {
        console.error("Fix DB Error:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
