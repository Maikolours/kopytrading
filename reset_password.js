const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
  const email = 'viajaconsakura@gmail.com';
  const newPassword = '123456';
  const hashedPassword = await bcrypt.hash(newPassword, 10);

  console.log("RESETTING PASSWORD FOR", email);

  try {
    const updated = await prisma.user.update({
      where: { email: email },
      data: { password: hashedPassword }
    });
    console.log("PASSWORD RESET SUCCESSFUL FOR:", updated.email);
  } catch (e) {
    console.error("ERROR RESETTING PASSWORD:", e);
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
