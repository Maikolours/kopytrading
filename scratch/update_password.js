const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function updatePassword() {
    try {
        const email = 'viajaconsakura@gmail.com';
        const newPasswordPlain = 'Dogi007759@';
        
        console.log(`Generando hash para: ${email}...`);
        const hashedPassword = await bcrypt.hash(newPasswordPlain, 10);
        
        const updated = await prisma.user.update({
            where: { email: email },
            data: { password: hashedPassword }
        });
        
        console.log('✅ Contraseña actualizada con éxito en la base de datos para:', updated.email);
        console.log('Rol:', updated.role);
    } catch (e) {
        console.error('❌ Error al actualizar contraseña:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}

updatePassword();
