"use client";

import { useMemo } from "react";
import { useAppStore } from "@/store/useAppStore";
import { computeWeeklySummary } from "@/lib/utils";

export function WeeklySummaryCard() {
  const { history } = useAppStore();
  const summary = useMemo(() => computeWeeklySummary(history), [history]);

  if (summary.totalAnalyzed === 0) return null;

  return (
    <div
      style={{
        background: "linear-gradient(135deg, #1a2f5e 0%, #112244 100%)",
        border: "1px solid #C9A22733",
        borderRadius: 12,
        padding: "14px 18px",
        display: "flex",
        alignItems: "center",
        gap: 12,
        marginBottom: 16,
      }}
    >
      <span style={{ fontSize: "1.3rem" }}>📊</span>
      <div style={{ flex: 1 }}>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.75rem",
            color: "#C9A227",
            margin: 0,
            fontWeight: 600,
            textTransform: "uppercase",
            letterSpacing: "0.06em",
          }}
        >
          This Week
        </p>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.9rem",
            color: "#F8F5EF",
            margin: "2px 0 0 0",
          }}
        >
          {summary.totalAnalyzed} call{summary.totalAnalyzed !== 1 ? "s" : ""} analyzed
          {summary.highRiskCount > 0 && (
            <span style={{ color: "#e06080", marginLeft: 6 }}>
              · {summary.highRiskCount} high-risk 🚨
            </span>
          )}
          {summary.mediumRiskCount > 0 && summary.highRiskCount === 0 && (
            <span style={{ color: "#e8b040", marginLeft: 6 }}>
              · {summary.mediumRiskCount} suspicious ⚠️
            </span>
          )}
        </p>
      </div>
    </div>
  );
}
