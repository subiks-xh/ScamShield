"use client";

import { useEffect, useState } from "react";
import type { Verdict } from "@/types";

interface ShieldEmblemProps {
  variant?: "home" | "result" | "history" | "empty";
  verdict?: Verdict | null;
  size?: number;
  animate?: boolean;
  className?: string;
}

const VERDICT_FILL: Record<string, string> = {
  high_risk: "#8B1E3F",
  medium_risk: "#B8860B",
  low_risk: "#3D6B4C",
};

export function ShieldEmblem({
  variant = "home",
  verdict = null,
  size = 120,
  animate = true,
  className = "",
}: ShieldEmblemProps) {
  const [fillProgress, setFillProgress] = useState(0);

  useEffect(() => {
    if (verdict && animate) {
      // Respect reduced motion
      const prefersReduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
      if (prefersReduced) {
        setFillProgress(1);
        return;
      }
      let start: number | null = null;
      const duration = 1200;
      function frame(ts: number) {
        if (!start) start = ts;
        const elapsed = ts - start;
        const progress = Math.min(elapsed / duration, 1);
        // Ease-out cubic
        setFillProgress(1 - Math.pow(1 - progress, 3));
        if (progress < 1) requestAnimationFrame(frame);
      }
      const rafId = requestAnimationFrame(frame);
      return () => cancelAnimationFrame(rafId);
    } else if (!verdict) {
      setFillProgress(0);
    }
  }, [verdict, animate]);

  const fillColor = verdict ? VERDICT_FILL[verdict] : "none";
  const strokeColor = "#C9A227";
  const strokeWidth = Math.max(1.5, size / 60);
  const opacity = variant === "empty" ? 0.25 : 1;

  // Shield path: heraldic shape, centered in 100×120 viewBox
  const shieldPath = `
    M 50 8
    C 50 8, 85 14, 90 18
    L 90 55
    C 90 82, 70 100, 50 112
    C 30 100, 10 82, 10 55
    L 10 18
    C 15 14, 50 8, 50 8
    Z
  `;

  // Inner decorative line
  const innerPath = `
    M 50 18
    C 50 18, 78 23, 82 26
    L 82 55
    C 82 77, 65 93, 50 103
    C 35 93, 18 77, 18 55
    L 18 26
    C 22 23, 50 18, 50 18
    Z
  `;

  // Clip for fill animation (bottom-up fill)
  const clipY = variant === "result" ? 112 - fillProgress * 104 : 0;
  const clipId = `shield-clip-${variant}-${verdict || "none"}`;

  return (
    <svg
      width={size}
      height={size * 1.2}
      viewBox="0 0 100 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      style={{ opacity }}
      aria-label={verdict ? `Shield: ${verdict.replace("_", " ")}` : "ScamShield emblem"}
      role="img"
    >
      <defs>
        <clipPath id={clipId}>
          <rect x="0" y={clipY} width="100" height="120" />
        </clipPath>
      </defs>

      {/* Fill layer (animated) */}
      {fillColor !== "none" && (
        <path
          d={shieldPath}
          fill={fillColor}
          fillOpacity={0.35}
          clipPath={`url(#${clipId})`}
        />
      )}

      {/* Outer shield outline */}
      <path
        d={shieldPath}
        stroke={strokeColor}
        strokeWidth={strokeWidth}
        fill="none"
        strokeLinejoin="round"
        strokeLinecap="round"
      />

      {/* Inner decorative border */}
      <path
        d={innerPath}
        stroke={strokeColor}
        strokeWidth={strokeWidth * 0.5}
        fill="none"
        strokeOpacity={0.5}
        strokeLinejoin="round"
      />

      {/* Central symbol */}
      {variant === "home" && (
        <>
          {/* Mic icon center */}
          <circle cx="50" cy="54" r="10" stroke={strokeColor} strokeWidth={strokeWidth * 0.7} fill="none" />
          <line x1="50" y1="64" x2="50" y2="72" stroke={strokeColor} strokeWidth={strokeWidth * 0.7} strokeLinecap="round" />
          <line x1="42" y1="72" x2="58" y2="72" stroke={strokeColor} strokeWidth={strokeWidth * 0.7} strokeLinecap="round" />
          <path d="M 42 54 C 42 45 58 45 58 54" stroke={strokeColor} strokeWidth={strokeWidth * 0.7} fill="none" strokeLinecap="round" />
        </>
      )}

      {variant === "result" && verdict && fillProgress > 0.4 && (
        <>
          {/* Verdict-dependent icon */}
          {verdict === "high_risk" && (
            <>
              <line x1="50" y1="42" x2="50" y2="62" stroke="#F8F5EF" strokeWidth={strokeWidth * 1.2} strokeLinecap="round" />
              <circle cx="50" cy="70" r="2.5" fill="#F8F5EF" />
            </>
          )}
          {verdict === "medium_risk" && (
            <path d="M 38 62 L 50 42 L 62 62 Z" stroke="#F8F5EF" strokeWidth={strokeWidth * 0.8} fill="none" strokeLinejoin="round" />
          )}
          {verdict === "low_risk" && (
            <path d="M 38 56 L 46 65 L 62 46" stroke="#F8F5EF" strokeWidth={strokeWidth * 1.2} fill="none" strokeLinecap="round" strokeLinejoin="round" />
          )}
        </>
      )}

      {variant === "history" && (
        <>
          {/* Clock icon */}
          <circle cx="50" cy="55" r="12" stroke={strokeColor} strokeWidth={strokeWidth * 0.6} fill="none" />
          <line x1="50" y1="55" x2="50" y2="47" stroke={strokeColor} strokeWidth={strokeWidth * 0.6} strokeLinecap="round" />
          <line x1="50" y1="55" x2="56" y2="60" stroke={strokeColor} strokeWidth={strokeWidth * 0.6} strokeLinecap="round" />
        </>
      )}

      {variant === "empty" && (
        <>
          {/* Question mark */}
          <text x="50" y="65" textAnchor="middle" fill={strokeColor} fontSize="28" fontFamily="Fraunces, serif" fontWeight="bold">
            ?
          </text>
        </>
      )}

      {/* Gold accent dot at top */}
      <circle cx="50" cy="8" r="3" fill={strokeColor} />
    </svg>
  );
}
