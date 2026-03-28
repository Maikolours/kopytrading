import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
    try {
        // Ocultar todos los bots del Marketplace público
        await prisma.botProduct.updateMany({
            data: { isActive: false }
        });

        return NextResponse.json({ success: true, message: "Todos los bots se han ocultado al público. Solo el dueño puede verlos ahora." });
    } catch (error: any) {
        console.error("Deactivate API Error:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
