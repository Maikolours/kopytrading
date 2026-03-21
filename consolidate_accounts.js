const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const sourceId = 'cmmb2z74y000mvhhoa8qm2o0v'; // Sin gmail
  const targetId = 'cmmb2z6ml000dvhhoj1s9zmnf'; // Con gmail (Sakura)

  console.log("MOVING PURCHASES FROM", sourceId, "TO", targetId);

  try {
    const updated = await prisma.purchase.updateMany({
      where: { userId: sourceId },
      data: { userId: targetId }
    });
    console.log("MOVED", updated.count, "PURCHASES.");

    // Eliminar el usuario duplicado
    await prisma.user.delete({ where: { id: sourceId } });
    console.log("DELETED DUPLICATE USER.");
    
  } catch (e) {
    console.error("ERROR MOVING PURCHASES:", e);
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
