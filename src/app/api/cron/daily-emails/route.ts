import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { sendEmail } from "@/lib/email";

export async function GET(req: Request) {
    try {
        // Verificar si es una llamada desde Vercel Cron
        const authHeader = req.headers.get("authorization");
        if (process.env.CRON_SECRET && authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
            return new Response("Unauthorized", { status: 401 });
        }

        const now = new Date();
        console.log(`[CRON] Iniciando envío de correos automáticos: ${now.toISOString()}`);

        const purchases = await prisma.purchase.findMany({
            where: {
                status: "TRIAL",
            },
            include: {
                user: true,
                botProduct: true
            }
        });

        let sentCount = 0;

        for (const purchase of purchases) {
            const daysSinceDownload = Math.floor((now.getTime() - purchase.createdAt.getTime()) / (1000 * 60 * 60 * 24));
            
            let daysUntilExpiry = 30;
            if (purchase.expiresAt) {
                daysUntilExpiry = Math.floor((purchase.expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
            }

            const botName = purchase.botProduct.name;
            const userEmail = purchase.user.email;
            const userName = purchase.user.name || "Trader";

            if (!userEmail) continue;

            // DÍA 3: SEGUIMIENTO
            if (daysSinceDownload === 3) {
                await sendEmail(
                    userEmail,
                    `¿Qué tal tus primeros días con ${botName}? 🚀`,
                    `
                    <div style="font-family: sans-serif; color: #333;">
                        <h2>¡Hola ${userName}! 👋</h2>
                        <p>Hace 3 días que descargaste la licencia de prueba de <strong>${botName}</strong>.</p>
                        <p>¿Has podido instalarlo correctamente en tu MetaTrader 5? Recuerda que el bot funciona de forma 100% automática y no requiere de tu intervención.</p>
                        <p>Si tienes cualquier duda técnica o necesitas ayuda con la configuración, puedes responder a este correo y nuestro equipo de soporte te ayudará.</p>
                        <p>¡Mucho éxito en tus operativas!</p>
                        <br>
                        <p>El equipo de KopyTrading</p>
                    </div>
                    `
                );
                sentCount++;
            }

            // DÍA 7: RESEÑA
            else if (daysSinceDownload === 7) {
                await sendEmail(
                    userEmail,
                    `Tu opinión sobre ${botName} es clave para nosotros ⭐`,
                    `
                    <div style="font-family: sans-serif; color: #333;">
                        <h2>¡Hola de nuevo ${userName}!</h2>
                        <p>Llevas ya una semana probando la tecnología institucional de <strong>${botName}</strong> en tu cuenta.</p>
                        <p>¿Qué te está pareciendo? Nos ayudaría muchísimo saber tu opinión real para seguir mejorando nuestros algoritmos.</p>
                        <p>Te invitamos a dejar una reseña (tardarás menos de 1 minuto):</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="https://kopytrading.com/bots/${purchase.botProductId}" style="background-color: #000; color: #fff; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; text-transform: uppercase;">
                                Dejar una Reseña
                            </a>
                        </div>
                        <p>¡Gracias por tu apoyo!</p>
                        <br>
                        <p>El equipo de KopyTrading</p>
                    </div>
                    `
                );
                sentCount++;
            }

            // DÍA 25 (Aviso Caducidad)
            else if (daysUntilExpiry === 5 && daysSinceDownload >= 25) {
                await sendEmail(
                    userEmail,
                    `⚠️ Tu licencia de prueba está a punto de caducar`,
                    `
                    <div style="font-family: sans-serif; color: #333;">
                        <h2>¡Atención ${userName}!</h2>
                        <p>Te escribimos para avisarte de que tu licencia de prueba gratuita de <strong>${botName}</strong> caduca en exactamente 5 días.</p>
                        <p>Aprovecha estos últimos días para seguir viendo los resultados en tu cuenta.</p>
                        <p>Si deseas seguir operando y llevar tus ganancias al siguiente nivel, puedes adquirir la licencia ilimitada en nuestra plataforma.</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="https://kopytrading.com/bots" style="background-color: #ff9900; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; text-transform: uppercase;">
                                Ver Licencias Ilimitadas
                            </a>
                        </div>
                        <br>
                        <p>El equipo de KopyTrading</p>
                    </div>
                    `
                );
                sentCount++;
            }
        }

        return NextResponse.json({ success: true, sentCount, message: `Se enviaron ${sentCount} correos automatizados.` });
    } catch (error) {
        console.error("[CRON ERROR]", error);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
