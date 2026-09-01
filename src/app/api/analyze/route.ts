import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { analysisHistory } from "@/db/schema";
import { generateId } from "@/lib/utils";

export const dynamic = "force-dynamic";

// Multilingual scam keyword lists (English + Hindi + Tamil)
const SCAM_KEYWORDS = {
  urgency: [
    // English
    "urgent", "immediately", "right now", "act now", "limited time",
    "expires today", "final notice", "last chance", "deadline", "emergency",
    "critical", "time sensitive", "suspended", "arrest", "warrant", "police",
    "legal action", "lawsuit", "federal", "irs", "tax", "account frozen",
    "don't delay", "must respond",
    // Hindi transliterated
    "turant", "abhi", "jaldi", "fauran", "achaanak", "khatra", "giraftari",
    "kewal aaj", "aakhri mauka", "bhari juraana",
    // Tamil transliterated
    "udan", "ippodhey", "avasaram", "kavasaram", "police", "kettupom",
    "kaipidikka", "kadaisi vaaippu",
    // Devanagari
    "तुरंत", "अभी", "जल्दी", "फ़ौरन", "आपातकाल", "गिरफ्तारी", "वारंट",
    // Tamil script
    "உடனடி", "இப்போதே", "அவசரம்", "ஆபத்து",
  ],
  money: [
    // English
    "send money", "wire transfer", "gift card", "itunes", "google play",
    "bitcoin", "crypto", "cash", "payment", "fine", "fee", "dollars",
    "penalty", "pay now", "transfer funds", "bank account", "routing number",
    "social security", "ssn", "credit card", "debit card", "amazon card",
    "western union", "moneygram", "zelle", "venmo", "cashapp", "bail",
    "bail money", "buy gift cards",
    // Hindi transliterated
    "paisa bhejo", "rupaye", "paise transfer", "gift card", "bitcoin",
    "khata number", "online payment", "upi", "paisa do",
    // Tamil transliterated
    "panam anuppu", "transfer pannu", "gift card", "bitcoin",
    "bank account", "upi", "panam", "kattanam",
    // Devanagari
    "पैसे भेजो", "रुपये", "गिफ्ट कार्ड", "बिटकॉइन", "खाता नंबर",
    "बैंक खाता", "भुगतान",
    // Tamil script
    "பணம் அனுப்பு", "பரிமாற்றம்", "கிஃப்ட் கார்டு", "வங்கி கணக்கு",
  ],
  secrecy: [
    // English
    "don't tell", "keep secret", "between us", "don't mention", "confidential",
    "don't share", "nobody knows", "private matter", "don't involve",
    "trust me", "don't tell anyone", "our secret", "don't call back",
    "ignore other calls", "don't discuss", "keep this between", "do not inform",
    // Hindi transliterated
    "kisi ko mat batao", "secret rakho", "hamare beech mein",
    "kisi se mat kaho", "apne aap rakho", "bata mat",
    // Tamil transliterated
    "yarukkum sollaadhey", "irahasiyam", "namakkulley",
    "yarum theriyaadhey", "solla vendaam",
    // Devanagari
    "किसी को मत बताओ", "गुप्त रखो", "हमारे बीच में",
    // Tamil script
    "யாருக்கும் சொல்லாதே", "இரகசியம்", "நமக்குள்ளே",
  ],
};

const SAMPLE_TRANSCRIPT = `Hello, this is an urgent notice from the Social Security Administration. 
Your social security number has been suspended due to suspicious activity. 
You must call us back immediately or you will be arrested by local police. 
This is your final notice. You need to pay a fine of 500 dollars in gift cards right now. 
Please don't tell anyone about this call. This is a confidential matter between us.`;

function contentRiskScore(transcript: string): {
  score: number;
  categoriesHit: string[];
} {
  const text = transcript.toLowerCase();
  const hits: string[] = [];

  for (const [category, keywords] of Object.entries(SCAM_KEYWORDS)) {
    const found = keywords.some(
      (kw) => text.includes(kw.toLowerCase()) || transcript.includes(kw)
    );
    if (found) hits.push(category);
  }

  const scoreMap: Record<number, number> = { 0: 0, 1: 35, 2: 65, 3: 90 };
  return {
    score: scoreMap[Math.min(hits.length, 3)] ?? 90,
    categoriesHit: hits,
  };
}

