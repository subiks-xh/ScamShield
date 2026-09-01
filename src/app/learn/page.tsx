"use client";

import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { QUIZ_QUESTIONS, SCAM_PATTERNS } from "@/lib/constants";

function ScamPatternCard({ pattern }: { pattern: (typeof SCAM_PATTERNS)[0] }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div
      className="card"
      style={{ marginBottom: 12, cursor: "pointer" }}
      onClick={() => setExpanded(!expanded)}
      role="button"
      tabIndex={0}
      aria-expanded={expanded}
      onKeyDown={(e) => e.key === "Enter" && setExpanded(!expanded)}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 12,
          justifyContent: "space-between",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <span style={{ fontSize: "1.8rem", lineHeight: 1 }}>{pattern.emoji}</span>
          <h3
            style={{
              fontFamily: "Fraunces, Georgia, serif",
              fontSize: "1rem",
              fontWeight: 700,
              color: "#F8F5EF",
              margin: 0,
            }}
          >
            {pattern.title}
          </h3>
        </div>
        <span style={{ color: "#C9A227", fontSize: "0.9rem", flexShrink: 0 }}>
          {expanded ? "▲" : "▼"}
        </span>
      </div>

      {expanded && (
        <div style={{ marginTop: 14, paddingTop: 14, borderTop: "1px solid #1e3a6e" }}>
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.875rem",
              color: "#c8c5bf",
              margin: "0 0 14px 0",
              lineHeight: 1.6,
            }}
          >
            {pattern.description}
          </p>

          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.78rem",
              color: "#C9A227",
              fontWeight: 600,
              margin: "0 0 8px 0",
              textTransform: "uppercase",
              letterSpacing: "0.05em",
            }}
          >
            Warning Signs
          </p>
          <ul style={{ margin: 0, padding: 0, listStyle: "none" }}>
            {pattern.warningSigns.map((sign, i) => (
              <li
                key={i}
                style={{
                  fontFamily: "Manrope, sans-serif",
                  fontSize: "0.875rem",
                  color: "#c8c5bf",
                  padding: "4px 0",
                  display: "flex",
                  alignItems: "flex-start",
                  gap: 8,
                }}
              >
                <span style={{ color: "#8B1E3F", flexShrink: 0, marginTop: 2 }}>▶</span>
                {sign}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

function QuizSection() {
  const [currentQ, setCurrentQ] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [answered, setAnswered] = useState(false);
  const [score, setScore] = useState(0);
  const [finished, setFinished] = useState(false);
  const [answers, setAnswers] = useState<boolean[]>([]);

  const { settings } = useAppStore();
  const simpleMode = settings.simpleMode;

  const q = QUIZ_QUESTIONS[currentQ];

  const handleSelect = (idx: number) => {
    if (answered) return;
    setSelected(idx);
    setAnswered(true);
    const correct = idx === q.correctIndex;
    if (correct) setScore((s) => s + 1);
    setAnswers((a) => [...a, correct]);
  };

  const handleNext = () => {
    if (currentQ < QUIZ_QUESTIONS.length - 1) {
      setCurrentQ((q) => q + 1);
      setSelected(null);
      setAnswered(false);
    } else {
      setFinished(true);
    }
  };

  const handleReset = () => {
    setCurrentQ(0);
    setSelected(null);
    setAnswered(false);
    setScore(0);
    setFinished(false);
    setAnswers([]);
  };

  if (finished) {
    const pct = Math.round((score / QUIZ_QUESTIONS.length) * 100);
    return (
      <div className="card" style={{ textAlign: "center" }}>
        <div style={{ fontSize: "3rem", marginBottom: 12 }}>
          {pct >= 80 ? "🏆" : pct >= 60 ? "👍" : "📚"}
        </div>
        <h3
          style={{
            fontFamily: "Fraunces, Georgia, serif",
            fontSize: "1.4rem",
            fontWeight: 700,
            color: "#F8F5EF",
            marginBottom: 8,
          }}
        >
          {pct >= 80
            ? "Excellent! You're well-protected."
            : pct >= 60
            ? "Good awareness! Keep learning."
            : "Keep practicing — knowledge is protection."}
        </h3>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "1rem",
            color: "#8899bb",
            marginBottom: 4,
          }}
        >
          You scored{" "}
          <span
            style={{
              fontFamily: "IBM Plex Mono, monospace",
              fontSize: "1.3rem",
              color: pct >= 80 ? "#6db88a" : pct >= 60 ? "#e8b040" : "#e06080",
              fontWeight: 700,
            }}
          >
            {score}/{QUIZ_QUESTIONS.length}
          </span>{" "}
          ({pct}%)
        </p>
        <div
          style={{
            display: "flex",
            gap: 6,
            justifyContent: "center",
            margin: "14px 0",
          }}
        >
          {answers.map((correct, i) => (
            <span key={i} style={{ fontSize: "1.2rem" }}>
              {correct ? "✅" : "❌"}
            </span>
          ))}
        </div>
        <button
          onClick={handleReset}
          className="btn-gold"
          style={{
            padding: simpleMode ? "16px 32px" : "12px 24px",
            fontSize: simpleMode ? "1rem" : "0.875rem",
          }}
        >
          Try Again
        </button>
      </div>
    );
  }

  return (
    <div className="card">
      {/* Progress */}
      <div style={{ display: "flex", gap: 6, marginBottom: 16 }}>
        {QUIZ_QUESTIONS.map((_, i) => (
          <div
            key={i}
            style={{
              flex: 1,
              height: 4,
              borderRadius: 999,
              background:
                i < currentQ
                  ? "#3D6B4C"
                  : i === currentQ
                  ? "#C9A227"
                  : "#1e3a6e",
            }}
          />
        ))}
      </div>

      <p
        style={{
          fontFamily: "Manrope, sans-serif",
          fontSize: "0.75rem",
          color: "#C9A22788",
          textTransform: "uppercase",
          letterSpacing: "0.05em",
          fontWeight: 600,
          marginBottom: 8,
        }}
      >
        Question {currentQ + 1} of {QUIZ_QUESTIONS.length}
      </p>

      <h3
        style={{
          fontFamily: "Fraunces, Georgia, serif",
          fontSize: simpleMode ? "1.2rem" : "1rem",
          fontWeight: 700,
          color: "#F8F5EF",
          margin: "0 0 16px 0",
          lineHeight: 1.4,
        }}
      >
        {q.question}
      </h3>

      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 16 }}>
        {q.options.map((option, idx) => {
          let bg = "#0d1f3d";
          let border = "#1e3a6e";
          let color = "#c8c5bf";

          if (answered) {
            if (idx === q.correctIndex) {
              bg = "#3D6B4C22";
              border = "#3D6B4C";
              color = "#6db88a";
            } else if (idx === selected && idx !== q.correctIndex) {
              bg = "#8B1E3F22";
              border = "#8B1E3F";
              color = "#e06080";
            }
          } else if (idx === selected) {
            bg = "#C9A22722";
            border = "#C9A227";
            color = "#F8F5EF";
          }

          return (
            <button
              key={idx}
              onClick={() => handleSelect(idx)}
              style={{
                padding: simpleMode ? "14px 16px" : "10px 14px",
                background: bg,
                border: `1.5px solid ${border}`,
                borderRadius: 10,
                color,
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1rem" : "0.875rem",
                textAlign: "left",
                cursor: answered ? "default" : "pointer",
                transition: "all 0.2s ease",
                lineHeight: 1.4,
              }}
              aria-pressed={selected === idx}
            >
              <span
                style={{
                  fontFamily: "IBM Plex Mono, monospace",
                  marginRight: 8,
                  opacity: 0.6,
                  fontSize: "0.8rem",
                }}
              >
                {String.fromCharCode(65 + idx)}.
              </span>
              {option}
            </button>
          );
        })}
      </div>

      {answered && (
        <div
          style={{
            background: "#112244",
            border: "1px solid #1e3a6e",
            borderRadius: 10,
            padding: "12px",
            marginBottom: 14,
          }}
        >
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.85rem",
              color: selected === q.correctIndex ? "#6db88a" : "#e8b040",
              margin: 0,
              fontWeight: 600,
              marginBottom: 4,
            }}
          >
            {selected === q.correctIndex ? "✓ Correct!" : "✗ Not quite —"}
          </p>
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.82rem",
              color: "#c8c5bf",
              margin: 0,
              lineHeight: 1.5,
            }}
          >
            {q.explanation}
          </p>
        </div>
      )}

      {answered && (
        <button
          onClick={handleNext}
          className="btn-gold"
          style={{
            width: "100%",
            padding: simpleMode ? "16px" : "12px",
            fontSize: simpleMode ? "1rem" : "0.875rem",
          }}
        >
          {currentQ === QUIZ_QUESTIONS.length - 1 ? "See Results →" : "Next Question →"}
        </button>
      )}
    </div>
  );
}

