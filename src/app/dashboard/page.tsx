import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import Link from "next/link";
import { Card, CardHeader, CardContent, CardTitle, CardFooter } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Countdown } from "@/components/ui/Countdown";
import { PasswordChangeForm } from "@/components/PasswordChangeForm";
import { BotRemoteControl } from "@/components/BotRemoteControl";
import { CopyIdButton } from "@/components/CopyIdButton";
import { SyncStatus } from "@/components/SyncStatus";

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
        const rawPurchases = await prisma.purchase.findMany({
            where: { userId: currentUserId },
            include: { 
                botProduct: true,
                activePositions: {
                    orderBy: { updatedAt: 'desc' }
                },
                pastTrades: {
                    orderBy: { closedAt: 'desc' },
                    take: 5
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        // Agrupar por botProductId
        const purchaseMap = new Map<string, any>();
        rawPurchases.forEach(p => {
            const botId = p.botProductId;
            const existing = purchaseMap.get(botId);
            // Si no existe, o si el nuevo es LIFETIME y el viejo es TRIAL, lo cambiamos
            if (!existing || (existing.status === "TRIAL" && p.status === "LIFETIME")) {
                purchaseMap.set(botId, p);
            }
        });
        purchases = Array.from(purchaseMap.values());
    } catch (e: any) {
        console.error("Prisma Error Dashboard:", e);
        error = e.message || "Error al conectar con la base de datos";
    }

    // Helper para colores de bot
    const getBotTheme = (name: string = "") => {
        const n = name.toUpperCase();
        if (n.includes("ORO") || n.includes("XAUUSD") || n.includes("AMETRA"))
            return {
                border: 'border-t-amber-500/80 border-l-amber-500/20 shadow-[0_0_15px_rgba(245,158,11,0.15)]',
                accent: 'text-amber-400',
                glow: 'bg-amber-500/5',
                bg: 'from-amber-500/5 via-transparent to-transparent'
            };
        if (n.includes("BTC") || n.includes("BITCOIN"))
            return {
                border: 'border-t-purple-500 border-l-4 border-l-purple-500 shadow-[0_0_20px_rgba(168,85,247,0.2)]',
                accent: 'text-purple-400',
                glow: 'bg-purple-500/10',
                bg: 'from-purple-500/5 via-transparent to-transparent',
                gradient: 'from-purple-500/20 via-black to-black'
            };
        if (n.includes("YEN") || n.includes("JPY"))
            return {
                border: 'border-t-cyan-500 border-l-4 border-l-cyan-500 shadow-[0_0_20px_rgba(6,182,212,0.2)]',
                accent: 'text-cyan-400',
                glow: 'bg-cyan-500/10',
                bg: 'from-cyan-500/5 via-transparent to-transparent',
                gradient: 'from-cyan-500/10 via-black to-black'
            };
        return {
            border: 'border-t-brand/80 border-l-brand/20 shadow-[0_0_15px_rgba(0,186,215,0.15)]',
            accent: 'text-brand-light',
            glow: 'bg-brand/5',
            bg: 'from-brand/5 via-transparent to-transparent',
            gradient: 'from-brand/10 via-black to-black'
        };
    };

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8">
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
                    <div className="space-y-8">
                        <div className="grid md:grid-cols-2 gap-6">
                            {purchases.map((purchase: any) => {
                                    if (!purchase || !purchase.botProduct) return null;
                                    
                                    const isTrial = purchase.status === "TRIAL";
                                    // Lógica de acceso eterno para cuentas de test (Usuario y Desarrollador)
                                    const userEmail = session?.user?.email || "";
                                    const isEternalUser = ["user@example.com", "viajaconsakura"].some(email => userEmail.toLowerCase().includes(email.toLowerCase()));
                                    const isExpired = isTrial && purchase.expiresAt && new Date() > new Date(purchase.expiresAt) && !isEternalUser;
                                    const hasUpdate = purchase.botProduct.version !== purchase.lastDownloadedVersion;
                                    const theme = getBotTheme(purchase.botProduct.name);

                                    return (
                                        <Card key={purchase.id} className={`relative overflow-hidden glass-card border border-white/5 ${theme.border} group h-full flex flex-col transition-all duration-300 hover:scale-[1.01] bg-black/60`}>
                                            <div className={`absolute inset-0 bg-gradient-to-tr ${theme.gradient} pointer-events-none opacity-40`} />
                                            <div className={`absolute -top-24 -right-24 w-48 h-48 ${theme.glow} blur-[120px] rounded-full group-hover:opacity-100 transition-opacity opacity-30`} />
                                            
                                            <CardHeader className="relative z-10 pb-2">
                                                <div className="flex justify-between items-start mb-2">
                                                    <CardTitle>{purchase.botProduct.name || "Sin nombre"}</CardTitle>
                                                    <div className="flex flex-col items-end gap-1">
                                                        <span className="text-[10px] uppercase tracking-wider text-text-muted">
                                                            {isTrial ? "Trial activado el" : "Comprado"}: {purchase.createdAt ? new Date(purchase.createdAt).toLocaleDateString() : '---'}
                                                        </span>
                                                        {isTrial && (
                                                            <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${isExpired ? 'bg-danger/20 text-danger' : 'bg-brand/20 text-brand-light animate-pulse'}`}>
                                                                {isExpired ? "PRUEBA EXPIRADA" : "PRUEBA ACTIVA"}
                                                            </span>
                                                        )}
                                                        {!isTrial || isEternalUser ? (
                                                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-success/20 text-success">
                                                                {isEternalUser ? "LICENCIA DEV (ETERNA)" : "LIFETIME"}
                                                            </span>
                                                        ) : null}
                                                        {hasUpdate && !isExpired && (
                                                            <a href={`/api/download/${purchase.id}?type=ex5`} className="mt-1">
                                                                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-brand-bright/20 text-brand-light border border-brand-light/20 animate-pulse cursor-pointer hover:bg-brand-bright/30 transition-colors block text-center">
                                                                    🚀 ¡NUEVA VERSIÓN {purchase.botProduct.version} DISPONIBLE! (Clic para descargar)
                                                                </span>
                                                            </a>
                                                        )}
                                                    </div>
                                                </div>
                                                <div className="flex flex-wrap gap-2 mt-2">
                                                    <span className="px-2 py-0.5 rounded text-xs bg-surface-light border border-white/5">{purchase.botProduct.instrument || '---'}</span>
                                                    {isTrial && <span className="px-2 py-0.5 rounded text-[10px] border border-orange-500/30 text-orange-400 bg-orange-500/5">Solo Cuenta DEMO</span>}
                                                    <div className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[9px] bg-brand/5 border border-brand/10 text-brand-light">
                                                        <span className="opacity-60">ID VÍNCULO:</span>
                                                        <code className="font-mono font-bold select-all tracking-tighter">{purchase.id}</code>
                                                    </div>
                                                </div>
                                            </CardHeader>
                                             <CardContent className="relative z-10 flex-grow flex flex-col pb-4 text-sm text-text-muted">
                                                {isTrial ? (
                                                    <div className="space-y-3">
                                                        <div className="flex flex-col gap-1">
                                                            <p className="text-[10px] uppercase tracking-wider text-text-muted/60">Tiempo de gracia restante:</p>
                                                            <div className="flex items-center gap-2">
                                                                {purchase.expiresAt && <Countdown targetDate={purchase.expiresAt.toISOString()} />}
                                                            </div>
                                                        </div>
                                                        {isExpired ? (
                                                            <div className="p-2 rounded bg-danger/10 border border-danger/20">
                                                                <p className="text-[10px] text-danger font-medium italic leading-tight">
                                                                    La licencia ha caducado. El bot dejará de operar. Adquiere una completa para seguir.
                                                                </p>
                                                            </div>
                                                        ) : (
                                                            <p className="text-[10px] text-text-muted/60 italic leading-tight">
                                                                Válido únicamente para cuentas MetaTrader 5 (MT5) de tipo DEMO (Simulación).
                                                            </p>
                                                        )}
                                                    </div>
                                                ) : (
                                                    <div className="flex items-center gap-2 text-success">
                                                        <div className="w-2 h-2 rounded-full bg-success animate-pulse" />
                                                        <p>Licencia: <span className="font-semibold text-white">Activa de por vida</span></p>
                                                    </div>
                                                )}
                                                                                     {(() => {
                                                    const syncTime = purchase.lastSync ? new Date(purchase.lastSync) : null;
                                                    // Determinar estado actual básico para el RemoteControl inicial
                                                    const isOnline = syncTime ? (new Date().getTime() - syncTime.getTime()) < 150000 : false;
                                                    
                                                    return (
                                                        <>
                                                            {!isExpired && (
                                                                <BotRemoteControl 
                                                                    purchaseId={purchase.id} 
                                                                    botName={purchase.botProduct?.name || "Bot"} 
                                                                    isOnline={isOnline}
                                                                />
                                                            )}
                                                            
                                                            <div className="mt-6 p-4 rounded-xl bg-surface-light/40 border-t-2 border-brand/20 shadow-inner">
                                                                <p className="text-[10px] text-text-muted/60 uppercase tracking-tighter mb-2 font-bold">
                                                                    ID para Parámetro <span className="text-secondary font-black">PurchaseID</span>
                                                                </p>
                                                                <div className="flex items-center gap-2">
                                                                    <code className="bg-black/40 px-3 py-2.5 rounded-lg text-secondary text-xs font-mono border border-white/5 flex-1 break-all uppercase font-bold tracking-widest text-glow">
                                                                        {purchase.id}
                                                                    </code>
                                                                    <CopyIdButton id={purchase.id} />
                                                                </div>
                                                            </div>

                                                            <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                                                        </>
                                                    );
                                                })()}

                                                {/* Sección de Operaciones Abiertas (Real-Time Grouped by Account) */}
                                                {(purchase.activePositions?.length || 0) > 0 && (() => {
                                                    // Agrupar por cuenta
                                                    const accounts: Record<string, any[]> = {};
                                                    purchase.activePositions.forEach((pos: any) => {
                                                        const acc = pos.account || "Principal";
                                                        if (!accounts[acc]) accounts[acc] = [];
                                                        accounts[acc].push(pos);
                                                    });

                                                    return (
                                                        <div className="mt-6 pt-4 border-t border-white/5">
                                                            <h4 className={`text-[10px] font-bold uppercase tracking-widest ${theme.accent} mb-4 flex items-center gap-2`}>
                                                                Operaciones Abiertas
                                                            </h4>
                                                            
                                                            <div className="space-y-6">
                                                                {Object.entries(accounts).map(([accountNo, positions]) => (
                                                                    <div key={accountNo} className="space-y-2">
                                                                        <div className="flex items-center gap-2 px-2 py-0.5 rounded bg-white/5 w-fit border border-white/5">
                                                                            <span className="text-[9px] text-text-muted/60">CUENTA:</span>
                                                                            <span className="text-[9px] font-mono font-bold text-white">{accountNo}</span>
                                                                        </div>
                                                                        <div className="space-y-2 pl-2 border-l border-white/5">
                                                                            {positions.map((pos: any) => {
                                                                                if (!pos) return null;
                                                                                return (
                                                                                    <div key={pos.id || Math.random()} className="bg-surface-light/30 rounded-lg p-3 border border-white/5 flex items-center justify-between transition-all hover:bg-surface-light/50">
                                                                                        <div className="flex items-center gap-3">
                                                                                            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-[10px] font-bold ${pos.type === 'BUY' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>
                                                                                                {pos.type === 'BUY' ? 'B' : 'S'}
                                                                                            </div>
                                                                                            <div>
                                                                                                <div className="flex items-center gap-2">
                                                                                                    <span className="text-white font-medium text-xs font-mono">{(pos.lots || 0).toFixed(2)} {pos.symbol || '---'}</span>
                                                                                                    <span className="text-[9px] text-text-muted/60 opacity-50">#{pos.ticket || '---'}</span>
                                                                                                </div>
                                                                                                <div className="text-[10px] text-text-muted/60">
                                                                                                    @ {(pos.openPrice || 0).toFixed(2)}
                                                                                                </div>
                                                                                            </div>
                                                                                        </div>
                                                                                        <div className={`text-sm font-bold font-mono ${(pos.profit || 0) >= 0 ? 'text-success' : 'text-danger'}`}>
                                                                                            {(pos.profit || 0) >= 0 ? '+' : ''}{(pos.profit || 0).toFixed(2)} $
                                                                                        </div>
                                                                                    </div>
                                                                                );
                                                                            })}
                                                                        </div>
                                                                    </div>
                                                                ))}
                                                            </div>
                                                        </div>
                                                    );
                                                })()}

                                                {/* Mini Historial Reciente */}
                                                {(purchase.pastTrades?.length || 0) > 0 && (
                                                    <div className="mt-6 pt-4 border-t border-white/5">
                                                        <h4 className="text-[10px] font-bold uppercase tracking-widest text-text-muted/40 mb-3">Historial Reciente (Global)</h4>
                                                        <div className="space-y-1">
                                                            {purchase.pastTrades.map((h: any) => (
                                                                <div key={h.id || Math.random()} className="flex items-center justify-between text-[11px] py-1 px-2 rounded hover:bg-white/5 transition-colors">
                                                                    <div className="flex items-center gap-2">
                                                                        <span className={(h.profit || 0) >= 0 ? 'text-success/70' : 'text-danger/70'}>
                                                                            {h.type === 'BUY' ? 'BUY' : 'SELL'}
                                                                        </span>
                                                                        <span className="text-text-muted/60">{(h.lots || 0).toFixed(2)} lotes</span>
                                                                        <span className="text-[8px] opacity-30 font-mono ml-1">{h.account || "---"}</span>
                                                                    </div>
                                                                    <div className="flex items-center gap-3">
                                                                        <span className="text-text-muted/40 italic text-[9px]">
                                                                            {h.closedAt && !isNaN(new Date(h.closedAt).getTime()) ? new Date(h.closedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '---'}
                                                                        </span>
                                                                        <span className={`font-mono font-bold ${(h.profit || 0) >= 0 ? 'text-success/80' : 'text-danger/80'}`}>
                                                                            {(h.profit || 0) >= 0 ? '+' : ''}{(h.profit || 0).toFixed(2)}$
                                                                        </span>
                                                                    </div>
                                                                </div>
                                                            ))}
                                                        </div>
                                                     </div>
                                                 )}

                                                {/* Botón de Emergencia SIEMPRE AL FINAL */}
                                                <div className="mt-auto pt-4 border-t border-white/5 italic text-[10px] text-text-muted/40 text-center">
                                                    Control centralizado de cuenta MT5.
                                                </div>
                                             </CardContent>
                                        <CardFooter className="pt-4 border-t border-white/5 flex flex-wrap gap-3">
                                            <a href={`/api/download/${purchase.id}?type=ex5`} className="flex-1 min-w-[120px]">
                                                <Button size="sm" fullWidth className="text-sm bg-surface-light hover:bg-surface-light/80 text-white shadow-none">
                                                    Descargar .EX5
                                                </Button>
                                            </a>
                                            {/* Oculto temporalmente */}
                                            {/* 
                                            <a href={`/api/download/${purchase.id}?type=pdf`} className="flex-1 min-w-[120px]">
                                                <Button variant="outline" size="sm" fullWidth className="text-sm">
                                                    Manual PDF
                                                </Button>
                                            </a>
                                            */}
                                            {isTrial && (
                                                <a href={`/checkout/${purchase.botProductId}`} className="w-full mt-2">
                                                    <Button size="sm" fullWidth className="bg-gradient-to-r from-brand to-brand-bright hover:shadow-brand/20 shadow-lg text-xs py-2">
                                                        Comprar Licencia Completa →
                                                    </Button>
                                                </a>
                                            )}
                                        </CardFooter>
                                    </Card>
                                );
                            })}
                        </div>

                        {/* Ayuda de Cuenta */}
                        <div className="bg-surface-light/20 border border-white/5 rounded-2xl p-6">
                            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                                🔐 Gestión de Cuenta
                            </h3>
                            <div className="grid sm:grid-cols-2 gap-4">
                                <div className="space-y-3">
                                    <p className="text-sm text-text-muted">
                                        Si acabas de activar una prueba o compra, tu contraseña temporal es <span className="text-white font-mono bg-white/10 px-2 py-0.5 rounded">123456</span>.
                                    </p>
                                    <p className="text-[11px] text-text-muted/60">
                                        Esta es la contraseña para entrar en esta página web.
                                    </p>
                                    <div className="p-3 bg-brand/5 border border-brand/10 rounded-xl">
                                        <p className="text-[11px] text-brand-light italic">
                                            <b>Nota:</b> Los bots en MetaTrader 5 (MT5) funcionan mediante validación de licencia automática (Email + Nº de Cuenta), no necesitan esta contraseña.
                                        </p>
                                    </div>
                                </div>
                                <div className="space-y-4">
                                    <h4 className="text-xs font-bold uppercase tracking-widest text-text-muted/40">Personalizar Acceso</h4>
                                    <PasswordChangeForm />
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