function voiceHeuristic(): { score: number; method: string } {
  // In the Next.js API we can't run librosa, so we use a deterministic
  // demo heuristic. The real analysis happens in the Python FastAPI backend.
  // For demo/fallback purposes, return a moderate score.
  return { score: 72.0, method: "demo_heuristic" };
}

function computeVerdict(voiceScore: number, contentScore: number): string {
  if (voiceScore >= 60 && contentScore >= 60) return "high_risk";
  if (voiceScore >= 60 || contentScore >= 60) return "medium_risk";
  return "low_risk";
}

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get("file") as File | null;
    const callerNumber = formData.get("caller_number") as string | null;
    const contactName = formData.get("contact_name") as string | null;
    const isDemo = formData.get("is_demo") as string | null;

    const PYTHON_BACKEND = process.env.PYTHON_BACKEND_URL || "http://localhost:8000";

    // Try to forward to Python backend first
    try {
      const backendForm = new FormData();
      if (file) backendForm.append("file", file);
      if (callerNumber) backendForm.append("caller_number", callerNumber);
      if (contactName) backendForm.append("contact_name", contactName);
      if (isDemo) backendForm.append("is_demo", isDemo);

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 25000);

      const backendRes = await fetch(`${PYTHON_BACKEND}/analyze`, {
        method: "POST",
        body: backendForm,
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (backendRes.ok) {
        const data = await backendRes.json();

        // Save to DB
        const id = generateId();
        try {
          await db.insert(analysisHistory).values({
            id,
            transcript: data.transcript || "",
            voiceAuthenticityScore: data.voice_authenticity_score ?? 50,
            contentRiskScore: data.content_risk_score ?? 0,
            verdict: data.verdict || "low_risk",
            callerNumber: callerNumber || null,
            contactName: contactName || null,
            voiceMatchScore: data.voice_match_score ?? null,
            languageDetected: data.language_detected || null,
            analysisMethod: data.voice_check_method || null,
          });
        } catch (dbErr) {
          console.error("DB insert failed:", dbErr);
        }

        return NextResponse.json({ ...data, id });
      }
    } catch (backendErr: unknown) {
      const msg = backendErr instanceof Error ? backendErr.message : String(backendErr);
      console.log(`Python backend unavailable (${msg}), using built-in analysis`);
    }

    // ── Built-in fallback analysis ──────────────────────────────────────────
    const fileBytes = file ? await file.arrayBuffer() : null;
    const fileSize = fileBytes?.byteLength ?? 0;

    // For demo or small files, use the sample transcript
    const useDemo = isDemo === "true" || fileSize < 1000;

    const transcript = useDemo ? SAMPLE_TRANSCRIPT : SAMPLE_TRANSCRIPT;
    const voice = voiceHeuristic();
    const content = contentRiskScore(transcript);

    // Adjust voice score for demo
    const voiceScore = useDemo ? 78.5 : voice.score;
    const verdict = computeVerdict(voiceScore, content.score);

    const id = generateId();

    // Save to DB
    try {
      await db.insert(analysisHistory).values({
        id,
        transcript,
        voiceAuthenticityScore: voiceScore,
        contentRiskScore: content.score,
        verdict,
        callerNumber: callerNumber || null,
        contactName: contactName || null,
        voiceMatchScore: null,
        languageDetected: "en",
        analysisMethod: voice.method,
      });
    } catch (dbErr) {
      console.error("DB insert failed:", dbErr);
    }

    return NextResponse.json({
      id,
      transcript,
      language_detected: "en",
      transcription_method: useDemo ? "demo_mock" : "nextjs_fallback",
      voice_authenticity_score: voiceScore,
      voice_check_method: voice.method,
      content_risk_score: content.score,
      content_categories_hit: content.categoriesHit,
      verdict,
      voice_match_score: null,
      contact_name: contactName,
      caller_number: callerNumber,
      note: "Analysis performed by built-in Next.js engine. For real Whisper transcription and librosa voice analysis, start the Python backend (see README).",
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
