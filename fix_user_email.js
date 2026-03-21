const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // Ver si existe alguien con viajaconsakura@gmail.com
  const existing = await prisma.user.findFirst({
    where: { email: { contains: 'viajaconsakura' } }
  });
  
  if (existing) {
    console.log("FOUND USER:", existing);
    // Cambiar 'viajaconsakura' a 'viajaconsakura@gmail.com' si es necesario
    if (existing.email === 'viajaconsakura') {
       const updated = await prisma.user.update({
         where: { id: existing.id },
         data: { email: 'viajaconsakura@gmail.com' }
       });
       console.log("UPDATED EMAIL TO: viajaconsakura@gmail.com");
    }
  } else {
    console.log("USER NOT FOUND WITH THAT PATTERN");
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
