import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  console.log('--- STARTING CLEANUP ---')

  // 1. Identificadores correctos (los que tienen compras y telemetría)
  const ACTIVE_IDS = {
      GOLD: 'cmn9hf8yc0000vhbcq9hbxk0j',
      BTC: 'cmn9hf9bm0003vhbckaamkqal',
      EUR: 'cmn9hf9440001vhbclffx9no6',
      YEN: 'cmn9hf9800002vhbc5rky6dx8'
  }

  // 2. Eliminar duplicados con 0 compras
  const productsToDelete = await prisma.botProduct.findMany({
      where: {
          id: { notIn: Object.values(ACTIVE_IDS) },
          purchases: { none: {} }
      }
  })

  console.log(`Borrando ${productsToDelete.length} productos duplicados sin compras...`)
  for (const p of productsToDelete) {
      await prisma.botProduct.delete({ where: { id: p.id } })
      console.log(`- Borrado: ${p.name} (${p.id})`)
  }

  // 3. Activar y actualizar los bots principales
  console.log('Activando y actualizando productos principales...')

  // Gold
  await prisma.botProduct.update({
      where: { id: ACTIVE_IDS.GOLD },
      data: {
          name: 'ELITE GOLD AMETRALLADORA 🔥',
          price: 224,
          originalPrice: 299,
          version: '5.84',
          isActive: true,
          status: 'ACTIVE'
      }
  })
  console.log('✅ Oro actualizado.')

  // Bitcoin
  await prisma.botProduct.update({
      where: { id: ACTIVE_IDS.BTC },
      data: {
          name: 'ELITE SNIPER v13 ⚡',
          price: 224,
          originalPrice: 299,
          version: '7.11',
          isActive: true,
          status: 'ACTIVE'
      }
  })
  console.log('✅ Bitcoin actualizado.')

  // EUR
  await prisma.botProduct.update({
      where: { id: ACTIVE_IDS.EUR },
      data: {
          name: 'EURO PRECISION FLOW 🎯',
          isActive: true,
          status: 'ACTIVE'
      }
  })
  console.log('✅ EUR actualizado.')

  // YEN
  await prisma.botProduct.update({
      where: { id: ACTIVE_IDS.YEN },
      data: {
          name: 'YEN NINJA GHOST 🥷',
          isActive: true,
          status: 'ACTIVE'
      }
  })
  console.log('✅ YEN actualizado.')

  console.log('--- CLEANUP COMPLETED ---')
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect())
