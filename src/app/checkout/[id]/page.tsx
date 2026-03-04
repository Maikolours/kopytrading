import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import CheckoutClientForm from "./CheckoutClientForm";

export default async function CheckoutPage({
    params,
    searchParams
}: {
    params: Promise<{ id: string }>,
    searchParams: Promise<{ trial?: string }>
}) {
    const { id } = await params;
    const { trial } = await searchParams;
    const isTrial = trial === 'true';

    const bot = await prisma.botProduct.findUnique({
        where: { id: id }
    });

    if (!bot) notFound();

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 flex items-center justify-center">
            <div className="max-w-md w-full glass-card p-8 border border-white/10 relative overflow-hidden">
                <div className="absolute -top-20 -right-20 w-40 h-40 bg-brand/30 blur-[50px] rounded-full pointer-events-none"></div>

                <h1 className="text-2xl font-bold text-white mb-2">
                    {isTrial ? "Activar Prueba Gratis" : "Finalizar Compra"}
                </h1>
                <p className="text-text-muted text-sm mb-8">
                    {isTrial ? "Estás a un paso de probar gratis tu bot." : "Estás a un paso de descargar tu bot."}
                </p>

                <div className="bg-surface/50 rounded-xl p-4 mb-8 border border-white/5">
                    <div className="flex justify-between items-center mb-2">
                        <span className="font-medium text-white">{bot.name}</span>
                        <span className={`font-bold text-lg ${isTrial ? "text-success" : "text-white"}`}>
                            {isTrial ? "GRATIS" : `$${Number(bot.price).toFixed(2)}`}
                        </span>
                    </div>
                    <p className={`text-xs ${isTrial ? "text-success" : "text-brand-light"}`}>
                        {isTrial ? "Licencia temporal 30 días" : "Licencia de por vida (.ex5 + Manual)"}
                    </p>
                </div>

                <CheckoutClientForm
                    bot={{
                        id: bot.id,
                        name: bot.name,
                        price: Number(bot.price),
                    }}
                    isTrial={isTrial}
                />
            </div>
        </div>
    );
}
