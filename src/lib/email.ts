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
        const bcc = email.toLowerCase() !== 'viajaconsakura@gmail.com' ? 'viajaconsakura@gmail.com' : undefined;
        const data = await resend.emails.send({
            from: 'KopyTrading <onboarding@resend.dev>', // Cámbialo a tu dominio verificado luego
            to: email,
            bcc: bcc,
            subject: subject,
            html: htmlContent,
        });
        return { success: true, data };
    } catch (error) {
        console.error("Error enviando email:", error);
        return { success: false, error };
    }
}

export async function sendTrialProgressEmail(email: string, daysRemaining: number, botName: string, purchaseId: string) {
    const buyRealLink = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/bots`;
    
    let subject = `📈 Progreso de tu Trial del bot ${botName}`;
    let title = "Progreso de tu Licencia Demo";
    let message = "";
    
    if (daysRemaining === 23 || daysRemaining === 21) {
        subject = `📈 Semana 1 Completada - Bot ${botName}`;
        title = "¡Primera semana de prueba superada!";
        message = "Tu bot lleva operando una semana en cuenta Demo. Observa su consistencia y cómo gestiona el riesgo. Recuerda que puedes adquirir la versión Real en cualquier momento para empezar a generar beneficios reales.";
    } else if (daysRemaining === 16 || daysRemaining === 14) {
        subject = `⚡ Semana 2 Completada - Bot ${botName}`;
        title = "Mitad de camino de tu prueba";
        message = "Has completado 14 días de prueba. El mercado cambia, pero tu algoritmo sigue ejecutando con precisión. No dejes pasar la oportunidad de dar el salto al mercado real cuando estés listo.";
    } else if (daysRemaining === 9 || daysRemaining === 7) {
        subject = `🚨 Semana 3 Completada - Bot ${botName}`;
        title = "¡Tres semanas de operativa!";
        message = "Has completado 21 días de prueba. Ya has visto el bot operar bajo diversas condiciones de mercado. Te quedan pocos días para finalizar. Adquiere tu licencia Real hoy mismo para asegurar tu plaza.";
    } else if (daysRemaining <= 2 && daysRemaining > 0) {
        subject = `🚨 ¡Última Semana de Trial para el bot ${botName}!`;
        title = "⚠️ Tu período de prueba está terminando";
        message = `Te quedan exactamente <strong>${daysRemaining} días</strong> de prueba en cuenta Demo. Asegúrate de adquirir la licencia Real antes de que expire para no interrumpir tu operativa y asegurar tu plaza.`;
    } else {
        message = `Te quedan ${daysRemaining} días de prueba con tu bot institucional en cuenta Demo.`;
    }

    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0d1117; color: #c9d1d9; border-radius: 10px;">
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #58a6ff; margin: 0;">KOPYTRADING</h1>
                <p style="color: #8b949e; letter-spacing: 2px; font-size: 12px; margin-top: 5px;">INSTITUTIONAL ALGORITHMS</p>
            </div>
            
            <h2 style="color: #ffffff; text-align: center;">${title}</h2>
            <p>Hola,</p>
            <p>${message}</p>
            
            <div style="background-color: #161b22; padding: 20px; border-radius: 8px; border: 1px solid #30363d; margin: 25px 0; text-align: center;">
                <h4 style="color: #ffffff; margin-top: 0; margin-bottom: 15px;">¿Listo para el Mercado Real?</h4>
                <p style="font-size: 13px; color: #8b949e; margin-bottom: 20px;">Da el salto y opera con capital real con la versión completa de MAIKO PRO GOLD.</p>
                <a href="${buyRealLink}" style="background-color: #238636; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Adquirir Licencia Real</a>
            </div>
            
            <div style="border-top: 1px solid #30363d; padding-top: 20px; margin-top: 30px; font-size: 11px; color: #8b949e; text-align: center;">
                <p>Estás recibiendo este correo porque tienes una licencia Demo activa con KopyTrading.</p>
            </div>
        </div>
    `;

    if (!resend) {
        console.log("==========================================");
        console.log("📧 SIMULACIÓN: CORREO DE SEGUIMIENTO DE TRIAL");
        console.log(`Para: ${email}`);
        console.log(`Asunto: ${subject}`);
        console.log(`Días restantes: ${daysRemaining}`);
        console.log("==========================================");
        return { success: true, simulated: true };
    }

    try {
        const bcc = email.toLowerCase() !== 'viajaconsakura@gmail.com' ? 'viajaconsakura@gmail.com' : undefined;
        const data = await resend.emails.send({
            from: 'KopyTrading <onboarding@resend.dev>',
            to: email,
            bcc: bcc,
            subject: subject,
            html: htmlContent,
        });
        return { success: true, data };
    } catch (error) {
        console.error("Error enviando email de progreso:", error);
        return { success: false, error };
    }
}

