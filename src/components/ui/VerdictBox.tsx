"use client";

import { VERDICT_CONFIG } from "@/lib/constants";
import type { Verdict } from "@/types";

interface VerdictBoxProps {
  verdict: Verdict;
  simpleMode?: boolean;
  className?: string;
}

export function VerdictBox({ verdict, simpleMode = false, className = "" }: VerdictBoxProps) {
  const config = VERDICT_CONFIG[verdict];
  const color = config.color;

  const explanations: Record<Verdict, string> = {
    high_risk:
      "Both the voice pattern AND the call content show strong scam indicators. Do not share personal information or money.",
    medium_risk:
      "One signal is elevated. This call may be suspicious — verify the caller's identity through a known number before acting.",
    low_risk:
      "No significant scam signals detected. This call appears to be from a real person with normal content.",
  };

  return (
    <div
      className={`verdict-${verdict.replace("_risk", "")} ${className}`}
      style={{
        border: `2px solid ${color}`,
        borderRadius: 16,
        padding: simpleMode ? "28px 24px" : "20px 24px",
        textAlign: "center",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Background glow */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at center, ${color}18 0%, transparent 70%)`,
          pointerEvents: "none",
        }}
      />

      <div style={{ position: "relative", zIndex: 1 }}>
        <div style={{ fontSize: simpleMode ? "3rem" : "2.5rem", marginBottom: 8 }}>
          {config.emoji}
        </div>

        <div
          style={{
            fontFamily: "Fraunces, Georgia, serif",
            fontSize: simpleMode ? "2rem" : "1.5rem",
            fontWeight: 700,
            color,
            marginBottom: 8,
            letterSpacing: "0.02em",
          }}
        >
          {simpleMode ? config.simpleLabel : config.label}
        </div>

        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1.1rem" : "0.9rem",
            color: "#c8c5bf",
            margin: 0,
            lineHeight: 1.5,
          }}
        >
          {explanations[verdict]}
        </p>

        {simpleMode && (
          <div
            style={{
              marginTop: 16,
              padding: "8px 16px",
              background: `${color}22`,
              borderRadius: 8,
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.85rem",
              color: "#c8c5bf",
            }}
          >
            📞 If unsure, hang up and call the person directly on their real number.
          </div>
        )}
      </div>
    </div>
  );
}
