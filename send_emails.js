const { PrismaClient } = require('@prisma/client');
const { Resend } = require('resend');
const dotenv = require('dotenv');

dotenv.config();

const prisma = new PrismaClient();
const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;

async function sendVersionUpdateEmail(email, botName, newVersion, purchaseId) {
    const downloadLink = `${process.env.NEXT_PUBLIC_APP_URL || 'https://www.kopytrading.com'}/dashboard`;
    const subject = `🔔 Nueva actualización disponible: ${botName} v${newVersion}`;
    
    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0d1117; color: #c9d1d9; border-radius: 10px; border: 1px solid #30363d;">
            <div style="text-align: center; margin-bottom: 30px; border-bottom: 1px solid #30363d; padding-bottom: 20px;">
                <h1 style="color: #58a6ff; margin: 0; font-size: 28px; font-weight: 900; letter-spacing: -1px;">KOPYTRADING</h1>
                <p style="color: #8b949e; letter-spacing: 2px; font-size: 11px; margin-top: 5px; font-weight: bold; uppercase">UPDATES & OPTIMIZATIONS</p>
            </div>
            
            <h2 style="color: #ffffff; font-size: 20px; font-weight: 800; margin-top: 0;">¡Nueva Versión Disponible (v${newVersion})!</h2>
            <p style="line-height: 1.6; font-size: 14px;">Hola,</p>
            <p style="line-height: 1.6; font-size: 14px;">Queremos informarte que se ha publicado una nueva versión optimizada para tu bot <strong>${botName}</strong>.</p>
            
            <div style="background-color: #161b22; padding: 20px; border-radius: 12px; border: 1px solid #30363d; margin: 25px 0;">
                <h3 style="color: #58a6ff; margin-top: 0; font-size: 15px; font-weight: bold;">Detalles de la versión v${newVersion}</h3>
                <p style="margin: 6px 0; font-size: 13px;"><strong>Bot:</strong> ${botName}</p>
                <p style="margin: 6px 0; font-size: 13px;"><strong>Nueva Versión:</strong> <span style="font-family: monospace; background: #000; padding: 3px 8px; border-radius: 4px; color: #58a6ff; font-weight: bold;">v${newVersion}</span></p>
                <p style="margin: 12px 0 0 0; font-size: 12px; color: #8b949e; line-height: 1.5;">Esta versión incluye los nuevos parámetros corregidos, solución de incompatibilidades de caracteres, y soporte dinámico para horarios de cierre de fin de semana (viernes a las 23:00).</p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="${downloadLink}" style="background-color: #238636; color: white; padding: 12px 28px; text-decoration: none; border-radius: 8px; font-weight: 900; display: inline-block; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; border: 1px solid #30363d; transition: all 0.3s;">Acceder a Mi Panel y Descargar (.EX5)</a>
            </div>
            
            <h3 style="color: #ffffff; font-size: 15px; font-weight: bold; margin-top: 25px;">¿Cómo actualizar tu EA?</h3>
            <ol style="color: #c9d1d9; padding-left: 20px; line-height: 1.6; font-size: 13px; margin-top: 10px;">
                <li style="margin-bottom: 8px;">Accede a tu panel en KopyTrading y descarga la última versión (archivo <strong>.EX5</strong>).</li>
                <li style="margin-bottom: 8px;">En MetaTrader 5, ve a <strong>Archivo > Abrir Carpeta de Datos</strong>.</li>
                <li style="margin-bottom: 8px;">Navega a <strong>MQL5 > Experts</strong> y reemplaza el archivo antiguo por el nuevo.</li>
                <li style="margin-bottom: 8px;">Haz clic derecho sobre la carpeta Experts en el Navegador de MT5 y selecciona <b>Actualizar</b> (o reinicia MetaTrader).</li>
            </ol>
            
            <div style="border-top: 1px solid #30363d; padding-top: 20px; margin-top: 35px; font-size: 11px; color: #8b949e; text-align: center; line-height: 1.4;">
                <p>KopyTrading · Tecnología de Trading Algorítmico Profesional.</p>
                <p style="font-size: 10px; color: #484f58; margin-top: 5px;">Este es un correo automático de actualización del sistema. Por favor no respondas a este mensaje.</p>
            </div>
        </div>
    `;

    if (!resend) {
        console.log("==========================================");
        console.log("📧 SIMULACIÓN: ENVÍO DE EMAIL DE ACTUALIZACIÓN DE BOT");
        console.log(`Para: ${email}`);
        console.log(`Asunto: ${subject}`);
        console.log(`Nueva versión: ${newVersion}`);
        console.log("==========================================");
        return { success: true, simulated: true };
    }

    try {
        const bcc = email.toLowerCase() !== 'viajaconsakura@gmail.com' ? 'viajaconsakura@gmail.com' : undefined;
        const data = await resend.emails.send({
            from: 'KopyTrading <info@kopytrading.com>',
            to: email,
            bcc: bcc,
            subject: subject,
            html: htmlContent,
        });
        return { success: true, data };
    } catch (error) {
        console.error("Error enviando email de actualización:", error);
        return { success: false, error };
    }
}

async function run() {
    const botsToUpdate = [
        "cmn9hf8yc0000vhbcq9hbxk0j", // DEMO
        "cmn9hf9440001vhbclffx9no6", // GOLD
        "cmn9hf9800002vhbc5rky6dx8", // CENT
    ];
    const newVersion = "11.32";
    
    let emailsSent = 0;
    for (let botId of botsToUpdate) {
        const bot = await prisma.botProduct.update({
            where: { id: botId },
            data: { version: newVersion }
        });
        console.log(`Updated version of ${bot.name} to ${newVersion}`);
        
        const purchases = await prisma.purchase.findMany({
            where: { botProductId: botId, status: "COMPLETED" },
            include: { user: true }
        });
        
        const uniqueUsers = new Map();
        purchases.forEach(p => {
            if (p.user && p.user.email) {
                const emailKey = p.user.email.trim().toLowerCase();
                if (!uniqueUsers.has(emailKey)) {
                    uniqueUsers.set(emailKey, { email: p.user.email, purchaseId: p.id });
                }
            }
        });
        
        for (const [_, userInfo] of uniqueUsers.entries()) {
            await sendVersionUpdateEmail(userInfo.email, bot.name, newVersion, userInfo.purchaseId);
            emailsSent++;
        }
    }
    console.log(`Successfully sent ${emailsSent} emails!`);
}

run().catch(console.error).finally(() => prisma.$disconnect());
