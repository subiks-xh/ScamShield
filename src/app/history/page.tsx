"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ShieldEmblem } from "@/components/shield/ShieldEmblem";
import { useAppStore } from "@/store/useAppStore";
import { truncateText, formatTimestamp } from "@/lib/utils";
import type { AnalysisResult, Verdict } from "@/types";

const VERDICT_LABELS: Record<Verdict, { label: string; tagClass: string; emoji: string }> = {
  high_risk: { label: "High Risk", tagClass: "tag-high", emoji: "🚨" },
  medium_risk: { label: "Medium Risk", tagClass: "tag-medium", emoji: "⚠️" },
  low_risk: { label: "Low Risk", tagClass: "tag-low", emoji: "✅" },
};

function HistoryCard({
  result,
  onView,
  onDelete,
}: {
  result: AnalysisResult;
  onView: () => void;
  onDelete: () => void;
}) {
  const config = VERDICT_LABELS[result.verdict] || VERDICT_LABELS.low_risk;
  const [confirmDelete, setConfirmDelete] = useState(false);

  return (
    <div
      className="card"
      style={{
        cursor: "pointer",
        transition: "all 0.2s ease",
        position: "relative",
        overflow: "hidden",
      }}
      onClick={onView}
      role="button"
      tabIndex={0}
      aria-label={`View analysis: ${config.label} — ${formatTimestamp(result.createdAt)}`}
      onKeyDown={(e) => e.key === "Enter" && onView()}
    >
      {/* Color accent left bar */}
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          bottom: 0,
          width: 4,
          background:
            result.verdict === "high_risk"
              ? "#8B1E3F"
              : result.verdict === "medium_risk"
              ? "#B8860B"
              : "#3D6B4C",
          borderRadius: "12px 0 0 12px",
        }}
      />

      <div style={{ paddingLeft: 12 }}>
        {/* Header */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: 8,
          }}
        >
          <span className={`tag ${config.tagClass}`}>
            {config.emoji} {config.label}
          </span>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <span
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.72rem",
                color: "#55667a",
              }}
            >
              {formatTimestamp(result.createdAt)}
            </span>
            <button
              onClick={(e) => {
                e.stopPropagation();
                if (confirmDelete) onDelete();
                else setConfirmDelete(true);
              }}
              onBlur={() => setConfirmDelete(false)}
              style={{
                background: "none",
                border: "none",
                cursor: "pointer",
                color: confirmDelete ? "#e06080" : "#55667a",
                fontSize: "0.8rem",
                padding: "2px 6px",
              }}
              aria-label={confirmDelete ? "Confirm delete" : "Delete this record"}
            >
              {confirmDelete ? "✓ Delete?" : "✕"}
            </button>
          </div>
        </div>

        {/* Transcript snippet */}
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.875rem",
            color: "#c8c5bf",
            margin: "0 0 10px 0",
            lineHeight: 1.5,
            fontStyle: "italic",
          }}
        >
          &ldquo;{truncateText(result.transcript, 120)}&rdquo;
        </p>

        {/* Score pills */}
        <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <span
            style={{
              fontFamily: "IBM Plex Mono, monospace",
              fontSize: "0.75rem",
              color: "#8899bb",
            }}
          >
            Voice:{" "}
            <strong
              style={{
                color:
                  result.voiceAuthenticityScore > 60
                    ? "#e06080"
                    : result.voiceAuthenticityScore > 30
                    ? "#e8b040"
                    : "#6db88a",
              }}
            >
              {result.voiceAuthenticityScore.toFixed(0)}%
            </strong>
          </span>
          <span
            style={{
              fontFamily: "IBM Plex Mono, monospace",
              fontSize: "0.75rem",
              color: "#8899bb",
            }}
          >
            Content:{" "}
            <strong
              style={{
                color:
                  result.contentRiskScore > 60
                    ? "#e06080"
                    : result.contentRiskScore > 30
                    ? "#e8b040"
                    : "#6db88a",
              }}
            >
              {result.contentRiskScore.toFixed(0)}%
            </strong>
          </span>
          {result.callerNumber && (
            <span
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.72rem",
                color: "#55667a",
              }}
            >
              📞 {result.callerNumber}
            </span>
          )}
          {result.voiceMatchScore !== undefined && result.voiceMatchScore !== null && (
            <span
              style={{
                fontFamily: "IBM Plex Mono, monospace",
                fontSize: "0.72rem",
                color: "#C9A22788",
              }}
            >
              🔬 Match: {result.voiceMatchScore.toFixed(0)}%
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

export default function HistoryPage() {
  const router = useRouter();
  const { history, clearHistory, removeFromHistory, setCurrentResult, settings } = useAppStore();
  const simpleMode = settings.simpleMode;
  const [showClearConfirm, setShowClearConfirm] = useState(false);

  const handleView = (result: AnalysisResult) => {
    setCurrentResult(result);
    router.push("/results");
  };

  return (
    <main
      style={{
        maxWidth: 480,
        margin: "0 auto",
        padding: "24px 20px",
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
          marginBottom: 24,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div>
          <h1
            style={{
              fontFamily: "Fraunces, Georgia, serif",
              fontSize: simpleMode ? "1.8rem" : "1.4rem",
              fontWeight: 700,
              color: "#F8F5EF",
              margin: 0,
            }}
          >
            History
          </h1>
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.8rem",
              color: "#C9A22788",
              margin: "4px 0 0 0",
            }}
          >
            {history.length} call{history.length !== 1 ? "s" : ""} analyzed
          </p>
        </div>
        {history.length > 0 && (
          <button
            onClick={() => {
              if (showClearConfirm) {
                clearHistory();
                setShowClearConfirm(false);
              } else {
                setShowClearConfirm(true);
              }
            }}
            onBlur={() => setShowClearConfirm(false)}
            style={{
              background: showClearConfirm ? "#8B1E3F44" : "#1e3a6e",
              border: `1px solid ${showClearConfirm ? "#8B1E3F" : "#2a4a7a"}`,
              borderRadius: 10,
              color: showClearConfirm ? "#e06080" : "#8899bb",
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.78rem",
              padding: "8px 14px",
              cursor: "pointer",
              fontWeight: 600,
              transition: "all 0.2s",
            }}
            aria-label={showClearConfirm ? "Confirm clear history" : "Clear all history"}
          >
            {showClearConfirm ? "✓ Confirm Clear" : "🗑 Clear All"}
          </button>
        )}
      </div>

      {/* Content */}
      {history.length === 0 ? (
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            minHeight: 300,
            gap: 20,
            textAlign: "center",
          }}
        >
          <ShieldEmblem variant="empty" size={100} animate={false} />
          <div>
            <h2
              style={{
                fontFamily: "Fraunces, Georgia, serif",
                fontSize: "1.3rem",
                fontWeight: 600,
                color: "#55667a",
                margin: "0 0 8px 0",
              }}
            >
              No calls analyzed yet
            </h2>
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.875rem",
                color: "#3a5070",
                margin: 0,
              }}
            >
              Your analysis history will appear here.
              <br />
              Start by recording or using the demo.
            </p>
          </div>
          <button
            onClick={() => router.push("/")}
            className="btn-gold"
            style={{ padding: "12px 28px", fontSize: "0.9rem" }}
          >
            Go to Home
          </button>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {history.map((result) => (
            <HistoryCard
              key={result.id}
              result={result}
              onView={() => handleView(result)}
              onDelete={() => removeFromHistory(result.id)}
            />
          ))}
        </div>
      )}
    </main>
  );
}
