import { PrismaClient } from '@prisma/client';
import { sendVersionUpdateEmail } from '../src/lib/email';

const prisma = new PrismaClient();

async function notifyUsers() {
    console.log('Fetching users to notify...');
    const users = await prisma.user.findMany({
        where: {
            OR: [
                { role: 'USER' },
                { role: 'TRIAL' }
            ]
        }
    });

    console.log(`Found ${users.length} users to notify.`);

    for (const user of users) {
        if (!user.email) continue;
        console.log(`Sending email to: ${user.email} (${user.name})`);
        try {
            await sendVersionUpdateEmail(user.email, "MAIKO PRO GOLD", "11.31", "bulk-update");
            console.log(`✅ Sent to ${user.email}`);
        } catch (error) {
            console.error(`❌ Failed to send to ${user.email}:`, error);
        }
    }

    console.log('Update notifications complete.');
}

notifyUsers()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
