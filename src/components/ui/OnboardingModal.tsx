"use client";

import { useState } from "react";
import { ShieldEmblem } from "@/components/shield/ShieldEmblem";

interface OnboardingModalProps {
  onClose: () => void;
}

const SLIDES = [
  {
    emoji: null,
    title: "Welcome to ScamShield",
    body: "ScamShield helps protect you from AI voice-cloning scam calls — one of the fastest-growing threats to families today.",
    useShield: true,
  },
  {
    emoji: "🎭",
    title: "How AI Voice Scams Work",
    body: "Scammers can clone anyone's voice from as little as 3 seconds of audio on social media. They call pretending to be a loved one in distress — and it sounds real.",
    useShield: false,
  },
  {
    emoji: "🔍",
    title: "Two Independent Signals",
    body: "ScamShield checks two things: (1) Does the voice sound AI-generated? (2) Does the content contain scam language? Only when BOTH are present do we raise a High Risk alert — so real emergencies are never wrongly flagged.",
    useShield: false,
  },
];

export function OnboardingModal({ onClose }: OnboardingModalProps) {
  const [slide, setSlide] = useState(0);

  const isLast = slide === SLIDES.length - 1;
  const current = SLIDES[slide];

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 1000,
        background: "rgba(6, 14, 28, 0.92)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 24,
        backdropFilter: "blur(8px)",
      }}
      role="dialog"
      aria-modal="true"
      aria-label="Welcome to ScamShield"
    >
      <div
        style={{
          background: "linear-gradient(145deg, #112244, #0d1f3d)",
          border: "1px solid #C9A22744",
          borderRadius: 20,
          padding: "40px 32px",
          maxWidth: 400,
          width: "100%",
          textAlign: "center",
          animation: "fadeIn 0.3s ease-out",
        }}
      >
        {/* Slide indicator */}
        <div
          style={{
            display: "flex",
            gap: 6,
            justifyContent: "center",
            marginBottom: 32,
          }}
        >
          {SLIDES.map((_, i) => (
            <div
              key={i}
              style={{
                width: i === slide ? 24 : 8,
                height: 4,
                borderRadius: 999,
                background: i === slide ? "#C9A227" : "#1e3a6e",
                transition: "all 0.3s ease",
              }}
            />
          ))}
        </div>

        {/* Icon */}
        {current.useShield ? (
          <div
            style={{ display: "flex", justifyContent: "center", marginBottom: 24 }}
          >
            <ShieldEmblem variant="home" size={80} animate={false} />
          </div>
        ) : (
          <div style={{ fontSize: "3.5rem", marginBottom: 24, lineHeight: 1 }}>
            {current.emoji}
          </div>
        )}

        {/* Title */}
        <h2
          style={{
            fontFamily: "Fraunces, Georgia, serif",
            fontSize: "1.6rem",
            fontWeight: 700,
            color: "#F8F5EF",
            margin: "0 0 16px 0",
            lineHeight: 1.2,
          }}
        >
          {current.title}
        </h2>

        {/* Body */}
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.95rem",
            color: "#c8c5bf",
            margin: "0 0 32px 0",
            lineHeight: 1.6,
          }}
        >
          {current.body}
        </p>

        {/* Buttons */}
        <div style={{ display: "flex", gap: 12 }}>
          <button
            onClick={onClose}
            style={{
              flex: 1,
              padding: "12px",
              background: "transparent",
              color: "#8899bb",
              border: "1px solid #1e3a6e",
              borderRadius: 12,
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.875rem",
              cursor: "pointer",
            }}
            aria-label="Skip onboarding"
          >
            Skip
          </button>
          <button
            onClick={() => {
              if (isLast) onClose();
              else setSlide(slide + 1);
            }}
            style={{
              flex: 2,
              padding: "12px",
              background: "linear-gradient(135deg, #C9A227, #e8bc40)",
              color: "#0B1D3A",
              border: "none",
              borderRadius: 12,
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.875rem",
              fontWeight: 700,
              cursor: "pointer",
            }}
            aria-label={isLast ? "Get started" : "Next slide"}
          >
            {isLast ? "Get Started →" : "Next →"}
          </button>
        </div>
      </div>
    </div>
  );
}
