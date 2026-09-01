import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { reportedNumbers } from "@/db/schema";
import { eq } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const phoneNumber = (body.phone_number || "").trim();
    const notes = body.notes || null;

    if (!phoneNumber) {
      return NextResponse.json({ error: "phone_number required" }, { status: 400 });
    }

    // Try Python backend first
    const PYTHON_BACKEND = process.env.PYTHON_BACKEND_URL || "http://localhost:8000";
    try {
      const res = await fetch(`${PYTHON_BACKEND}/report-number`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ phone_number: phoneNumber, notes }),
        signal: AbortSignal.timeout(5000),
      });
      if (res.ok) {
        return NextResponse.json(await res.json());
      }
    } catch {
      // fall through to DB
    }

    // Fallback: use PostgreSQL
    const existing = await db
      .select()
      .from(reportedNumbers)
      .where(eq(reportedNumbers.phoneNumber, phoneNumber))
      .limit(1);

    if (existing.length > 0) {
      const current = existing[0];
      await db
        .update(reportedNumbers)
        .set({
          reportCount: current.reportCount + 1,
          lastReportedAt: new Date(),
        })
        .where(eq(reportedNumbers.phoneNumber, phoneNumber));

      return NextResponse.json({
        success: true,
        phone_number: phoneNumber,
        total_reports: current.reportCount + 1,
      });
    } else {
      await db.insert(reportedNumbers).values({
        phoneNumber,
        reportCount: 1,
        lastReportedAt: new Date(),
        reportDetails: notes ? { notes } : null,
      });

      return NextResponse.json({
        success: true,
        phone_number: phoneNumber,
        total_reports: 1,
      });
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
