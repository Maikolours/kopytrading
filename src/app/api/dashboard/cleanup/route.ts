import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
    try {
        const { purchaseId } = await req.json();

        if (!purchaseId) {
            return NextResponse.json({ error: "Missing purchaseId" }, { status: 400 });
        }

        // Borrar todas las posiciones en vivo de esta compra
        await prisma.livePosition.deleteMany({
            where: { purchaseId }
        });

        // Opcional: Podríamos marcar el lastSync como null para indicar que está "limpio"
        await prisma.purchase.update({
            where: { id: purchaseId },
            data: { lastSync: null }
        });

        return NextResponse.json({ success: true });
    } catch (err: any) {
        console.error("Cleanup Error:", err);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
