"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import { useRouter } from "next/navigation";
import { ShieldEmblem } from "@/components/shield/ShieldEmblem";
import { AmplitudeBars } from "@/components/ui/AmplitudeBars";
import { WeeklySummaryCard } from "@/components/ui/WeeklySummary";
import { NumberBadge } from "@/components/ui/NumberBadge";
import { useAppStore } from "@/store/useAppStore";
import { generateId } from "@/lib/utils";
import type { AnalysisResult } from "@/types";

type RecordState = "idle" | "recording" | "analyzing" | "error";

type SpeechRecognitionEventLike = Event & {
  results: SpeechRecognitionResultList;
};

type SpeechRecognitionLike = {
  continuous: boolean;
  interimResults: boolean;
  lang: string;
  onresult: ((event: SpeechRecognitionEventLike) => void) | null;
  onerror: (() => void) | null;
  onend: (() => void) | null;
  start: () => void;
  stop: () => void;
};

type SpeechRecognitionConstructor = new () => SpeechRecognitionLike;

declare global {
  interface Window {
    SpeechRecognition?: SpeechRecognitionConstructor;
    webkitSpeechRecognition?: SpeechRecognitionConstructor;
  }
}

export default function HomePage() {
  const router = useRouter();
  const { settings, setCurrentResult, addToHistory, protectedContacts } = useAppStore();
  const simpleMode = settings.simpleMode;

  const [recordState, setRecordState] = useState<RecordState>("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [amplitude, setAmplitude] = useState(0);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [callerNumber, setCallerNumber] = useState("");
  const [contactName, setContactName] = useState("");
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [audioQualityMessage, setAudioQualityMessage] = useState("");
  const [liveTranscript, setLiveTranscript] = useState("");
  const [liveTranscriptStatus, setLiveTranscriptStatus] = useState("Not started");
  const [liveRiskScore, setLiveRiskScore] = useState(0);

  const stableTranscriptRef = useRef<string>("");
  const isTranscribingRef = useRef<boolean>(false);
  const pendingUpdateRef = useRef<boolean>(false);
  const requestCountRef = useRef<number>(0);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animFrameRef = useRef<number>(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
      if (timerRef.current) clearInterval(timerRef.current);
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      if (wsRef.current) wsRef.current.close();
    };
  }, []);

  const startAmplitudeTracking = useCallback((stream: MediaStream) => {
    try {
      const audioCtx = new AudioContext();
      const source = audioCtx.createMediaStreamSource(stream);
      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      analyserRef.current = analyser;

      const data = new Uint8Array(analyser.frequencyBinCount);
      let lastMessageTime = 0;
      
      function tick() {
        analyser.getByteFrequencyData(data);
        const avg = data.reduce((a, b) => a + b, 0) / data.length;
        const normalizedAmp = avg / 128;
        setAmplitude(normalizedAmp);
        
        const now = Date.now();
        if (now - lastMessageTime > 1500) {
            if (normalizedAmp < 0.05) {
                setAudioQualityMessage("The recording is too quiet to analyze reliably");
            } else if (normalizedAmp > 0.8) {
                setAudioQualityMessage("There is too much background noise or it's too loud");
            } else {
                setAudioQualityMessage("Audio quality is good");
            }
            lastMessageTime = now;
        }

        animFrameRef.current = requestAnimationFrame(tick);
      }
      tick();
    } catch {
      // AudioContext not supported — silent fallback
    }
  }, []);

  const startRecording = useCallback(async () => {
    setErrorMessage("");
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mimeType = MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
        ? "audio/webm;codecs=opus"
        : MediaRecorder.isTypeSupported("audio/webm")
        ? "audio/webm"
        : MediaRecorder.isTypeSupported("audio/mp4")
        ? "audio/mp4"
        : "audio/ogg";

      const recorder = new MediaRecorder(stream, { mimeType });
      mediaRecorderRef.current = recorder;
      audioChunksRef.current = [];
      setLiveTranscript("");
      setLiveTranscriptStatus("Not started");

      // WebSocket setup
      const wsProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
      const wsUrl = `${wsProtocol}//127.0.0.1:8000/ws/analyze-live`;
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => setLiveTranscriptStatus("Connected (Local AI)");
      ws.onerror = () => setLiveTranscriptStatus("Connection failed");
      ws.onclose = () => setLiveTranscriptStatus("Disconnected");
      
      const sendWsUpdate = () => {
        if (ws.readyState === WebSocket.OPEN && audioChunksRef.current.length > 0) {
          isTranscribingRef.current = true;
          pendingUpdateRef.current = false;
          requestCountRef.current += 1;
          const blob = new Blob(audioChunksRef.current, { type: mimeType });
          console.log(`[DIAGNOSTIC] Sending LIVE Request #${requestCountRef.current} | Cumulative Blob Size: ${blob.size} bytes | Duration ~${audioChunksRef.current.length * 3.5}s`);
          ws.send(blob);
        }
      };

      ws.onmessage = (event) => {
        isTranscribingRef.current = false;
        try {
          const data = JSON.parse(event.data);
          
          if (data.status === "rejected") {
            console.log(`[DIAGNOSTIC] Request rejected by backend (likely corrupted or hallucination). Retaining stable transcript.`);
          } else if (data.transcript !== undefined) {
            const newText = data.transcript.trim();
            // Stable accumulation logic
            if (newText.length >= stableTranscriptRef.current.length) {
              stableTranscriptRef.current = newText;
              setLiveTranscript(newText);
            } else if (newText.length > 0 && stableTranscriptRef.current.length - newText.length < 30) {
              // Allow minor corrections
              stableTranscriptRef.current = newText;
              setLiveTranscript(newText);
            }
          }
          if (data.score !== undefined) {
            setLiveRiskScore(data.score);
          }
        } catch (err) {
          console.error("WS parse error", err);
        }
        
        // If an update was queued while we were transcribing, process it now
        if (pendingUpdateRef.current && mediaRecorderRef.current?.state === "recording") {
           sendWsUpdate();
        }
      };

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          audioChunksRef.current.push(e.data);
          if (!isTranscribingRef.current) {
            sendWsUpdate();
          } else {
            pendingUpdateRef.current = true;
          }
        }
      };

      recorder.onstop = async () => {
        stream.getTracks().forEach((t) => t.stop());
        if (wsRef.current) {
          wsRef.current.close();
          wsRef.current = null;
        }
        if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
        setAmplitude(0);
        setAudioQualityMessage("");
        const blob = new Blob(audioChunksRef.current, { type: mimeType });
        await submitAudio(blob, false);
      };

      recorder.start(3500); // 3.5s cumulative chunk
      setRecordState("recording");
      setRecordingSeconds(0);
      setLiveRiskScore(0);
      stableTranscriptRef.current = "";
      isTranscribingRef.current = false;
      pendingUpdateRef.current = false;
      requestCountRef.current = 0;

      startAmplitudeTracking(stream);

      // Recording timer
      timerRef.current = setInterval(() => {
        setRecordingSeconds((s) => s + 1);
      }, 1000);

    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("Permission") || msg.includes("denied")) {
        setErrorMessage("Microphone permission denied. Please allow microphone access and try again.");
      } else {
        setErrorMessage(`Could not start recording: ${msg}`);
      }
      setRecordState("error");
    }
  }, [startAmplitudeTracking]); // eslint-disable-line react-hooks/exhaustive-deps

  const stopRecording = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (mediaRecorderRef.current?.state === "recording") {
      mediaRecorderRef.current.stop();
    }
  }, []);

  const submitAudio = useCallback(
    async (audioBlob: Blob, isDemo: boolean) => {
      setRecordState("analyzing");

      const controller = new AbortController();
      timeoutRef.current = setTimeout(() => controller.abort(), 30000);

      try {
        const formData = new FormData();
        formData.append("file", audioBlob, isDemo ? "sample_scam.webm" : "recording.webm");
        if (callerNumber.trim()) formData.append("caller_number", callerNumber.trim());
        if (contactName.trim()) formData.append("contact_name", contactName.trim());
        if (isDemo) formData.append("is_demo", "true");

        const res = await fetch("/api/analyze", {
          method: "POST",
          body: formData,
          signal: controller.signal,
        });

        if (timeoutRef.current) clearTimeout(timeoutRef.current);

        if (!res.ok) {
          const errData = await res.json().catch(() => ({}));
          throw new Error(errData.error || `Server error ${res.status}`);
        }

        const data = await res.json();

        const result: AnalysisResult = {
          id: data.id || generateId(),
          transcript: data.transcript || "",
          voiceAuthenticityScore: data.voice_authenticity_score ?? 50,
          contentRiskScore: data.content_risk_score ?? 0,
          verdict: data.verdict || "low_risk",
          callerNumber: data.caller_number || callerNumber || undefined,
          contactName: data.contact_name || contactName || undefined,
          voiceMatchScore: data.voice_match_score ?? undefined,
          languageDetected: data.language_detected || undefined,
          analysisMethod: data.voice_check_method || undefined,
          llmAnalysis: data.llm_analysis || undefined,
          engineSource: data.engine_source || undefined,
          createdAt: new Date().toISOString(),
        };

        // Final authoritative transcript overwrite
        if (data.transcript) {
          setLiveTranscript(data.transcript);
          stableTranscriptRef.current = data.transcript;
        }

        setCurrentResult(result);
        addToHistory(result);
        router.push("/results");
      } catch (err: unknown) {
        if (timeoutRef.current) clearTimeout(timeoutRef.current);
        const msg = err instanceof Error ? err.message : String(err);
        if (msg.includes("aborted") || msg.includes("timeout")) {
          setErrorMessage(
            "Analysis timed out (30s). The backend may be slow or unreachable. Try again or use the demo mode."
          );
        } else {
          setErrorMessage(
            `Analysis failed: ${msg}. Make sure the backend is running, or use the demo mode below.`
          );
        }
        setRecordState("error");
      }
    },
    [callerNumber, contactName, setCurrentResult, addToHistory, router]
  );

  const handleDemo = useCallback(async () => {
    // Create a minimal placeholder blob; backend will use mock data
    const demoBlob = new Blob(["DEMO"], { type: "audio/webm" });
    await submitAudio(demoBlob, true);
  }, [submitAudio]);

  const handleMicButton = useCallback(() => {
    if (recordState === "idle" || recordState === "error") {
      startRecording();
    } else if (recordState === "recording") {
      stopRecording();
    }
  }, [recordState, startRecording, stopRecording]);

  const isRecording = recordState === "recording";
  const isAnalyzing = recordState === "analyzing";

  return (
    <main
      style={{
        maxWidth: 480,
        margin: "0 auto",
        padding: "24px 20px",
        minHeight: "100dvh",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {/* Header */}
      <header style={{ marginBottom: 24 }}>
        <div
          style={{
            background: "linear-gradient(135deg, #3B1E54 0%, #4e2970 100%)",
            borderRadius: 16,
            padding: "20px 24px",
            border: "1px solid #C9A22733",
            display: "flex",
            alignItems: "center",
            gap: 16,
          }}
        >
          <ShieldEmblem variant="home" size={52} animate={false} />
          <div>
            <h1
              style={{
                fontFamily: "Fraunces, Georgia, serif",
                fontSize: simpleMode ? "2rem" : "1.6rem",
                fontWeight: 700,
                color: "#F8F5EF",
                margin: 0,
                lineHeight: 1.1,
              }}
            >
              ScamShield
            </h1>
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1rem" : "0.8rem",
                color: "#C9A227",
                margin: "2px 0 0 0",
                fontWeight: 500,
              }}
            >
              AI scam call detector
            </p>
          </div>
        </div>
      </header>

      {/* Weekly Summary */}
      <WeeklySummaryCard />

      {/* Caller number input */}
      {!simpleMode && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
            <input
              type="tel"
              placeholder="Caller number (optional)"
              value={callerNumber}
              onChange={(e) => setCallerNumber(e.target.value)}
              style={{
                flex: 1,
                background: "#112244",
                border: "1px solid #1e3a6e",
                borderRadius: 10,
                padding: "10px 14px",
                color: "#F8F5EF",
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.875rem",
                outline: "none",
              }}
              aria-label="Enter caller phone number"
            />
          </div>
          {callerNumber.trim() && <NumberBadge phoneNumber={callerNumber.trim()} />}

          {/* Advanced: Protected Contact */}
          {protectedContacts.length > 0 && (
            <button
              onClick={() => setShowAdvanced(!showAdvanced)}
              style={{
                background: "none",
                border: "none",
                color: "#C9A22788",
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.78rem",
                cursor: "pointer",
                padding: "4px 0",
                marginTop: 4,
              }}
            >
              {showAdvanced ? "▲" : "▼"} Protected Contact check
            </button>
          )}

          {showAdvanced && protectedContacts.length > 0 && (
            <select
              value={contactName}
              onChange={(e) => setContactName(e.target.value)}
              style={{
                width: "100%",
                background: "#112244",
                border: "1px solid #1e3a6e",
                borderRadius: 10,
                padding: "10px 14px",
                color: "#F8F5EF",
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.875rem",
                marginTop: 6,
              }}
              aria-label="Select protected contact to voice-match"
            >
              <option value="">No voice match (skip)</option>
              {protectedContacts.map((c) => (
                <option key={c.id} value={c.name}>
                  {c.name} {c.relationship ? `(${c.relationship})` : ""}
                  {!c.hasVoiceSample ? " — no sample" : ""}
                </option>
              ))}
            </select>
          )}
        </div>
      )}

      {/* Main recording area */}
      <div
        style={{
          flex: 1,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 24,
          paddingBottom: 24,
        }}
      >
        {/* Shield + Mic Button */}
        <div style={{ position: "relative", display: "flex", alignItems: "center", justifyContent: "center" }}>
          {/* Background shield */}
          <div style={{ position: "absolute", opacity: 0.15, transform: "scale(1.4)" }}>
            <ShieldEmblem variant="home" size={140} animate={false} />
          </div>

          {/* Pulse rings when recording */}
          {isRecording && (
            <>
              <div
                style={{
                  position: "absolute",
                  width: 120,
                  height: 120,
                  borderRadius: "50%",
                  border: "2px solid #C9A22766",
                  animation: "pulse-ring 1.5s ease-in-out infinite",
                  animationDelay: "0s",
                }}
              />
              <div
                style={{
                  position: "absolute",
                  width: 150,
                  height: 150,
                  borderRadius: "50%",
                  border: "1px solid #C9A22733",
                  animation: "pulse-ring 1.5s ease-in-out infinite",
                  animationDelay: "0.4s",
                }}
              />
            </>
          )}

          {/* Mic / Stop button */}
          <button
            onClick={handleMicButton}
            disabled={isAnalyzing}
            style={{
              width: simpleMode ? 120 : 96,
              height: simpleMode ? 120 : 96,
              borderRadius: "50%",
              border: `3px solid ${isRecording ? "#8B1E3F" : "#C9A227"}`,
              background: isRecording
                ? "linear-gradient(135deg, #8B1E3F, #b5264f)"
                : "linear-gradient(135deg, #C9A227, #e8bc40)",
              cursor: isAnalyzing ? "not-allowed" : "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: simpleMode ? "2.8rem" : "2.2rem",
              position: "relative",
              zIndex: 2,
              transition: "all 0.3s ease",
              boxShadow: isRecording
                ? "0 0 30px #8B1E3F88"
                : "0 0 20px #C9A22766",
              opacity: isAnalyzing ? 0.6 : 1,
            }}
            aria-label={
              isRecording
                ? "Stop recording"
                : isAnalyzing
                ? "Analyzing..."
                : "Start recording to analyze call"
            }
          >
            {isRecording ? "⏹" : isAnalyzing ? "⏳" : "🎙️"}
          </button>
        </div>

        {/* Status text */}
        <div style={{ textAlign: "center" }}>
          {isRecording && (
            <div style={{ textAlign: "center" }}>
              <p
                style={{
                  fontFamily: "Manrope, sans-serif",
                  fontSize: simpleMode ? "1.3rem" : "1rem",
                  color: "#e06080",
                  margin: "0 0 4px 0",
                  fontWeight: 600,
                }}
              >
                ● Recording{" "}
                <span
                  style={{ fontFamily: "IBM Plex Mono, monospace" }}
                >
                  {recordingSeconds}s
                </span>
              </p>
              {audioQualityMessage && (
                  <p
                    style={{
                      fontFamily: "Manrope, sans-serif",
                      fontSize: "0.85rem",
                      color: audioQualityMessage.includes("good") ? "#22c55e" : "#fbbf24",
                      margin: "4px 0 0 0",
                    }}
                  >
                    {audioQualityMessage}
                  </p>
              )}
            </div>
          )}
          {isAnalyzing && (
            <div
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1.3rem" : "1rem",
                color: "#C9A227",
              }}
            >
              <span style={{ animation: "spin-slow 1s linear infinite", display: "inline-block" }}>
                ⚙️
              </span>{" "}
              Analyzing…
            </div>
          )}
          {!isRecording && !isAnalyzing && (
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1.2rem" : "0.95rem",
                color: "#8899bb",
                margin: 0,
                textAlign: "center",
                maxWidth: 260,
              }}
            >
              {simpleMode
                ? "Tap the button and start talking"
                : "Tap to record a call snippet, then tap again to analyze"}
            </p>
          )}
        </div>

        {/* Amplitude bars */}
        {(isRecording || isAnalyzing) && (
          <AmplitudeBars
            isRecording={isRecording}
            amplitude={amplitude}
          />
        )}

        {(isRecording || liveTranscript) && (
          <div
            style={{
              width: "100%",
              maxWidth: 360,
              background: "#112244",
              border: "1px solid #1e3a6e",
              borderRadius: 12,
              padding: "12px 14px",
              boxSizing: "border-box",
            }}
            aria-live="polite"
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                gap: 12,
                color: "#C9A227",
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.75rem",
                fontWeight: 700,
                textTransform: "uppercase",
                letterSpacing: "0.04em",
              }}
            >
              <span>Live transcript preview</span>
              <span style={{ color: liveRiskScore >= 90 ? "#e06080" : liveRiskScore >= 50 ? "#fbbf24" : "#8899bb", fontWeight: 500, textTransform: "none" }}>
                Risk: {liveRiskScore}% | {liveTranscriptStatus}
              </span>
            </div>
            <p
              style={{
                minHeight: 44,
                margin: "8px 0 0",
                color: liveTranscript ? "#F8F5EF" : "#8899bb",
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1rem" : "0.9rem",
                lineHeight: 1.5,
              }}
            >
              {liveTranscript || "Start speaking. Words will appear here while you record."}
            </p>
            <p
              style={{
                margin: 0,
                color: "#66799f",
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.7rem",
              }}
            >
              Powered by local on-device AI.
            </p>
          </div>
        )}

        {/* Error state */}
        {recordState === "error" && (
          <div
            style={{
              background: "#8B1E3F22",
              border: "1px solid #8B1E3F55",
              borderRadius: 12,
              padding: "16px",
              maxWidth: 340,
              textAlign: "center",
            }}
            role="alert"
          >
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.875rem",
                color: "#e06080",
                margin: "0 0 12px 0",
              }}
            >
              {errorMessage}
            </p>
            <button
              onClick={() => setRecordState("idle")}
              className="btn-gold"
              style={{ padding: "10px 24px", fontSize: "0.875rem" }}
            >
              Try Again
            </button>
          </div>
        )}
      </div>

      {/* Demo button */}
      <div style={{ paddingBottom: 16 }}>
        <div
          style={{
            height: 1,
            background: "linear-gradient(90deg, transparent, #1e3a6e, transparent)",
            marginBottom: 16,
          }}
        />
        <button
          onClick={handleDemo}
          disabled={isAnalyzing || isRecording}
          style={{
            width: "100%",
            padding: simpleMode ? "18px" : "14px",
            background: "transparent",
            border: "1.5px solid #C9A22766",
            borderRadius: 12,
            color: "#C9A227",
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1rem" : "0.875rem",
            fontWeight: 600,
            cursor: isAnalyzing || isRecording ? "not-allowed" : "pointer",
            opacity: isAnalyzing || isRecording ? 0.5 : 1,
            transition: "all 0.2s ease",
          }}
          aria-label="Use sample scam call for demo"
        >
          🎭 Use Sample Scam Call Instead
        </button>
        {!simpleMode && (
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.72rem",
              color: "#55667a",
              textAlign: "center",
              margin: "6px 0 0 0",
            }}
          >
            Guaranteed demo — works without mic or network
          </p>
        )}
      </div>
    </main>
  );
}
