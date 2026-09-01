"use client";

import { useEffect, useState } from "react";
import { scoreColor } from "@/lib/utils";

interface ScoreBarProps {
  label: string;
  score: number;
  method?: string;
  simpleMode?: boolean;
}

export function ScoreBar({ label, score, method, simpleMode = false }: ScoreBarProps) {
  const [displayWidth, setDisplayWidth] = useState(0);
  const color = scoreColor(score);
  const clampedScore = Math.max(0, Math.min(100, score));

  useEffect(() => {
    const timer = setTimeout(() => {
      const prefersReduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
      if (prefersReduced) {
        setDisplayWidth(clampedScore);
        return;
      }
      let start: number | null = null;
      const duration = 900;
      function animate(ts: number) {
        if (!start) start = ts;
        const elapsed = ts - start;
        const t = Math.min(elapsed / duration, 1);
        const eased = 1 - Math.pow(1 - t, 3);
        setDisplayWidth(eased * clampedScore);
        if (t < 1) requestAnimationFrame(animate);
      }
      requestAnimationFrame(animate);
    }, 200);
    return () => clearTimeout(timer);
  }, [clampedScore]);

  const riskLabel =
    clampedScore > 60 ? "High" : clampedScore > 30 ? "Moderate" : "Low";

  return (
    <div className="space-y-2">
      <div className="flex justify-between items-baseline">
        <span
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1rem" : "0.875rem",
            color: "#c8c5bf",
            fontWeight: 500,
          }}
        >
          {label}
          {method && !simpleMode && (
            <span style={{ fontSize: "0.7rem", marginLeft: 6, opacity: 0.6 }}>
              [{method}]
            </span>
          )}
        </span>
        <span
          style={{
            fontFamily: "IBM Plex Mono, monospace",
            fontSize: simpleMode ? "1.2rem" : "1rem",
            color,
            fontWeight: 700,
          }}
        >
          {clampedScore.toFixed(0)}%
          {!simpleMode && (
            <span
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.7rem",
                marginLeft: 4,
                opacity: 0.7,
              }}
            >
              {riskLabel}
            </span>
          )}
        </span>
      </div>

      {/* Bar track */}
      <div
        style={{
          width: "100%",
          height: simpleMode ? 14 : 10,
          background: "#1e3a6e",
          borderRadius: 999,
          overflow: "hidden",
        }}
        role="progressbar"
        aria-valuenow={Math.round(clampedScore)}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={`${label}: ${Math.round(clampedScore)}%`}
      >
        <div
          style={{
            width: `${displayWidth}%`,
            height: "100%",
            background: `linear-gradient(90deg, ${color}88, ${color})`,
            borderRadius: 999,
            transition: "width 0.05s linear",
            boxShadow: `0 0 8px ${color}66`,
          }}
        />
      </div>

      {simpleMode && (
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.85rem",
            color: "#c8c5bf",
            margin: 0,
          }}
        >
          {label === "AI Voice Score"
            ? clampedScore > 60
              ? "This voice sounds like it may be AI-generated"
              : "This voice sounds natural and human"
            : clampedScore > 60
            ? "This call contains scam-like language"
            : "No suspicious phrases detected"}
        </p>
      )}
    </div>
  );
}

interface VoiceMatchBarProps {
  score: number;
  contactName: string;
  simpleMode?: boolean;
}

export function VoiceMatchBar({ score, contactName, simpleMode = false }: VoiceMatchBarProps) {
  const [displayWidth, setDisplayWidth] = useState(0);
  // Inverse color: high match = green, low match = red
  const color = score >= 70 ? "#3D6B4C" : score >= 40 ? "#B8860B" : "#8B1E3F";
  const label = score >= 70 ? "Good match ✓" : score >= 40 ? "Partial match" : "Poor match ⚠️";
  const clampedScore = Math.max(0, Math.min(100, score));

  useEffect(() => {
    const timer = setTimeout(() => {
      let start: number | null = null;
      const duration = 900;
      function animate(ts: number) {
        if (!start) start = ts;
        const elapsed = ts - start;
        const t = Math.min(elapsed / duration, 1);
        setDisplayWidth((1 - Math.pow(1 - t, 3)) * clampedScore);
        if (t < 1) requestAnimationFrame(animate);
      }
      requestAnimationFrame(animate);
    }, 400);
    return () => clearTimeout(timer);
  }, [clampedScore]);

  return (
    <div
      style={{
        background: "#0d1f3d",
        border: `1px solid ${color}44`,
        borderRadius: 12,
        padding: "16px",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          marginBottom: 8,
        }}
      >
        <span style={{ fontSize: "1.1rem" }}>🔬</span>
        <span
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.8rem",
            color: "#C9A22788",
            textTransform: "uppercase",
            letterSpacing: "0.06em",
            fontWeight: 600,
          }}
        >
          Bonus Signal · Protected Contact
        </span>
      </div>

      <p
        style={{
          fontFamily: "Manrope, sans-serif",
          fontSize: simpleMode ? "1rem" : "0.875rem",
          color: "#c8c5bf",
          margin: "0 0 12px 0",
        }}
      >
        Voice match to <strong style={{ color: "#F8F5EF" }}>{contactName}</strong>
        <span
          style={{
            fontFamily: "IBM Plex Mono, monospace",
            fontSize: simpleMode ? "1.2rem" : "1.1rem",
            color,
            fontWeight: 700,
            marginLeft: 8,
          }}
        >
          {clampedScore.toFixed(0)}%
        </span>
        <span
          style={{
            marginLeft: 6,
            fontSize: "0.8rem",
            color,
          }}
        >
          {label}
        </span>
      </p>

      <div
        style={{
          width: "100%",
          height: 8,
          background: "#1e3a6e",
          borderRadius: 999,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            width: `${displayWidth}%`,
            height: "100%",
            background: `linear-gradient(90deg, ${color}88, ${color})`,
            borderRadius: 999,
          }}
        />
      </div>

      <p
        style={{
          fontFamily: "Manrope, sans-serif",
          fontSize: "0.72rem",
          color: "#8899bb",
          margin: "10px 0 0 0",
          fontStyle: "italic",
        }}
      >
        Bonus signal only · Does not affect the main verdict · Requires enrolled voice sample (stored locally, never uploaded)
      </p>
    </div>
  );
}
