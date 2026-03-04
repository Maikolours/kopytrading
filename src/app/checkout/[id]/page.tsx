import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import dynamic from "next/dynamic";

// IMPORTANTE: Tipamos el componente dinámico para que TypeScript no se queje
const CheckoutClientForm = dynamic<any>(
    () => import("./CheckoutClientForm"),
    {
        ssr: false,
        loading: () => (
            <div className="flex flex-col items-center justify-center py-20">
                <div className="w-10 h-10 border-4 border-brand-light border-t-transparent rounded-full animate-spin"></div>
                <p className="mt-4 text-text-muted animate-pulse">Cargando pasarela segura...</p>
            </div>
        )
    }
);

interface PageProps {
    params: Promise<{ id: string }>;
}

export default async function CheckoutPage({ params }: PageProps) {
    // Next.js 15 requiere await para acceder a los params
    const { id } = await params;

    const bot = await prisma.botProduct.findUnique({
        where: { id },
    });

    if (!bot) {
        notFound();
    }

    // Objeto plano y limpio para el cliente
    const plainBot = {
        id: bot.id,
        name: bot.name,
        price: Number(bot.price),
        description: bot.description
    };

    return (
        <main className="min-h-screen pt-24 pb-12 px-4">
            <div className="max-w-4xl mx-auto">
                <div className="bg-surface-dark/50 backdrop-blur-xl border border-white/5 rounded-[2.5rem] overflow-hidden shadow-2xl">
                    <div className="grid md:grid-cols-2">
                        <div className="p-8 md:p-12 bg-gradient-to-br from-brand/10 to-transparent border-r border-white/5">
                            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-brand/10 border border-brand/20 mb-6">
                                <span className="w-2 h-2 rounded-full bg-brand animate-pulse"></span>
                                <span className="text-[10px] font-bold text-brand uppercase tracking-wider">Compra Segura</span>
                            </div>

                            <h1 className="text-3xl md:text-4xl font-black text-white mb-4">
                                {plainBot.name}
                            </h1>
                            <p className="text-text-muted leading-relaxed mb-8">
                                Estás a un paso de obtener tu licencia de {plainBot.name}. Acceso instantáneo tras el pago.
                            </p>

                            <div className="mt-12 pt-8 border-t border-white/10">
                                <p className="text-xs text-text-muted uppercase font-black tracking-widest mb-1">Precio Total</p>
                                <div className="flex items-baseline gap-2">
                                    <span className="text-5xl font-black text-white">${plainBot.price}</span>
                                    <span className="text-text-muted font-medium">USD</span>
                                </div>
                            </div>
                        </div>

                        <div className="p-8 md:p-12 flex flex-col justify-center">
                            <CheckoutClientForm bot={plainBot} />
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}
