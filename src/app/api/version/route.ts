import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    version: "v15.1-REPAIRED-SYNC-FUZZY",
    deployDate: new Date().toISOString(),
    status: "OK",
    author: "Antigravity",
    notes: "If you see this, the domain is correctly pointing to the new Vercel code."
  });
}
