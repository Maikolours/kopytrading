const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  await prisma.botProduct.update({
    where: { id: "cmn9hf8yc0000vhbcq9hbxk0j" },
    data: { name: "ELITE GOLD MAIKO SNIPER 🔥" }
  });

  await prisma.botProduct.update({
    where: { id: "cmn9hf9440001vhbclffx9no6" },
    data: { name: "MAIKO SNIPER PRO 🎯", instrument: "MULTIDIVISA" }
  });

  await prisma.botProduct.update({
    where: { id: "cmn9hf9800002vhbc5rky6dx8" },
    data: { name: "MAIKO SNIPER PRO CENT 🥷", instrument: "MULTIDIVISA" }
  });

  await prisma.botProduct.update({
    where: { id: "cmn9hf9bm0003vhbckaamkqal" },
    data: { name: "MAIKO BTC WEEKEND ⚡" }
  });

  console.log("Bots updated successfully");
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
