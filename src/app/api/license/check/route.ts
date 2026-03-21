import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const purchaseId = searchParams.get("purchaseId");
  const account = searchParams.get("account");
  const mode = searchParams.get("mode"); // 0=Demo, 1=Real (custom)

  if (!purchaseId) {
    return NextResponse.json({ allowed: false, error: "Missing PurchaseID" }, { status: 400 });
  }

  try {
    const purchase = await prisma.purchase.findUnique({
      where: { id: purchaseId },
      include: { botProduct: true }
    });

    if (!purchase) {
      return NextResponse.json({ allowed: false, error: "Invalid License" }, { status: 404 });
    }

    // Lógica de Trial: Solo Demo
    if (purchase.status === "TRIAL") {
      if (mode === "1") { // Intento en Cuenta Real
         return NextResponse.json({ 
            allowed: false, 
            error: "TRIAL_REAL_FORBIDDEN",
            message: "La versión TRIAL solo funciona en cuentas DEMO." 
         });
      }

      // Check Expiración
      if (purchase.expiresAt && new Date() > new Date(purchase.expiresAt)) {
         return NextResponse.json({ 
            allowed: false, 
            error: "TRIAL_EXPIRED",
            message: "Tu periodo de prueba de 30 días ha terminado." 
         });
      }

      return NextResponse.json({ 
         allowed: true, 
         type: "TRIAL",
         message: "Prueba Activa (Solo Demo)" 
      });
    }

    // Lógica Full/Lifetime
    return NextResponse.json({ 
       allowed: true, 
       type: "FULL",
       message: "Licencia Vitalicia Activa" 
    });

  } catch (error) {
    console.error("License Check Error:", error);
    return NextResponse.json({ allowed: false, error: "Internal Error" }, { status: 500 });
  }
}
