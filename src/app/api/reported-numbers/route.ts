import { NextResponse } from "next/server";
import { db } from "@/db";
import { reportedNumbers } from "@/db/schema";
import { desc } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const rows = await db
      .select()
      .from(reportedNumbers)
      .orderBy(desc(reportedNumbers.reportCount))
      .limit(100);

    return NextResponse.json({
      numbers: rows.map((r) => ({
        phone_number: r.phoneNumber,
        report_count: r.reportCount,
        last_reported: r.lastReportedAt?.toISOString() || null,
      })),
      total: rows.length,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
