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
import { CleanupButton } from "@/components/CleanupButton";

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
                border: 'border-amber-500/50 border-[2px] sm:border-l-[16px] border-l-[8px] shadow-[0_0_80px_-20px_rgba(245,158,11,0.3)]',
                accent: 'text-amber-400',
                glow: 'bg-amber-500/20',
                gradient: 'from-amber-600/40 via-amber-900/20 to-[#0a0a0f]',
                badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30'
            };
        if (n.includes("BTC") || n.includes("BITCOIN"))
            return {
                border: 'border-purple-500/50 border-[2px] sm:border-l-[16px] border-l-[8px] shadow-[0_0_80px_-20px_rgba(168,85,247,0.3)]',
                accent: 'text-purple-400',
                glow: 'bg-purple-500/20',
                gradient: 'from-purple-600/40 via-purple-900/20 to-[#0a0a0f]',
                badge: 'bg-purple-500/20 text-purple-300 border-purple-500/30'
            };
        if (n.includes("YEN") || n.includes("JPY"))
            return {
                border: 'border-cyan-500/50 border-[2px] sm:border-l-[16px] border-l-[8px] shadow-[0_0_80px_-20px_rgba(6,182,212,0.3)]',
                accent: 'text-cyan-400',
                glow: 'bg-cyan-500/20',
                gradient: 'from-cyan-600/40 via-cyan-900/20 to-[#0a0a0f]',
                badge: 'bg-cyan-500/20 text-cyan-300 border-cyan-500/30'
            };
        return {
            border: 'border-brand/50 border-[2px] sm:border-l-[16px] border-l-[8px] shadow-[0_0_80px_-20px_rgba(168,85,247,0.3)]',
            accent: 'text-brand-light',
            glow: 'bg-brand/20',
            gradient: 'from-brand/30 via-brand-dark/20 to-[#0a0a0f]',
            badge: 'bg-brand/20 text-brand-light border-brand/30'
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
                                     
                                     // Comparación de versiones más inteligente (solo muestra si la del producto es mayor que la descargada)
                                     const normalizeVer = (v: string) => parseFloat(v.replace(/[^0-9.]/g, '')) || 0;
                                     const hasUpdate = normalizeVer(purchase.botProduct.version) > normalizeVer(purchase.lastDownloadedVersion || "0.0");
                                     
                                     const theme = getBotTheme(purchase.botProduct.name);
                                 
                                 // Calcular beneficio diario de hoy
                                 const dailyProfit = (purchase.pastTrades || []).reduce((acc: number, t: any) => acc + (Number(t.profit) || 0), 0);
                                 
                                    return (
                                         <Card key={purchase.id} className={`relative overflow-hidden glass-card ${theme.border} group h-full flex flex-col transition-all duration-500 hover:scale-[1.03] bg-black/90 shadow-2xl rounded-2xl`}>
                                             {/* Full Background Gradient specifically for each bot */}
                                             <div className={`absolute inset-0 bg-gradient-to-b ${theme.gradient} pointer-events-none opacity-80`} />
                                             <div className={`absolute inset-0 border border-white/10 rounded-2xl pointer-events-none`} />
                                            
                                            {/* Spotlight effect - Large and colorful */}
                                            <div className={`absolute -top-40 -right-40 w-80 h-80 ${theme.glow} blur-[150px] rounded-full group-hover:opacity-100 transition-opacity opacity-60`} />
                                            
                                            <CardHeader className="relative z-10 pb-2 bg-white/5 border-b border-white/5">
                                                <div className="flex justify-between items-start mb-2">
                                                    <CardTitle className="text-2xl font-black text-white drop-shadow-[0_2px_4px_rgba(0,0,0,0.8)] tracking-tight">
                                                        {purchase.botProduct.name || "Sin nombre"}
                                                    </CardTitle>
                                                    <div className="flex flex-col items-end gap-1">
                                                        <span className="text-[10px] uppercase tracking-wider text-text-muted">
                                                            {isTrial ? "Trial activado el" : "Comprado"}: {purchase.createdAt ? new Date(purchase.createdAt).toLocaleDateString() : '---'}
                                                        </span>
                                                        {isTrial ? (
                                                            <span className={`text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-widest ${theme.badge}`}>
                                                                PRUEBA ACTIVA
                                                            </span>
                                                        ) : (
                                                            <span className="text-[10px] font-black px-3 py-1 rounded-full bg-success/20 text-success border border-success/30 uppercase tracking-widest">
                                                                LIFETIME
                                                            </span>
                                                        )}
                                                        
                                                        {/* Resultado Diario (PnL Hoy) - Flex wrap for mobile */}
                                                        <div className={`mt-2 px-2 sm:px-3 py-2 rounded-xl flex flex-wrap items-center justify-between gap-2 shadow-inner bg-black/60 border ${theme.border}`}>
                                                            <span className="text-[8px] sm:text-[9px] font-black uppercase tracking-widest opacity-60">RESULTADO HOY:</span>
                                                            <span className={`text-xs sm:text-sm font-black font-mono ${dailyProfit >= 0 ? 'text-success drop-shadow-[0_0_8px_rgba(34,197,94,0.4)]' : 'text-danger drop-shadow-[0_0_8px_rgba(239,68,68,0.4)]'}`}>
                                                                {dailyProfit >= 0 ? '+' : ''}{dailyProfit.toFixed(2)} $
                                                            </span>
                                                        </div>
                                                        {hasUpdate && !isExpired && (
                                                            <a href={`/api/download/${purchase.id}?type=ex5`} className="mt-1">
                                                                <span className={`text-[10px] font-black px-3 py-1.5 rounded-full ${theme.badge} animate-pulse cursor-pointer hover:opacity-80 transition-all block text-center shadow-lg border-2`}>
                                                                    🚀 ¡NUEVA VERSIÓN {purchase.botProduct.version} DISPONIBLE! (Clic para descargar)
                                                                </span>
                                                            </a>
                                                        )}
                                                    </div>
                                                </div>
                                                <div className="flex flex-wrap gap-2 mt-2">
                                                    <span className="px-2 py-0.5 rounded text-xs bg-surface-light border border-white/5">{purchase.botProduct.instrument || '---'}</span>
                                                    {isTrial && <span className="px-2 py-0.5 rounded text-[10px] border border-orange-500/30 text-orange-400 bg-orange-500/5">Solo Cuenta DEMO</span>}
                                                     <div className={`flex items-center gap-1.5 px-2 py-0.5 rounded text-[9px] bg-black/40 border ${theme.border} text-white`}>
                                                        <span className="opacity-60">ID VÍNCULO:</span>
                                                        <code className={`font-mono font-bold select-all tracking-tighter ${theme.accent}`}>{purchase.id}</code>
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
                                                                    theme={theme}
                                                                />
                                                            )}
                                                            
                                                                                                         <div className={`mt-6 p-4 rounded-xl bg-black/40 border-t-2 ${theme.border} shadow-2xl backdrop-blur-md`}>
                                                                <p className="text-[10px] text-text-muted/80 uppercase tracking-tighter mb-2 font-black">
                                                                    ID para Parámetro <span className={`${theme.accent} font-black`}>PurchaseID</span>
                                                                </p>
                                                                <div className="flex items-center gap-2">
                                                                    <code className={`bg-black/60 px-3 py-3 rounded-lg ${theme.accent} text-xs font-mono border border-white/10 flex-1 break-all uppercase font-black tracking-widest text-glow`}>
                                                                        {purchase.id}
                                                                    </code>
                                                                    <CopyIdButton id={purchase.id} />
                                                                </div>
                                                            </div>

                                                             <div className="flex items-center justify-between mt-4">
                                                                <SyncStatus initialLastSync={purchase.lastSync ? purchase.lastSync.toISOString() : null} />
                                                                <CleanupButton purchaseId={purchase.id} />
                                                            </div>
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
                                                                            <span className="text-[9px] text-text-muted/60 lowercase italic">cuenta:</span>
                                                                            <span className="text-[9px] font-mono font-bold text-white">{accountNo}</span>
                                                                            <span className={`text-[8px] font-black px-1.5 py-0.5 rounded ${positions[0]?.isReal ? 'bg-success/20 text-success border border-success/30' : 'bg-text-muted/10 text-text-muted/40 border border-white/5'}`}>
                                                                                {positions[0]?.isReal ? 'REAL' : 'DEMO'}
                                                                            </span>
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

                                                {/* Mini Historial de Operaciones de HOY */}
                                                {(purchase.pastTrades?.length || 0) > 0 && (
                                                    <div className="mt-6 pt-4 border-t border-white/5">
                                                        <div className="flex justify-between items-center mb-3">
                                                            <h4 className="text-[10px] font-bold uppercase tracking-widest text-text-muted/40 text-glow">Historial Cerrado (Hoy)</h4>
                                                            <span className="text-[10px] text-text-muted/20 font-mono">Últimas {purchase.pastTrades.length} ops.</span>
                                                        </div>
                                                        <div className="space-y-1 max-h-[250px] overflow-y-auto pr-1 scrollbar-thin">
                                                            {purchase.pastTrades.map((h: any) => (
                                                                <div key={h.id || Math.random()} className="flex items-center justify-between text-[11px] py-1.5 px-3 rounded bg-white/5 hover:bg-white/10 transition-all border border-transparent hover:border-white/5">
                                                                    <div className="flex items-center gap-3">
                                                                        <span className={`font-black font-mono w-4 ${h.type === 'BUY' ? 'text-success' : 'text-danger'}`}>
                                                                            {h.type === 'BUY' ? 'B' : 'S'}
                                                                        </span>
                                                                        <div>
                                                                            <div className="flex items-center gap-2">
                                                                                <span className="text-white font-bold">{(h.lots || 0).toFixed(2)}</span>
                                                                                <span className="text-text-muted/60">{h.symbol}</span>
                                                                            </div>
                                                                            <div className="flex items-center gap-2 text-[9px] opacity-40">
                                                                                <span className="font-mono text-white/50">#{h.account}</span>
                                                                                <span className="font-mono bg-white/5 px-1 rounded">t:{h.ticket}</span>
                                                                                <span className={`text-[7.5px] font-black px-1 rounded-sm ${h.isReal ? 'text-success/80 border border-success/30' : 'text-text-muted/50 border border-white/10'}`}>
                                                                                    {h.isReal ? 'R' : 'D'}
                                                                                </span>
                                                                                <span>•</span>
                                                                                <span>{(() => {
                                                                                    if (!h.closedAt) return '---';
                                                                                    const d = new Date(h.closedAt);
                                                                                    const now = new Date();
                                                                                    const isToday = d.toDateString() === now.toDateString();
                                                                                    const isYesterday = new Date(now.setDate(now.getDate() - 1)).toDateString() === d.toDateString();
                                                                                    
                                                                                    const time = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                                                                                    if (isToday) return `Hoy, ${time}`;
                                                                                    if (isYesterday) return `Ayer, ${time}`;
                                                                                    return `${d.toLocaleDateString([], { day: '2-digit', month: '2-digit' })}, ${time}`;
                                                                                })()}</span>
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                    <div className={`font-black font-mono ${(h.profit || 0) >= 0 ? 'text-success' : 'text-danger'} drop-shadow-md`}>
                                                                        {(h.profit || 0) >= 0 ? '+' : ''}{(h.profit || 0).toFixed(2)} $
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
