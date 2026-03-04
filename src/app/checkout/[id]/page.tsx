import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import CheckoutClientForm from "./CheckoutClientForm";

export default async function CheckoutPage(props: any) {
    const params = await props.params;
    const searchParams = await props.searchParams;
    
    const bot = await prisma.botProduct.findUnique({
        where: { id: params.id },
    });

    if (!bot) notFound();

    return (
        <main className="min-h-screen pt-24 flex items-center justify-center bg-black text-white">
            <div className="max-w-md w-full p-8 border border-white/10 rounded-3xl">
                <h1 className="text-2xl font-bold mb-4">{bot.name}</h1>
                <p className="mb-6 text-gray-400">
                    Precio: {searchParams.trial === 'true' ? "Gratis" : `${bot.price} EUR`}
                </p>
                <CheckoutClientForm 
                    bot={{ id: bot.id, name: bot.name, price: Number(bot.price) }} 
                    isTrial={searchParams.trial === 'true'} 
                />
            </div>
        </main>
    );
}
