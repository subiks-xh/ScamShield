"use client";

import { useEffect, useRef } from "react";

interface AmplitudeBarsProps {
  isRecording: boolean;
  amplitude?: number; // 0-1
  barCount?: number;
}

export function AmplitudeBars({
  isRecording,
  amplitude = 0,
  barCount = 24,
}: AmplitudeBarsProps) {
  const barsRef = useRef<(HTMLDivElement | null)[]>([]);

  useEffect(() => {
    if (!isRecording) {
      barsRef.current.forEach((bar) => {
        if (bar) bar.style.transform = "scaleY(0.08)";
      });
      return;
    }

    let frameId: number;
    let phase = 0;

    function animate() {
      phase += 0.15;
      barsRef.current.forEach((bar, i) => {
        if (!bar) return;
        const wave = Math.sin(phase + (i / barCount) * Math.PI * 3) * 0.4 + 0.4;
        const noise = Math.random() * 0.3;
        const base = 0.08 + amplitude * 0.6;
        const height = Math.min(1, base + wave * 0.3 + noise * amplitude);
        bar.style.transform = `scaleY(${height.toFixed(3)})`;

        // Color shifts with amplitude
        const hue = 40 + amplitude * 20;
        bar.style.background = `hsl(${hue}, 80%, ${50 + amplitude * 20}%)`;
      });
      frameId = requestAnimationFrame(animate);
    }

    frameId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(frameId);
  }, [isRecording, amplitude, barCount]);

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 3,
        height: 60,
      }}
      aria-label={isRecording ? "Recording audio — microphone active" : "Microphone inactive"}
      aria-live="polite"
    >
      {Array.from({ length: barCount }).map((_, i) => (
        <div
          key={i}
          ref={(el) => { barsRef.current[i] = el; }}
          style={{
            width: 4,
            height: 48,
            background: isRecording ? "#C9A227" : "#1e3a6e",
            borderRadius: 999,
            transformOrigin: "center",
            transform: "scaleY(0.08)",
            transition: "background 0.3s ease",
          }}
        />
      ))}
    </div>
  );
}
