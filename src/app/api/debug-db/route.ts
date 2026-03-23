import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import bcrypt from 'bcryptjs';

export async function GET() {
  try {
    // 1. Check DB Connection
    await prisma.$connect();
    
    // 2. Check for Test User
    const testUser = await prisma.user.findUnique({
      where: { email: 'test@kopytrading.com' }
    });
    
    // 3. Check for Main User
    const mainUser = await prisma.user.findUnique({
      where: { email: 'viajaconsakura@gmail.com' }
    });

    // 4. Get all BotProducts
    const botProducts = await prisma.botProduct.findMany();

    return NextResponse.json({
      connected: true,
      hasTestUser: !!testUser,
      hasMainUser: !!mainUser,
      botProducts,
      nextAuthUrl: process.env.NEXTAUTH_URL,
    });
  } catch (error: any) {
    return NextResponse.json({
      connected: false,
      error: error.message,
      stack: error.stack
    }, { status: 500 });
  }
}
