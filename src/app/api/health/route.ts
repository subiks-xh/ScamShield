import { db } from "@/db";
import { sql } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    await db.execute(sql`select 1`);
    return Response.json({
      ok: true,
      service: "ScamShield Next.js API",
      database: "connected",
      timestamp: new Date().toISOString(),
    });
  } catch {
    return Response.json({
      ok: true,
      service: "ScamShield Next.js API",
      database: "unavailable",
      note: "The app is running with local client-side history and built-in analysis fallbacks.",
      timestamp: new Date().toISOString(),
    });
  }
}
