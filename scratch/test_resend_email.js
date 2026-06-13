const { Resend } = require('resend');

// We will read RESEND_API_KEY from env
const apiKey = process.env.RESEND_API_KEY;
if (!apiKey) {
  console.error("Error: RESEND_API_KEY environment variable is not defined.");
  process.exit(1);
}

const resend = new Resend(apiKey);

async function run() {
  console.log("Sending test email via Resend...");
  try {
    const data = await resend.emails.send({
      from: 'KopyTrading <onboarding@resend.dev>',
      to: 'viajaconsakura@gmail.com',
      subject: '🧪 Test KopyTrading Email',
      html: '<p>Este es un correo de prueba de <strong>KopyTrading</strong> para verificar la clave API de Resend.</p>',
    });
    console.log("Success! Email sent. Response data:", data);
  } catch (error) {
    console.error("Error sending email:", error);
  }
}

run();
