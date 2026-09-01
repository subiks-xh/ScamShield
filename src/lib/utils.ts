import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import type { AnalysisResult, WeeklySummary } from "@/types";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatTimestamp(iso: string): string {
  try {
    const d = new Date(iso);
    return d.toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

export function truncateText(text: string, maxLen = 100): string {
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen) + "…";
}

export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

export function generatePairingCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

export function computeWeeklySummary(history: AnalysisResult[]): WeeklySummary {
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - 7);
  weekStart.setHours(0, 0, 0, 0);

  const thisWeek = history.filter((r) => {
    try {
      return new Date(r.createdAt) >= weekStart;
    } catch {
      return false;
    }
  });

  return {
    totalAnalyzed: thisWeek.length,
    highRiskCount: thisWeek.filter((r) => r.verdict === "high_risk").length,
    mediumRiskCount: thisWeek.filter((r) => r.verdict === "medium_risk").length,
    lowRiskCount: thisWeek.filter((r) => r.verdict === "low_risk").length,
    weekStart: weekStart.toISOString(),
    weekEnd: now.toISOString(),
  };
}

export function scoreColor(score: number): string {
  if (score > 60) return "#8B1E3F";
  if (score > 30) return "#B8860B";
  return "#3D6B4C";
}

export function voiceMatchColor(score: number): string {
  // Inversely colored — high match = green (reassuring), low = red (warning)
  if (score >= 70) return "#3D6B4C";
  if (score >= 40) return "#B8860B";
  return "#8B1E3F";
}

export function formatPhoneNumber(num: string): string {
  const cleaned = num.replace(/\D/g, "");
  if (cleaned.length === 10) {
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  }
  return num;
}

export function shareableReport(result: AnalysisResult): string {
  const ts = formatTimestamp(result.createdAt);
  const verdictLabels: Record<string, string> = {
    high_risk: "🚨 HIGH RISK — Likely Scam",
    medium_risk: "⚠️ MEDIUM RISK — Suspicious",
    low_risk: "✅ LOW RISK — Appears Safe",
  };

  let text = `ScamShield Analysis Report\n`;
  text += `Generated: ${ts}\n`;
  text += `─────────────────────────────\n`;
  text += `VERDICT: ${verdictLabels[result.verdict] || result.verdict}\n\n`;
  text += `AI Voice Score: ${result.voiceAuthenticityScore.toFixed(0)}% (${result.voiceAuthenticityScore > 60 ? "likely AI-generated" : "likely human"})\n`;
  text += `Scam Content Score: ${result.contentRiskScore.toFixed(0)}% (${result.contentRiskScore > 60 ? "high risk language" : "normal language"})\n`;
  if (result.voiceMatchScore !== undefined && result.voiceMatchScore !== null) {
    text += `Voice Match (${result.contactName || "contact"}): ${result.voiceMatchScore.toFixed(0)}%\n`;
  }
  if (result.callerNumber) {
    text += `Caller: ${result.callerNumber}\n`;
  }
  text += `\nTranscript:\n"${result.transcript.slice(0, 300)}${result.transcript.length > 300 ? "…" : ""}"\n`;
  text += `─────────────────────────────\n`;
  text += `ScamShield — AI scam call detector\n`;
  text += `Note: Both AI voice AND scam language signals must be present for HIGH RISK.`;
  return text;
}
