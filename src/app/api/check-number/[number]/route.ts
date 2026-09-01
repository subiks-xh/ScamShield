import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { reportedNumbers } from "@/db/schema";
import { eq } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ number: string }> }
) {
  try {
    const { number } = await params;
    const phoneNumber = decodeURIComponent(number).trim();

    // Try Python backend first
    const PYTHON_BACKEND = process.env.PYTHON_BACKEND_URL || "http://localhost:8000";
    try {
      const res = await fetch(
        `${PYTHON_BACKEND}/check-number/${encodeURIComponent(phoneNumber)}`,
        { signal: AbortSignal.timeout(5000) }
      );
      if (res.ok) {
        return NextResponse.json(await res.json());
      }
    } catch {
      // fall through to DB
    }

    // Fallback: PostgreSQL
    const rows = await db
      .select()
      .from(reportedNumbers)
      .where(eq(reportedNumbers.phoneNumber, phoneNumber))
      .limit(1);

    if (rows.length > 0) {
      return NextResponse.json({
        found: true,
        phone_number: phoneNumber,
        report_count: rows[0].reportCount,
        last_reported: rows[0].lastReportedAt?.toISOString() || null,
      });
    }

    return NextResponse.json({
      found: false,
      phone_number: phoneNumber,
      report_count: 0,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
