import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { protectedContacts } from "@/db/schema";
import { generateId } from "@/lib/utils";

export const dynamic = "force-dynamic";

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get("file") as File | null;
    const contactName = (formData.get("contact_name") as string || "").trim();
    const relationship = formData.get("relationship") as string | null;

    if (!contactName) {
      return NextResponse.json({ error: "contact_name required" }, { status: 400 });
    }

    // Try Python backend
    const PYTHON_BACKEND = process.env.PYTHON_BACKEND_URL || "http://localhost:8000";
    if (file) {
      try {
        const backendForm = new FormData();
        backendForm.append("file", file);
        backendForm.append("contact_name", contactName);
        if (relationship) backendForm.append("relationship", relationship);

        const res = await fetch(`${PYTHON_BACKEND}/enroll-voice`, {
          method: "POST",
          body: backendForm,
          signal: AbortSignal.timeout(15000),
        });
        if (res.ok) {
          const data = await res.json();

          // Also save to our DB
          const id = generateId();
          await db.insert(protectedContacts).values({
            id,
            name: contactName,
            relationship: relationship || null,
            voiceFeaturesJson: null,
            hasVoiceSample: 1,
          }).onConflictDoNothing();

          return NextResponse.json({ ...data, id });
        }
      } catch {
        // fall through
      }
    }

    // Fallback: save contact without audio features
    const id = generateId();
    try {
      await db.insert(protectedContacts).values({
        id,
        name: contactName,
        relationship: relationship || null,
        voiceFeaturesJson: null,
        hasVoiceSample: file ? 1 : 0,
      });
    } catch (dbErr) {
      console.error("DB insert error:", dbErr);
    }

    return NextResponse.json({
      success: true,
      contact_name: contactName,
      id,
      note: file
        ? "Contact saved. Voice analysis requires Python backend for full MFCC feature extraction."
        : "Contact saved without voice sample.",
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

export async function GET() {
  try {
    const rows = await db.select().from(protectedContacts);
    return NextResponse.json({
      contacts: rows.map((r) => ({
        id: r.id,
        name: r.name,
        relationship: r.relationship,
        has_voice_sample: r.hasVoiceSample === 1,
        created_at: r.createdAt?.toISOString() || null,
      })),
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
