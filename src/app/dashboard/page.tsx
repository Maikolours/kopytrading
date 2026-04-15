import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { DashboardRefresher } from "@/components/DashboardRefresher";
import { DashboardContainer } from "@/components/DashboardContainer";
// Evitar cacheo
export const dynamic = "force-dynamic";

export default async function DashboardPage() {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
        redirect("/login");
    }

    // Obtener ID real del usuario de forma robusta
    let currentUserId = (session.user as any).id;
    if (!currentUserId && session.user.email) {
        const dbUser = await prisma.user.findUnique({
            where: { email: session.user.email },
            select: { id: true }
        });
        currentUserId = dbUser?.id;
    }

    if (!currentUserId) {
        redirect("/login");
    }

    // Obtener compras del usuario y deduplicar (priorizar LIFE sobre TRIAL)
    let purchases: any[] = [];
    let error: string | null = null;
    try {
        purchases = await prisma.purchase.findMany({
            where: { userId: currentUserId },
            include: { 
                botProduct: true,
                activePositions: {
                    orderBy: { updatedAt: 'desc' }
                },
                pastTrades: {
                    where: {
                        closedAt: {
                            gte: new Date(new Date().setHours(0, 0, 0, 0))
                        }
                    },
                    orderBy: { closedAt: 'desc' },
                    take: 10
                }
            },
            orderBy: { createdAt: 'desc' }
        });
    } catch (e) {
        error = "No se pudieron cargar tus bots.";
    }

    // Deeply serialize the data to ensure only POJOs are passed to the client (Dates to strings)
    const serializedPurchases = JSON.parse(JSON.stringify(purchases));

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8">
            <DashboardRefresher />
            <div className="max-w-5xl mx-auto">
                <div className="mb-10 pb-6 border-b border-white/10 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
                    <div>
                        <h1 className="text-3xl font-bold text-white mb-1">Mi Panel de Trading</h1>
                        <p className="text-text-muted">Hola, {session.user.name || session.user.email}</p>
                    </div>
                    {(session.user as any).role === "ADMIN" && (
                        <Button variant="outline" size="sm" className="border-brand-light text-brand-light">
                            Panel de Configuración Admin
                        </Button>
                    )}
                </div>

                {error && (
                    <div className="bg-danger/10 border border-danger/20 p-4 rounded-xl text-danger mb-8">
                        <p className="font-bold">Error de Sistema:</p>
                        <p className="text-sm opacity-80">{error}</p>
                        <p className="text-xs mt-2 italic opacity-60">Prueba a recargar en unos minutos.</p>
                    </div>
                )}

                <h2 className="text-xl font-semibold text-white mb-6">Mis Bots Comprados</h2>

                {purchases.length === 0 ? (
                    <div className="glass-card border border-dashed border-white/20 p-12 text-center rounded-2xl">
                        <div className="w-16 h-16 rounded-full bg-surface-light/50 flex items-center justify-center mx-auto mb-4 text-2xl">
                            🤖
                        </div>
                        <h3 className="text-lg font-medium text-white mb-2">Aún no tienes ningún bot</h3>
                        <p className="text-text-muted mb-6">Explora nuestro marketplace y potencia tu trading en MetaTrader 5 (MT5).</p>
                        <Link href="/bots">
                            <Button size="md">Ver Marketplace</Button>
                        </Link>
                    </div>
                ) : (
                    <DashboardContainer purchases={serializedPurchases} />
                )}
            </div>
        </div>
    );
}
