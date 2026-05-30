import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
    const session = await getServerSession(authOptions);
    
    // Bloqueo de seguridad en el servidor
    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        const formData = await req.formData();
        const name = formData.get("name") as string;
        const price = parseFloat(formData.get("price") as string);
        const instrument = formData.get("instrument") as string;
        const strategyType = formData.get("strategyType") as string;
        const description = formData.get("description") as string;
        const riskLevel = formData.get("riskLevel") as string;
        const timeframes = formData.get("timeframes") as string;
        const minCapital = parseFloat(formData.get("minCapital") as string) || 0;

        // Crear bot en la base de datos
        const bot = await prisma.botProduct.create({
            data: {
                name,
                price,
                instrument,
                strategyType,
                description,
                riskLevel,
                timeframes,
                minCapital,
                isActive: true,
                status: "UPCOMING"
            }
        });

        return NextResponse.json({ success: true, bot });
    } catch (e: any) {
        console.error("Publish Bot API Error:", e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}
