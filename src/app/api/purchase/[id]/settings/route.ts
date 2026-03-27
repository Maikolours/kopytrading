import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function GET(
    req: Request, 
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params;
        const session = await getServerSession(authOptions);
        if (!session?.user) return new NextResponse("No autorizado", { status: 401 });

        const { searchParams } = new URL(req.url);
        const account = searchParams.get("account") || "unknown";

        // @ts-ignore - Handle possible generation delay
        const settings = await prisma.botSettings.findUnique({
            where: { purchaseId_account: { purchaseId: id, account } }
        });

        return NextResponse.json(settings ? settings.settings : {});
    } catch (error) {
        console.error("GET Settings Error:", error);
        return new NextResponse("Error interno", { status: 500 });
    }
}

export async function PATCH(
    req: Request, 
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params;
        const session = await getServerSession(authOptions);
        if (!session?.user) return new NextResponse("No autorizado", { status: 401 });

        const body = await req.json();
        const { account, settings } = body;

        if (!account) return new NextResponse("Falta cuenta", { status: 400 });

        // @ts-ignore - Handle possible generation delay
        const updated = await prisma.botSettings.upsert({
            where: { purchaseId_account: { purchaseId: id, account: String(account) } },
            update: { settings },
            create: { purchaseId: id, account: String(account), settings }
        });

        return NextResponse.json(updated);
    } catch (error) {
        console.error("PATCH Settings Error:", error);
        return new NextResponse("Error interno", { status: 500 });
    }
}
