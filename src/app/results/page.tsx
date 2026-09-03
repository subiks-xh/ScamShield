"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ShieldEmblem } from "@/components/shield/ShieldEmblem";
import { ScoreBar, VoiceMatchBar } from "@/components/ui/ScoreBar";
import { VerdictBox } from "@/components/ui/VerdictBox";
import { useAppStore } from "@/store/useAppStore";
import { shareableReport, formatTimestamp } from "@/lib/utils";
import { VERDICT_CONFIG } from "@/lib/constants";

export default function ResultsPage() {
  const router = useRouter();
  const { currentResult, settings, protectedContacts } = useAppStore();
  const simpleMode = settings.simpleMode;
  const [shieldAnimated, setShieldAnimated] = useState(false);
  const [reportNumber, setReportNumber] = useState(false);
  const [reportDone, setReportDone] = useState(false);
  const [ttsActive, setTtsActive] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!currentResult) {
      router.replace("/");
      return;
    }

    // Trigger shield animation
    const t = setTimeout(() => setShieldAnimated(true), 100);

    // Auto-read verdict if TTS enabled (Simple Mode or setting)
    if (settings.ttsEnabled && "speechSynthesis" in window) {
      const config = VERDICT_CONFIG[currentResult.verdict];
      const utterance = new SpeechSynthesisUtterance(config.ttsText);
      utterance.rate = 0.85;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      utterance.onstart = () => setTtsActive(true);
      utterance.onend = () => setTtsActive(false);
      utterance.onerror = () => setTtsActive(false);

      // Small delay to let shield animation start
      const ttsTimer = setTimeout(() => {
        window.speechSynthesis.speak(utterance);
      }, 600);

      return () => {
        clearTimeout(t);
        clearTimeout(ttsTimer);
        window.speechSynthesis.cancel();
      };
    }

    return () => clearTimeout(t);
  }, [currentResult, router, settings.ttsEnabled]);

  const handleShare = async () => {
    if (!currentResult) return;
    const text = shareableReport(currentResult);

    if (navigator.share) {
      try {
        await navigator.share({ title: "ScamShield Report", text });
      } catch {
        // User cancelled
      }
    } else {
      await navigator.clipboard.writeText(text).catch(() => {});
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    }
  };

  const handleReportNumber = async () => {
    if (!currentResult?.callerNumber) return;
    setReportNumber(true);
    try {
      await fetch("/api/report-number", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          phone_number: currentResult.callerNumber,
          notes: `Verdict: ${currentResult.verdict}`,
        }),
      });
      setReportDone(true);
    } catch {
      // silent fail
    } finally {
      setReportNumber(false);
    }
  };

  const speakVerdict = () => {
    if (!currentResult || !("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const config = VERDICT_CONFIG[currentResult.verdict];
    const utterance = new SpeechSynthesisUtterance(config.ttsText);
    utterance.rate = 0.85;
    utterance.onstart = () => setTtsActive(true);
    utterance.onend = () => setTtsActive(false);
    window.speechSynthesis.speak(utterance);
  };

  if (!currentResult) return null;

  const contactWithSample = protectedContacts.find(
    (c) => c.name === currentResult.contactName && c.hasVoiceSample
  );

  return (
    <main
      style={{
        maxWidth: 480,
        margin: "0 auto",
        padding: "24px 20px 32px",
        minHeight: "100dvh",
      }}
    >
      {/* Top bar */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 12,
          marginBottom: 24,
          background: "linear-gradient(135deg, #3B1E54 0%, #4e2970 100%)",
          borderRadius: 16,
          padding: "14px 20px",
          border: "1px solid #C9A22733",
        }}
      >
        <button
          onClick={() => router.push("/")}
          style={{
            background: "none",
            border: "none",
            color: "#C9A227",
            cursor: "pointer",
            fontSize: "1.2rem",
            padding: "4px 8px",
            borderRadius: 8,
          }}
          aria-label="Go back to home"
        >
          ←
        </button>
        <h1
          style={{
            fontFamily: "Fraunces, Georgia, serif",
            fontSize: "1.2rem",
            fontWeight: 700,
            color: "#F8F5EF",
            margin: 0,
            flex: 1,
          }}
        >
          Analysis Results
        </h1>
        {currentResult.engineSource && (
          <span
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.75rem",
              background: currentResult.engineSource.includes("Python") ? "#2a4d35" : "#8B1E3F",
              color: currentResult.engineSource.includes("Python") ? "#8cd3a6" : "#f1aabf",
              padding: "4px 8px",
              borderRadius: "4px",
              fontWeight: 600,
              marginLeft: "auto",
              marginRight: "10px",
            }}
          >
            {currentResult.engineSource}
          </span>
        )}
        {/* TTS button */}
        {"speechSynthesis" in (typeof window !== "undefined" ? window : {}) && (
          <button
            onClick={speakVerdict}
            style={{
              background: ttsActive ? "#C9A22733" : "none",
              border: "1px solid #C9A22744",
              borderRadius: 8,
              color: "#C9A227",
              cursor: "pointer",
              padding: "6px 10px",
              fontSize: "1rem",
              transition: "all 0.2s",
            }}
            aria-label="Read verdict aloud"
            title="Read verdict aloud"
          >
            {ttsActive ? "🔊" : "🔈"}
          </button>
        )}
      </div>

      {/* Shield + Verdict */}
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          marginBottom: 24,
          gap: 20,
        }}
      >
        <ShieldEmblem
          variant="result"
          verdict={shieldAnimated ? currentResult.verdict : null}
          size={100}
          animate={true}
        />

        <VerdictBox
          verdict={currentResult.verdict}
          simpleMode={simpleMode}
        />
      </div>

      {/* Score bars */}
      <div
        className="card"
        style={{ marginBottom: 16 }}
      >
        <h2
          style={{
            fontFamily: "Fraunces, Georgia, serif",
            fontSize: simpleMode ? "1.2rem" : "1rem",
            fontWeight: 700,
            color: "#F8F5EF",
            margin: "0 0 16px 0",
          }}
        >
          {simpleMode ? "Detection Details" : "Risk Scores"}
        </h2>
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <ScoreBar
            label="AI Voice Score"
            score={currentResult.voiceAuthenticityScore}
            method={currentResult.analysisMethod}
            simpleMode={simpleMode}
          />
          <ScoreBar
            label="Scam Content Score"
            score={currentResult.contentRiskScore}
            simpleMode={simpleMode}
          />
        </div>

        {!simpleMode && (
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.72rem",
              color: "#55667a",
              margin: "12px 0 0 0",
            }}
          >
            High Risk requires BOTH scores &gt; 60 — ensuring real urgent calls are never wrongly flagged.
          </p>
        )}
      </div>

      {/* Voice match score (bonus signal) */}
      {currentResult.voiceMatchScore !== undefined &&
        currentResult.voiceMatchScore !== null &&
        currentResult.contactName && (
          <div style={{ marginBottom: 16 }}>
            <VoiceMatchBar
              score={currentResult.voiceMatchScore}
              contactName={currentResult.contactName}
              simpleMode={simpleMode}
            />
          </div>
        )}

      {/* Safety Action Plan / LLM Recommendations */}
      {currentResult.llmAnalysis && currentResult.llmAnalysis.recommended_actions && (
        <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #C9A227" }}>
          <h2
            style={{
              fontFamily: "Fraunces, Georgia, serif",
              fontSize: simpleMode ? "1.2rem" : "1rem",
              fontWeight: 700,
              color: "#F8F5EF",
              margin: "0 0 12px 0",
            }}
          >
            📋 Safety Action Plan
          </h2>
          <ul style={{ paddingLeft: 20, margin: 0, color: "#c8c5bf", fontSize: simpleMode ? "1rem" : "0.9rem", lineHeight: 1.5, fontFamily: "Manrope, sans-serif" }}>
            {currentResult.llmAnalysis.recommended_actions.map((action: string, i: number) => (
              <li key={i} style={{ marginBottom: 8 }}>{action}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Transcript */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
          <h2
            style={{
              fontFamily: "Fraunces, Georgia, serif",
              fontSize: simpleMode ? "1.2rem" : "1rem",
              fontWeight: 700,
              color: "#F8F5EF",
              margin: 0,
            }}
          >
            Transcript
          </h2>
          {currentResult.languageDetected && currentResult.languageDetected !== "en" && (
            <span
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.72rem",
                color: "#C9A227",
                background: "#C9A22722",
                padding: "2px 8px",
                borderRadius: 6,
              }}
            >
              {currentResult.languageDetected.toUpperCase()}
            </span>
          )}
        </div>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1rem" : "0.875rem",
            color: "#c8c5bf",
            margin: 0,
            lineHeight: 1.6,
            maxHeight: simpleMode ? "none" : 180,
            overflowY: "auto",
          }}
        >
          {currentResult.transcript || "(No transcript available)"}
        </p>
      </div>

      {/* Metadata */}
      {!simpleMode && (
        <div
          style={{
            background: "#0d1f3d",
            borderRadius: 10,
            padding: "12px 16px",
            marginBottom: 16,
            display: "flex",
            flexWrap: "wrap",
            gap: 8,
          }}
        >
          {currentResult.callerNumber && (
            <span
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.75rem",
                color: "#8899bb",
              }}
            >
              📞 {currentResult.callerNumber}
            </span>
          )}
          {currentResult.contactName && !contactWithSample && (
            <span
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.75rem",
                color: "#8899bb",
              }}
            >
              👤 Claimed: {currentResult.contactName} (no enrolled sample)
            </span>
          )}
          <span
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.75rem",
              color: "#55667a",
              marginLeft: "auto",
            }}
          >
            {formatTimestamp(currentResult.createdAt)}
          </span>
        </div>
      )}

      {/* Action buttons */}
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {/* Safe Pause Button */}
        <button
          onClick={() => {
              alert("PAUSE & VERIFY:\n\n1. Do not send money.\n2. Do not share OTPs.\n3. Hang up and verify directly.");
          }}
          style={{
            padding: simpleMode ? "20px" : "14px",
            background: "#2a4d35",
            border: "2px solid #3D6B4C",
            borderRadius: 12,
            color: "#8cd3a6",
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1.1rem" : "1rem",
            fontWeight: 700,
            cursor: "pointer",
            boxShadow: "0 4px 12px rgba(42, 77, 53, 0.4)",
          }}
          aria-label="Pause and verify"
        >
          ✋ Pause and Verify
        </button>

        {/* Report number */}
        {currentResult.callerNumber && !reportDone && (
          <button
            onClick={handleReportNumber}
            disabled={reportNumber}
            style={{
              padding: simpleMode ? "18px" : "12px",
              background: "#8B1E3F22",
              border: "1px solid #8B1E3F66",
              borderRadius: 12,
              color: "#e06080",
              fontFamily: "Manrope, sans-serif",
              fontSize: simpleMode ? "1rem" : "0.875rem",
              fontWeight: 600,
              cursor: reportNumber ? "not-allowed" : "pointer",
            }}
            aria-label="Report this number as a scam"
          >
            {reportNumber ? "Reporting…" : "🚫 Report This Number as Scam"}
          </button>
        )}
        {reportDone && (
          <div
            style={{
              padding: "10px",
              background: "#3D6B4C22",
              border: "1px solid #3D6B4C55",
              borderRadius: 12,
              textAlign: "center",
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.875rem",
              color: "#6db88a",
            }}
          >
            ✓ Number reported — thank you for protecting others
          </div>
        )}

        {/* Share */}
        <button
          onClick={handleShare}
          className="btn-outline"
          style={{ padding: simpleMode ? "18px" : "12px", fontSize: simpleMode ? "1rem" : "0.875rem" }}
          aria-label="Share this analysis report"
        >
          {copied ? "✓ Copied to clipboard" : "📤 Share This Report"}
        </button>

        {/* Analyze another */}
        <button
          onClick={() => router.push("/")}
          className="btn-gold"
          style={{ padding: simpleMode ? "20px" : "14px", fontSize: simpleMode ? "1.1rem" : "0.95rem" }}
          aria-label="Analyze another call"
        >
          🎙️ Analyze Another Call
        </button>
      </div>
    </main>
  );
}
