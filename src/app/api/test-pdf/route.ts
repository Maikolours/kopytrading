import { NextResponse } from "next/server";
import { readFile } from "fs/promises";
import path from "path";

export async function GET(req: Request) {
    try {
        const filename = "Manual_Maiko_Pro_Cent.pdf";
        const filePath = path.join(process.cwd(), "public", "uploads", filename);
        console.log("TEST-PDF: Attempting to read", filePath);
        const fileBuffer = await readFile(filePath);
        
        return new NextResponse(fileBuffer, { status: 200 });
    } catch (error: any) {
        console.error("TEST-PDF ERROR:", error);
        return new NextResponse(error.message, { status: 500 });
    }
}
