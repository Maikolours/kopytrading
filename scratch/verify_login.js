const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function verify() {
    try {
        const user = await prisma.user.findUnique({
            where: { email: 'viajaconsakura@gmail.com' }
        });
        const matches = await bcrypt.compare('Dogi007759@', user.password);
        console.log('¿Verificación exitosa?:', matches);
    } catch (e) {
        console.error('Error:', e);
    } finally {
        await prisma.$disconnect();
    }
}

verify();
