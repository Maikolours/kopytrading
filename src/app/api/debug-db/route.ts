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

    return NextResponse.json({
      connected: true,
      hasTestUser: !!testUser,
      hasMainUser: !!mainUser,
      nextAuthUrl: process.env.NEXTAUTH_URL,
      nodeEnv: process.env.NODE_ENV,
      databaseUrlPrefix: process.env.DATABASE_URL?.split('@')[1] || 'NOT_SET'
    });
  } catch (error: any) {
    return NextResponse.json({
      connected: false,
      error: error.message,
      stack: error.stack
    }, { status: 500 });
  }
}
