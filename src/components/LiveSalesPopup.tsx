"use client";

import { useState, useEffect } from "react";

const BOTS = ["La Ametralladora v5.0", "Euro Precision Flow", "Yen Ninja Ghost", "BTC Storm Rider v6.0"];
const OUTCOMES = [
    { text: "operación ganadora", emoji: "✅", color: "text-success", bg: "bg-success/10", border: "border-success/30" },
    { text: "Take Profit alcanzado", emoji: "🎯", color: "text-success", bg: "bg-success/10", border: "border-success/30" },
    { text: "Break Even activado", emoji: "🛡️", color: "text-brand-light", bg: "bg-brand/10", border: "border-brand/30" },
    { text: "Cierre por Trailing", emoji: "📉", color: "text-success", bg: "bg-success/10", border: "border-success/30" }
];

export function LiveSalesPopup() {
    return null;
}
