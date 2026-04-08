import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const settings = await prisma.botSettings.findMany();
    return NextResponse.json({ 
      success: true, 
      count: settings.length,
      timestamp: new Date().toISOString(),
      data: settings 
    });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
