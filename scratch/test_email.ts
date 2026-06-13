import 'dotenv/config';
import { sendVersionUpdateEmail } from '../src/lib/email';

async function test() {
    const testEmail = 'viajaconsakura@gmail.com';
    const botName = 'MAIKO SNIPER PRO 🎯';
    const newVersion = '11.30';
    const purchaseId = 'cmn9hfapj000hvhbca86faz0c';

    console.log(`Enviando correo real de prueba a ${testEmail}...`);
    try {
        const result = await sendVersionUpdateEmail(testEmail, botName, newVersion, purchaseId);
        console.log("Resultado del envío:", result);
    } catch (e) {
        console.error("Error al enviar el correo:", e);
    }
}

test();
