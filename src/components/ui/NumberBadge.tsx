"use client";

import { useEffect, useState } from "react";

interface NumberBadgeProps {
  phoneNumber: string | undefined;
}

export function NumberBadge({ phoneNumber }: NumberBadgeProps) {
  const [state, setState] = useState<{
    loading: boolean;
    found: boolean;
    count: number;
    error: boolean;
  }>({ loading: false, found: false, count: 0, error: false });

  useEffect(() => {
    if (!phoneNumber) return;
    setState({ loading: true, found: false, count: 0, error: false });

    const controller = new AbortController();
    const encoded = encodeURIComponent(phoneNumber);

    fetch(`/api/check-number/${encoded}`, { signal: controller.signal })
      .then((r) => r.json())
      .then((data) => {
        setState({
          loading: false,
          found: data.found === true,
          count: data.report_count || 0,
          error: false,
        });
      })
      .catch(() => {
        setState({ loading: false, found: false, count: 0, error: true });
      });

    return () => controller.abort();
  }, [phoneNumber]);

  if (!phoneNumber || state.loading || state.error || !state.found) return null;

  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        background: "#8B1E3F22",
        border: "1px solid #8B1E3F55",
        borderRadius: 8,
        padding: "6px 10px",
        marginTop: 8,
      }}
      role="alert"
      aria-live="polite"
    >
      <span style={{ fontSize: "1rem" }}>⚠️</span>
      <span
        style={{
          fontFamily: "Manrope, sans-serif",
          fontSize: "0.8rem",
          color: "#e06080",
          fontWeight: 600,
        }}
      >
        Reported by {state.count} user{state.count !== 1 ? "s" : ""} as scam
      </span>
    </div>
  );
}