export default function LearnPage() {
  const { settings } = useAppStore();
  const simpleMode = settings.simpleMode;
  const [activeTab, setActiveTab] = useState<"patterns" | "quiz">("patterns");

  return (
    <main
      style={{
        maxWidth: 480,
        margin: "0 auto",
        padding: "24px 20px 40px",
        minHeight: "100dvh",
      }}
    >
      {/* Header */}
      <div
        style={{
          background: "linear-gradient(135deg, #3B1E54 0%, #4e2970 100%)",
          borderRadius: 16,
          padding: "20px 24px",
          border: "1px solid #C9A22733",
          marginBottom: 20,
        }}
      >
        <h1
          style={{
            fontFamily: "Fraunces, Georgia, serif",
            fontSize: simpleMode ? "1.8rem" : "1.4rem",
            fontWeight: 700,
            color: "#F8F5EF",
            margin: 0,
          }}
        >
          📚 Learn
        </h1>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.8rem",
            color: "#C9A22788",
            margin: "4px 0 0 0",
          }}
        >
          Understand scam patterns and test your awareness
        </p>
      </div>

      {/* Tabs */}
      <div
        style={{
          display: "flex",
          gap: 8,
          marginBottom: 20,
          background: "#112244",
          padding: 6,
          borderRadius: 12,
          border: "1px solid #1e3a6e",
        }}
      >
        {[
          { id: "patterns" as const, label: "🎭 Scam Patterns" },
          { id: "quiz" as const, label: "🧠 Awareness Quiz" },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              flex: 1,
              padding: simpleMode ? "14px" : "10px",
              background:
                activeTab === tab.id
                  ? "linear-gradient(135deg, #C9A227, #e8bc40)"
                  : "transparent",
              border: "none",
              borderRadius: 8,
              color: activeTab === tab.id ? "#0B1D3A" : "#8899bb",
              fontFamily: "Manrope, sans-serif",
              fontSize: simpleMode ? "1rem" : "0.875rem",
              fontWeight: activeTab === tab.id ? 700 : 500,
              cursor: "pointer",
              transition: "all 0.2s ease",
            }}
            aria-pressed={activeTab === tab.id}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      {activeTab === "patterns" && (
        <div>
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: simpleMode ? "1rem" : "0.875rem",
              color: "#8899bb",
              margin: "0 0 16px 0",
              lineHeight: 1.5,
            }}
          >
            These are the most common phone scams targeting families today.
            Tap each one to learn the warning signs.
          </p>
          {SCAM_PATTERNS.map((pattern) => (
            <ScamPatternCard key={pattern.id} pattern={pattern} />
          ))}
        </div>
      )}

      {activeTab === "quiz" && (
        <div>
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: simpleMode ? "1rem" : "0.875rem",
              color: "#8899bb",
              margin: "0 0 16px 0",
              lineHeight: 1.5,
            }}
          >
            Test your scam awareness. These questions cover real scenarios —
            perfect for practicing with a family member.
          </p>
          <QuizSection />
        </div>
      )}
    </main>
  );
}
