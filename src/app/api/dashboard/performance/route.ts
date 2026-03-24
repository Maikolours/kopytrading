import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET(request: Request) {
    const session = await getServerSession(authOptions);
    if (!session?.user) return NextResponse.json({ error: "No autorizado" }, { status: 401 });

    const { searchParams } = new URL(request.url);
    const purchaseId = searchParams.get("purchaseId");

    try {
        const userId = (session.user as any).id;
        
        // Si hay purchaseId, filtramos por él. Si no, traemos todo lo del usuario.
        const where: any = purchaseId 
            ? { purchaseId, purchase: { userId } }
            : { purchase: { userId } };

        const history = await prisma.tradeHistory.findMany({
            where,
            orderBy: { closedAt: 'asc' },
            select: {
                profit: true,
                closedAt: true,
                account: true,
                isReal: true,
                symbol: true
            }
        });

        // Agrupar por día
        const performanceByDay: Record<string, { profit: number, count: number, isReal: boolean }> = {};
        
        history.forEach(trade => {
            const day = trade.closedAt.toISOString().split('T')[0];
            if (!performanceByDay[day]) {
                performanceByDay[day] = { profit: 0, count: 0, isReal: trade.isReal };
            }
            performanceByDay[day].profit += trade.profit;
            performanceByDay[day].count += 1;
        });

        // Convertir a array para el frontend
        const dailyData = Object.entries(performanceByDay).map(([date, data]) => ({
            date,
            ...data
        }));

        return NextResponse.json({ dailyData });

    } catch (error: any) {
        console.error("Performance API Error:", error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
