
import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  const email = 'viajaconsakura@gmail.com'
  const password = '123456'
  
  try {
    const user = await prisma.user.findUnique({
      where: { email }
    })
    
    if (!user) {
      console.log("User not found: " + email)
      return
    }
    
    console.log("User found. Hash:", user.password)
    
    const isValid = await bcrypt.compare(password, user.password || '')
    console.log("Password is valid:", isValid)
    
  } catch (e) {
    console.error(e)
  } finally {
    await prisma.$disconnect()
  }
}

main()
