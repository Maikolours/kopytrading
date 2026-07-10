import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getServerSession } from "next-auth";

export async function POST(req: Request) {
    try {
        const session = await getServerSession();
        if (!session?.user?.email) {
            return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
        }

        const body = await req.json();
        const { botProductId, rating, comment } = body;

        if (!botProductId || !rating || !comment) {
            return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
        }

        const user = await prisma.user.findUnique({
            where: { email: session.user.email }
        });

        if (!user) {
            return NextResponse.json({ error: "User not found" }, { status: 404 });
        }

        const review = await prisma.review.create({
            data: {
                rating: Number(rating),
                comment,
                userId: user.id,
                botProductId
            }
        });

        return NextResponse.json({ success: true, review });
    } catch (error) {
        console.error("Error creating review:", error);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}

export async function GET(req: Request) {
    try {
        const { searchParams } = new URL(req.url);
        const botProductId = searchParams.get("botProductId");

        if (!botProductId) {
            return NextResponse.json({ error: "Bot Product ID is required" }, { status: 400 });
        }

        const reviews = await prisma.review.findMany({
            where: { botProductId },
            include: {
                user: {
                    select: { name: true, image: true }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return NextResponse.json({ reviews });
    } catch (error) {
        console.error("Error fetching reviews:", error);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
