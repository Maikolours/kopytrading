const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
    try {
        const user = await prisma.user.findUnique({
            where: { email: 'viajaconsakura@gmail.com' }
        });
        if (!user) {
            console.log('Usuario no encontrado');
        } else {
            console.log('Email:', user.email);
            console.log('Role:', user.role);
            console.log('Password hash:', user.password ? user.password.substring(0, 15) + '...' : 'SIN PASSWORD');
        }
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}

run();
