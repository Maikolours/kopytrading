const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const email = 'viajaconsakura@gmail.com';
  const user = await prisma.user.findUnique({ where: { email } });
  
  if (!user || !user.password) {
    console.log("USER NOT FOUND OR NO PASSWORD");
    return;
  }

  const isMatch = await bcrypt.compare('123456', user.password);
  console.log("PASSWORD '123456' MATCHES?", isMatch);
  console.log("CURRENT HASH:", user.password);

  if (!isMatch) {
    console.log("RESETTING WITH BCRYPTJS...");
    const hashed = await bcrypt.hash('123456', 10);
    await prisma.user.update({
      where: { email },
      data: { password: hashed }
    });
    console.log("RESET SUCCESSFUL WITH BCRYPTJS");
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
