import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import dynamic from "next/dynamic";

const CheckoutClientForm = dynamic<any>(
    () => import("./CheckoutClientForm"),
    {
        ssr: false,
        loading: () => (
            <div className="flex flex-col items-center justify-center py-20">
                <div className="w-10 h-10 border-4 border-brand-light border-t-transparent rounded-full animate-spin"></div>
                <p className="mt-4 text-text-muted">Cargando pasarela...</p>
            </div>
        )
    }
);

export default async function CheckoutPage(props: any) {
    // Esta es la forma más segura de extraer los datos en Next.js 15
    const params = await props.params;
    const searchParams = await props.searchParams;
    
    const id = params.id;
    const isTrial = searchParams.trial === 'true';

    const bot = await prisma.botProduct.findUnique({
        where: { id: id },
    });

    if (!bot) notFound();

    const plainBot = {
        id: bot.id,
        name: bot.name,
        price: Number(bot.price),
    };

    return (
        <main className="min-h-screen pt-24 pb-12 px-4">
            <div className="max-w-4xl mx-auto">
                <div className="bg-surface-dark/50 backdrop-blur-xl border border-white/5 rounded-[2.5rem] overflow-hidden">
                    <div className="grid md:grid-cols-2">
                        <div className="p-8 md:p-12 bg-gradient-to-br from-brand/10 to-transparent border-r border-white/5">
                            <h1 className="text-3xl font-black text-white mb-4">{plainBot.name}</h1>
                            <p className="text-text-muted mb-8">
                                {isTrial ? "Prueba gratuita de 30 días activada." : "Licencia completa e instantánea."}
                            </p>
                            <div className="mt-12 pt-8 border-t border-white/10">
                                <div className="flex items-baseline gap-2">
                                    <span className="text-5xl font-black text-white">{isTrial ? "0" : plainBot.price}</span>
                                    <span className="text-text-muted font-medium">EUR (€)</span>
                                </div>
                            </div>
                        </div>
                        <div className="p-8 md:p-12">
                            <CheckoutClientForm bot={plainBot} isTrial={isTrial} />
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}
