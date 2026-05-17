import { Resend } from 'resend';

// Solo inicializamos Resend si existe la clave de API
const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;

export async function sendWelcomeEmail(email: string, licenseKey: string, botName: string, purchaseId: string) {
    const downloadLink = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/download?p=${purchaseId}`;
    const passwordResetLink = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/auth/reset-password`;
    
    const subject = `🚀 Tu Bot Institucional: ${botName} está listo`;
    
    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0d1117; color: #c9d1d9; border-radius: 10px;">
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #58a6ff; margin: 0;">KOPYTRADING</h1>
                <p style="color: #8b949e; letter-spacing: 2px; font-size: 12px; margin-top: 5px;">INSTITUTIONAL ALGORITHMS</p>
            </div>
            
            <h2 style="color: #ffffff;">¡Bienvenido a la Élite!</h2>
            <p>Hola,</p>
            <p>Tu compra del bot <strong>${botName}</strong> se ha procesado con éxito. Ya tienes acceso a tu tecnología de francotirador institucional.</p>
            
            <div style="background-color: #161b22; padding: 20px; border-radius: 8px; border: 1px solid #30363d; margin: 25px 0;">
                <h3 style="color: #58a6ff; margin-top: 0;">Tus Credenciales de Activación</h3>
                <p style="margin: 5px 0;"><strong>Email de Compra:</strong> ${email}</p>
                <p style="margin: 5px 0;"><strong>Clave Única:</strong> <span style="font-family: monospace; background: #000; padding: 3px 8px; border-radius: 4px; color: #ff7b72;">${licenseKey}</span></p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="${downloadLink}" style="background-color: #238636; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Descargar Archivo .EX5</a>
            </div>
            
            <h3 style="color: #ffffff;">¿Cómo instalarlo?</h3>
            <ol style="color: #c9d1d9;">
                <li>Descarga el archivo desde el botón de arriba.</li>
                <li>Abre tu MetaTrader 5 y ve a <strong>Archivo > Abrir Carpeta de Datos</strong>.</li>
                <li>Pega el archivo en la carpeta <strong>MQL5 > Experts</strong>.</li>
                <li>Asegúrate de permitir WebRequest hacia <code>https://kopytrading.com</code> en las opciones de MetaTrader.</li>
                <li>Arrastra el bot al gráfico e introduce tu Email y tu Clave Única.</li>
            </ol>
            
            <div style="border-top: 1px solid #30363d; padding-top: 20px; margin-top: 30px; font-size: 12px; color: #8b949e;">
                <p>Se ha creado una cuenta automáticamente en nuestra web para que gestiones tus licencias.</p>
                <p>Puedes <a href="${passwordResetLink}" style="color: #58a6ff;">crear tu propia contraseña aquí</a>.</p>
            </div>
        </div>
    `;

    // Si NO hay Resend configurado, simulamos el envío en la consola (para pruebas locales)
    if (!resend) {
        console.log("==========================================");
        console.log("📧 SIMULACIÓN DE ENVÍO DE CORREO (RESEND_API_KEY no configurado)");
        console.log(`Para: ${email}`);
        console.log(`Asunto: ${subject}`);
        console.log(`Link de Descarga: ${downloadLink}`);
        console.log(`Clave: ${licenseKey}`);
        console.log("==========================================");
        return { success: true, simulated: true };
    }

    try {
        const data = await resend.emails.send({
            from: 'KopyTrading <onboarding@resend.dev>', // Cámbialo a tu dominio verificado luego
            to: email,
            subject: subject,
            html: htmlContent,
        });
        return { success: true, data };
    } catch (error) {
        console.error("Error enviando email:", error);
        return { success: false, error };
    }
}
