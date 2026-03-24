import { prisma } from "@/lib/prisma";
import { revalidatePath } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
    try {
        const { purchaseId } = await req.json();

        if (!purchaseId) {
            return NextResponse.json({ error: "Missing purchaseId" }, { status: 400 });
        }

        // Borrar todas las posiciones en vivo y el historial de esta compra
        await prisma.$transaction([
            prisma.livePosition.deleteMany({ where: { purchaseId } }),
            prisma.tradeHistory.deleteMany({ where: { purchaseId } })
        ]);

        // Opcional: Podríamos marcar el lastSync como null para indicar que está "limpio"
        await prisma.purchase.update({
            where: { id: purchaseId },
            data: { lastSync: null }
        });

        // Asegurar que la cache de Next.js se invalide
        revalidatePath("/dashboard");

        return NextResponse.json({ success: true });
    } catch (err: any) {
        console.error("Cleanup Error:", err);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
