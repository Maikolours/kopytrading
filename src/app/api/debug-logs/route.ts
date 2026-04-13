import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export async function GET() {
    try {
        const logs = await prisma.requestLog.findMany({
            orderBy: { createdAt: 'desc' },
            take: 20
        });

        const purchases = await prisma.purchase.findMany({
            take: 10,
            select: { id: true, userId: true, botProductId: true, updatedAt: true }
        });

        return NextResponse.json({ 
            success: true, 
            serverTime: new Date().toISOString(),
            logs,
            activePurchases: purchases
        });
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