export async function sendTrialExpiredEmail(email: string, botName: string, purchaseId: string) {
    const buyRealLink = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/bots`;
    const subject = `❌ Licencia de Prueba Expirada - Bot ${botName}`;
    
    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0d1117; color: #c9d1d9; border-radius: 10px;">
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #ff7b72; margin: 0;">KOPYTRADING</h1>
                <p style="color: #8b949e; letter-spacing: 2px; font-size: 12px; margin-top: 5px;">PRUEBA FINALIZADA</p>
            </div>
            
            <h2 style="color: #ffffff; text-align: center;">Tu Trial ha Finalizado</h2>
            <p>Hola,</p>
            <p>El período de 30 días de prueba para tu bot <strong>${botName}</strong> en cuenta Demo ha expirado hoy, y las operaciones se han pausado.</p>
            <p>Esperamos que hayas podido comprobar el funcionamiento y consistencia del algoritmo en el mercado real de simulación.</p>
            
            <div style="background-color: #161b22; padding: 25px; border-radius: 8px; border: 1px solid #ff7b72/30; margin: 25px 0; text-align: center;">
                <h3 style="color: #ff7b72; margin-top: 0;">¡No dejes pasar la oportunidad!</h3>
                <p style="font-size: 14px; color: #c9d1d9; margin-bottom: 20px;">
                    Ya estás familiarizado con la operativa del bot. Ahora puedes dar el salto al mercado real adquiriendo tu licencia oficial para empezar a operar con tu capital.
                </p>
                <a href="${buyRealLink}" style="background-color: #238636; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 15px;">Comprar Licencia Real Now →</a>
            </div>
            
            <div style="border-top: 1px solid #30363d; padding-top: 20px; margin-top: 30px; font-size: 11px; color: #8b949e; text-align: center;">
                <p>KopyTrading · Tecnología de Trading Algorítmico Profesional.</p>
            </div>
        </div>
    `;

    if (!resend) {
        console.log("==========================================");
        console.log("📧 SIMULACIÓN: CORREO DE TRIAL EXPIRADO");
        console.log(`Para: ${email}`);
        console.log(`Asunto: ${subject}`);
        console.log("==========================================");
        return { success: true, simulated: true };
    }

    try {
        const bcc = email.toLowerCase() !== 'viajaconsakura@gmail.com' ? 'viajaconsakura@gmail.com' : undefined;
        const data = await resend.emails.send({
            from: 'KopyTrading <onboarding@resend.dev>',
            to: email,
            bcc: bcc,
            subject: subject,
            html: htmlContent,
        });
        return { success: true, data };
    } catch (error) {
        console.error("Error enviando email de expiración:", error);
        return { success: false, error };
    }
}

export async function sendVersionUpdateEmail(email: string, botName: string, newVersion: string, purchaseId: string) {
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
                <p style="margin: 12px 0 0 0; font-size: 12px; color: #8b949e; line-height: 1.5;">Esta versión incluye los nuevos parámetros de Stop Loss con función Standby (espera de 10 min tras pérdida) y Bloqueo de Horas Críticas (para evitar noticias de alta volatilidad).</p>
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
                <li style="margin-bottom: 8px;">Asegúrate de comprobar la pestaña de parámetros de tu bot para configurar las nuevas opciones de gestión de riesgo si deseas usarlas.</li>
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
            from: 'KopyTrading <onboarding@resend.dev>',
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

