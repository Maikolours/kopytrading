import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
    const session = await getServerSession(authOptions);
    
    // Bloqueo estricto de seguridad en el servidor
    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        // 1. Total de usuarios y registros recientes
        const totalUsers = await prisma.user.count();
        const recentUsers = await prisma.user.findMany({
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                createdAt: true
            },
            orderBy: { createdAt: "desc" },
            take: 30
        });

        // 2. Compras totales e ingresos acumulados
        const purchases = await prisma.purchase.findMany({
            include: {
                user: true,
                botProduct: true
            },
            orderBy: { createdAt: "desc" }
        });

        const totalRevenue = purchases
            .filter(p => p.status === "COMPLETED")
            .reduce((sum, p) => sum + p.amount, 0);

        const sales = purchases.map(p => ({
            id: p.id,
            userEmail: p.user?.email || "unknown",
            userName: p.user?.name || "unknown",
            botName: p.botProduct?.name || "unknown",
            amount: p.amount,
            status: p.status,
            createdAt: p.createdAt
        }));

        // 3. Sincronizaciones activas (Licencias y terminales MT5 en ejecución en vivo)
        const licenseSessions = await prisma.licenseSession.findMany({
            include: {
                purchase: {
                    include: {
                        user: true,
                        botProduct: true
                    }
                }
            },
            orderBy: { lastActivity: "desc" }
        });

        const activeSessions = licenseSessions.map(session => ({
            id: session.id,
            account: session.account,
            lastActivity: session.purchase?.lastSync || session.lastActivity,
            isActive: session.isActive,
            userEmail: session.purchase?.user?.email || "unknown",
            userName: session.purchase?.user?.name || "unknown",
            botName: session.purchase?.botProduct?.name || "unknown",
            balance: session.purchase?.balance || 0,
            equity: session.purchase?.equity || 0,
            status: session.purchase?.lastStatus || "unknown"
        }));

        // 4. Historial de descargas realizadas por usuarios
        const downloadsRaw = await prisma.purchase.findMany({
            where: {
                lastDownloadedVersion: { not: null }
            },
            include: {
                user: true,
                botProduct: true
            },
            orderBy: { updatedAt: "desc" },
            take: 30
        });

        const downloads = downloadsRaw.map(d => ({
            id: d.id,
            userEmail: d.user?.email || "unknown",
            userName: d.user?.name || "unknown",
            botName: d.botProduct?.name || "unknown",
            downloadedVersion: d.lastDownloadedVersion,
            downloadedAt: d.updatedAt
        }));

        return NextResponse.json({
            success: true,
            timestamp: new Date().toISOString(),
            metrics: {
                totalUsers,
                totalRevenue,
                activeSessionsCount: activeSessions.filter(s => s.isActive).length
            },
            recentUsers,
            sales,
            activeSessions,
            downloads
        });

    } catch (error: any) {
        console.error("Admin Metrics API Error:", error);
        return NextResponse.json({
            success: false,
            error: error.message || "Internal Server Error"
        }, { status: 500 });
    }
}

export async function DELETE(req: Request) {
    const session = await getServerSession(authOptions);
    
    // Bloqueo estricto de seguridad en el servidor
    if (!session?.user || (session.user as any).role !== "ADMIN") {
        return new NextResponse("Forbidden", { status: 403 });
    }

    try {
        const { searchParams } = new URL(req.url);
        const type = searchParams.get("type"); // "user" | "purchase"
        const id = searchParams.get("id");

        if (!type || !id) {
            return NextResponse.json({ success: false, error: "Missing type or id" }, { status: 400 });
        }

        if (type === "user") {
            // Prevenir eliminar la propia cuenta del administrador principal
            const targetUser = await prisma.user.findUnique({ where: { id } });
            if (targetUser?.email === "viajaconsakura@gmail.com" || targetUser?.email === (session.user as any).email) {
                return NextResponse.json({ success: false, error: "No puedes eliminar tu propia cuenta de Administrador." }, { status: 400 });
            }

            // Buscar compras del usuario
            const userPurchases = await prisma.purchase.findMany({
                where: { userId: id },
                select: { id: true }
            });
            const purchaseIds = userPurchases.map(p => p.id);

            if (purchaseIds.length > 0) {
                // Eliminar relaciones secundarias de las compras
                await prisma.licenseSession.deleteMany({ where: { purchaseId: { in: purchaseIds } } });
                await prisma.livePosition.deleteMany({ where: { purchaseId: { in: purchaseIds } } });
                await prisma.tradeHistory.deleteMany({ where: { purchaseId: { in: purchaseIds } } });
                await prisma.remoteCommand.deleteMany({ where: { purchaseId: { in: purchaseIds } } });
                await prisma.botSettings.deleteMany({ where: { purchaseId: { in: purchaseIds } } });
                await prisma.purchase.deleteMany({ where: { userId: id } });
            }

            await prisma.review.deleteMany({ where: { userId: id } });
            await prisma.user.delete({ where: { id } });

            return NextResponse.json({ success: true, message: "Usuario eliminado correctamente." });
        }

        if (type === "purchase") {
            await prisma.licenseSession.deleteMany({ where: { purchaseId: id } });
            await prisma.livePosition.deleteMany({ where: { purchaseId: id } });
            await prisma.tradeHistory.deleteMany({ where: { purchaseId: id } });
            await prisma.remoteCommand.deleteMany({ where: { purchaseId: id } });
            await prisma.botSettings.deleteMany({ where: { purchaseId: id } });
            await prisma.purchase.delete({ where: { id } });

            return NextResponse.json({ success: true, message: "Registro de descarga/compra eliminado correctamente." });
        }

        return NextResponse.json({ success: false, error: "Tipo de eliminación no válido" }, { status: 400 });

    } catch (error: any) {
        console.error("Admin Delete API Error:", error);
        return NextResponse.json({
            success: false,
            error: error.message || "Error al eliminar registro"
        }, { status: 500 });
    }
}
