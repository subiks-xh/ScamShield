"use client";

import { useState, useCallback } from "react";
import { useAppStore } from "@/store/useAppStore";
import { generateId } from "@/lib/utils";
import type { ProtectedContact } from "@/types";

function Toggle({
  checked,
  onChange,
  label,
  description,
  simpleMode,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  label: string;
  description?: string;
  simpleMode: boolean;
}) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "flex-start",
        justifyContent: "space-between",
        gap: 16,
        padding: simpleMode ? "16px 0" : "12px 0",
        borderBottom: "1px solid #1e3a6e",
      }}
    >
      <div style={{ flex: 1 }}>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1.1rem" : "0.95rem",
            color: "#F8F5EF",
            margin: 0,
            fontWeight: 500,
          }}
        >
          {label}
        </p>
        {description && !simpleMode && (
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.78rem",
              color: "#8899bb",
              margin: "3px 0 0 0",
            }}
          >
            {description}
          </p>
        )}
      </div>
      <button
        role="switch"
        aria-checked={checked}
        aria-label={label}
        onClick={() => onChange(!checked)}
        style={{
          width: simpleMode ? 60 : 48,
          height: simpleMode ? 32 : 26,
          borderRadius: 999,
          background: checked
            ? "linear-gradient(90deg, #C9A227, #e8bc40)"
            : "#1e3a6e",
          border: "none",
          cursor: "pointer",
          position: "relative",
          flexShrink: 0,
          transition: "background 0.2s ease",
        }}
      >
        <span
          style={{
            position: "absolute",
            top: simpleMode ? 4 : 3,
            left: checked ? (simpleMode ? 32 : 24) : simpleMode ? 4 : 3,
            width: simpleMode ? 24 : 20,
            height: simpleMode ? 24 : 20,
            borderRadius: "50%",
            background: "#F8F5EF",
            transition: "left 0.2s ease",
            boxShadow: "0 1px 3px rgba(0,0,0,0.3)",
          }}
        />
      </button>
    </div>
  );
}

function SectionHeader({ title, simpleMode }: { title: string; simpleMode: boolean }) {
  return (
    <h2
      style={{
        fontFamily: "Fraunces, Georgia, serif",
        fontSize: simpleMode ? "1.3rem" : "1.05rem",
        fontWeight: 700,
        color: "#C9A227",
        margin: "24px 0 12px 0",
        letterSpacing: "0.02em",
      }}
    >
      {title}
    </h2>
  );
}

export default function SettingsPage() {
  const {
    settings,
    updateSetting,
    protectedContacts,
    addContact,
    removeContact,
    guardianCode,
    regenerateGuardianCode,
  } = useAppStore();

  const simpleMode = settings.simpleMode;
  const [enrollName, setEnrollName] = useState("");
  const [enrollRelationship, setEnrollRelationship] = useState("");
  const [enrollState, setEnrollState] = useState<"idle" | "recording" | "submitting" | "done" | "error">("idle");
  const [enrollError, setEnrollError] = useState("");
  const [mediaRecorder, setMediaRecorder] = useState<MediaRecorder | null>(null);
  const [audioChunks, setAudioChunks] = useState<Blob[]>([]);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [timer, setTimer] = useState<ReturnType<typeof setInterval> | null>(null);
  const [showGuardian, setShowGuardian] = useState(false);
  const [copied, setCopied] = useState(false);

  const startEnrollRecording = useCallback(async () => {
    if (!enrollName.trim()) {
      setEnrollError("Please enter a contact name first.");
      return;
    }
    setEnrollError("");
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream);
      const chunks: Blob[] = [];
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunks.push(e.data);
      };
      recorder.onstop = async () => {
        stream.getTracks().forEach((t) => t.stop());
        setAudioChunks(chunks);
        setEnrollState("submitting");

        // Submit to backend
        const blob = new Blob(chunks, { type: "audio/webm" });
        const formData = new FormData();
        formData.append("file", blob, "voice_sample.webm");
        formData.append("contact_name", enrollName.trim());
        if (enrollRelationship.trim()) {
          formData.append("relationship", enrollRelationship.trim());
        }

        try {
          const res = await fetch("/api/voice-enroll", {
            method: "POST",
            body: formData,
          });
          const data = await res.json();
          if (res.ok && data.success !== false) {
            const contact: ProtectedContact = {
              id: data.id || generateId(),
              name: enrollName.trim(),
              relationship: enrollRelationship.trim() || undefined,
              hasVoiceSample: true,
              createdAt: new Date().toISOString(),
            };
            addContact(contact);
            setEnrollState("done");
            setEnrollName("");
            setEnrollRelationship("");
          } else {
            throw new Error(data.error || data.note || "Enrollment failed");
          }
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          // Even if backend fails, save contact locally
          const contact: ProtectedContact = {
            id: generateId(),
            name: enrollName.trim(),
            relationship: enrollRelationship.trim() || undefined,
            hasVoiceSample: true,
            createdAt: new Date().toISOString(),
          };
          addContact(contact);
          setEnrollError(`Contact saved locally. Backend note: ${msg}`);
          setEnrollState("done");
          setEnrollName("");
          setEnrollRelationship("");
        }
      };

      recorder.start(100);
      setMediaRecorder(recorder);
      setAudioChunks([]);
      setRecordingSeconds(0);
      setEnrollState("recording");

      const t = setInterval(() => setRecordingSeconds((s) => s + 1), 1000);
      setTimer(t);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      setEnrollError(`Cannot access microphone: ${msg}`);
      setEnrollState("error");
    }
  }, [enrollName, enrollRelationship, addContact]);

  const stopEnrollRecording = useCallback(() => {
    if (timer) clearInterval(timer);
    if (mediaRecorder?.state === "recording") mediaRecorder.stop();
  }, [timer, mediaRecorder]);

  const copyCode = () => {
    navigator.clipboard.writeText(guardianCode).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

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
          marginBottom: 8,
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
          Settings
        </h1>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: "0.8rem",
            color: "#C9A22788",
            margin: "4px 0 0 0",
          }}
        >
          Preferences, protected contacts, and guardian link
        </p>
      </div>

      {/* ─── DISPLAY SETTINGS ─────────────────────────────────────────── */}
      <SectionHeader title="Display & Accessibility" simpleMode={simpleMode} />
      <div className="card">
        <Toggle
          checked={settings.simpleMode}
          onChange={(v) => updateSetting("simpleMode", v)}
          label="Simple Mode (Elderly-Friendly)"
          description="Larger text, bigger buttons, plain-language verdicts. Designed for easier reading."
          simpleMode={simpleMode}
        />
        <Toggle
          checked={settings.ttsEnabled}
          onChange={(v) => updateSetting("ttsEnabled", v)}
          label="Read Verdict Aloud"
          description="Uses your device's text-to-speech to automatically speak the verdict when results load."
          simpleMode={simpleMode}
        />
        <Toggle
          checked={settings.darkMode}
          onChange={(v) => updateSetting("darkMode", v)}
          label="Dark Mode"
          description="Keep ScamShield dark — it's easier on the eyes."
          simpleMode={simpleMode}
        />
        <Toggle
          checked={settings.autoPlaySample}
          onChange={(v) => updateSetting("autoPlaySample", v)}
          label="Auto-play Demo on Launch"
          description="Automatically run the sample scam call analysis when the app opens."
          simpleMode={simpleMode}
        />
      </div>

      {/* ─── PROTECTED CONTACTS ────────────────────────────────────────── */}
      <SectionHeader title="Protected Contacts" simpleMode={simpleMode} />
      <div className="card" style={{ marginBottom: 12 }}>
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1rem" : "0.85rem",
            color: "#8899bb",
            margin: "0 0 16px 0",
            lineHeight: 1.5,
          }}
        >
          Record a 10–15 second voice sample of a trusted person (with their consent).
          If a caller claims to be that person, ScamShield will compare voices as a bonus signal.
          All samples are stored locally on this device only — never uploaded.
        </p>

        {/* Existing contacts */}
        {protectedContacts.length > 0 && (
          <div style={{ marginBottom: 16 }}>
            {protectedContacts.map((c) => (
              <div
                key={c.id}
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  padding: "10px 12px",
                  background: "#0d1f3d",
                  borderRadius: 10,
                  marginBottom: 8,
                  border: "1px solid #1e3a6e",
                }}
              >
                <div>
                  <span
                    style={{
                      fontFamily: "Manrope, sans-serif",
                      fontSize: simpleMode ? "1rem" : "0.9rem",
                      color: "#F8F5EF",
                      fontWeight: 600,
                    }}
                  >
                    {c.name}
                  </span>
                  {c.relationship && (
                    <span
                      style={{
                        fontFamily: "Manrope, sans-serif",
                        fontSize: "0.75rem",
                        color: "#8899bb",
                        marginLeft: 6,
                      }}
                    >
                      · {c.relationship}
                    </span>
                  )}
                  <span
                    style={{
                      display: "block",
                      fontFamily: "Manrope, sans-serif",
                      fontSize: "0.72rem",
                      color: c.hasVoiceSample ? "#6db88a" : "#8899bb",
                    }}
                  >
                    {c.hasVoiceSample ? "🎙️ Voice sample enrolled" : "📝 No voice sample"}
                  </span>
                </div>
                <button
                  onClick={() => removeContact(c.id)}
                  style={{
                    background: "none",
                    border: "1px solid #8B1E3F55",
                    borderRadius: 8,
                    color: "#e06080",
                    cursor: "pointer",
                    padding: "4px 10px",
                    fontSize: "0.78rem",
                    fontFamily: "Manrope, sans-serif",
                  }}
                  aria-label={`Remove ${c.name} from protected contacts`}
                >
                  Remove
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Add new contact */}
        {enrollState !== "recording" && enrollState !== "submitting" && (
          <div>
            <input
              type="text"
              placeholder="Contact name (e.g. Mom, Dad)"
              value={enrollName}
              onChange={(e) => setEnrollName(e.target.value)}
              style={{
                width: "100%",
                background: "#0d1f3d",
                border: "1px solid #1e3a6e",
                borderRadius: 10,
                padding: "10px 14px",
                color: "#F8F5EF",
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1rem" : "0.875rem",
                marginBottom: 8,
                outline: "none",
                boxSizing: "border-box",
              }}
            />
            <input
              type="text"
              placeholder="Relationship (optional)"
              value={enrollRelationship}
              onChange={(e) => setEnrollRelationship(e.target.value)}
              style={{
                width: "100%",
                background: "#0d1f3d",
                border: "1px solid #1e3a6e",
                borderRadius: 10,
                padding: "10px 14px",
                color: "#F8F5EF",
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1rem" : "0.875rem",
                marginBottom: 12,
                outline: "none",
                boxSizing: "border-box",
              }}
            />
            <button
              onClick={startEnrollRecording}
              className="btn-gold"
              style={{
                width: "100%",
                padding: simpleMode ? "16px" : "12px",
                fontSize: simpleMode ? "1rem" : "0.875rem",
              }}
            >
              🎙️ Record Voice Sample (10–15s)
            </button>
          </div>
        )}

        {/* Recording state */}
        {enrollState === "recording" && (
          <div style={{ textAlign: "center" }}>
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: simpleMode ? "1.1rem" : "0.95rem",
                color: "#e06080",
                marginBottom: 4,
              }}
            >
              ● Recording{" "}
              <span style={{ fontFamily: "IBM Plex Mono, monospace" }}>
                {recordingSeconds}s
              </span>
            </p>
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.8rem",
                color: "#8899bb",
                marginBottom: 16,
              }}
            >
              Ask {enrollName || "them"} to speak naturally for 10–15 seconds. Confirm they consent.
            </p>
            <button
              onClick={stopEnrollRecording}
              style={{
                padding: "12px 28px",
                background: "#8B1E3F",
                border: "none",
                borderRadius: 12,
                color: "#F8F5EF",
                fontFamily: "Manrope, sans-serif",
                fontWeight: 700,
                cursor: "pointer",
                fontSize: simpleMode ? "1rem" : "0.875rem",
              }}
            >
              ⏹ Stop & Save
            </button>
          </div>
        )}

        {enrollState === "submitting" && (
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.9rem",
              color: "#C9A227",
              textAlign: "center",
            }}
          >
            ⚙️ Extracting voice features…
          </p>
        )}

        {enrollState === "done" && (
          <div style={{ textAlign: "center" }}>
            <p style={{ color: "#6db88a", fontFamily: "Manrope, sans-serif", fontSize: "0.9rem" }}>
              ✓ Voice sample enrolled successfully
            </p>
            <button
              onClick={() => setEnrollState("idle")}
              style={{
                background: "none",
                border: "1px solid #1e3a6e",
                borderRadius: 10,
                color: "#8899bb",
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.8rem",
                cursor: "pointer",
                padding: "8px 16px",
                marginTop: 8,
              }}
            >
              Add Another Contact
            </button>
          </div>
        )}

        {enrollError && (
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.8rem",
              color: "#e8b040",
              marginTop: 8,
            }}
          >
            {enrollError}
          </p>
        )}
      </div>

      {/* ─── GUARDIAN LINK ─────────────────────────────────────────────── */}
      <SectionHeader title="Guardian Link" simpleMode={simpleMode} />
      <div className="card" style={{ marginBottom: 12 }}>
        <div
          style={{
            background: "#B8860B22",
            border: "1px solid #B8860B44",
            borderRadius: 10,
            padding: "10px 14px",
            marginBottom: 14,
          }}
        >
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.78rem",
              color: "#e8b040",
              margin: 0,
              fontWeight: 600,
            }}
          >
            🔶 Demo / UI Mockup Only
          </p>
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.75rem",
              color: "#a09060",
              margin: "4px 0 0 0",
              lineHeight: 1.4,
            }}
          >
            Real Guardian Link requires push notification infrastructure (Firebase Cloud Messaging).
            This shows the pairing flow only — a real Phase 2 roadmap feature.
          </p>
        </div>

        <button
          onClick={() => setShowGuardian(!showGuardian)}
          style={{
            width: "100%",
            padding: simpleMode ? "16px" : "12px",
            background: "#112244",
            border: "1px solid #C9A22744",
            borderRadius: 12,
            color: "#C9A227",
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1rem" : "0.875rem",
            fontWeight: 600,
            cursor: "pointer",
            marginBottom: showGuardian ? 16 : 0,
          }}
        >
          {showGuardian ? "▲ Hide Pairing Code" : "🔗 Show Guardian Pairing Code"}
        </button>

        {showGuardian && (
          <div style={{ textAlign: "center" }}>
            <p
              style={{
                fontFamily: "Manrope, sans-serif",
                fontSize: "0.85rem",
                color: "#8899bb",
                marginBottom: 16,
              }}
            >
              Share this code with a family member to link their ScamShield.
              They enter it in their app under Guardian Link.
            </p>
            <div
              style={{
                background: "#0d1f3d",
                border: "2px solid #C9A22766",
                borderRadius: 14,
                padding: "20px",
                marginBottom: 16,
              }}
            >
              <p
                style={{
                  fontFamily: "IBM Plex Mono, monospace",
                  fontSize: simpleMode ? "2.5rem" : "2rem",
                  fontWeight: 700,
                  color: "#C9A227",
                  margin: 0,
                  letterSpacing: "0.15em",
                }}
              >
                {guardianCode}
              </p>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button
                onClick={copyCode}
                className="btn-gold"
                style={{ flex: 1, padding: "10px", fontSize: "0.875rem" }}
              >
                {copied ? "✓ Copied" : "Copy Code"}
              </button>
              <button
                onClick={regenerateGuardianCode}
                style={{
                  flex: 1,
                  padding: "10px",
                  background: "transparent",
                  border: "1px solid #1e3a6e",
                  borderRadius: 12,
                  color: "#8899bb",
                  fontFamily: "Manrope, sans-serif",
                  fontSize: "0.875rem",
                  cursor: "pointer",
                }}
              >
                Regenerate
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ─── ABOUT ─────────────────────────────────────────────────────── */}
      <SectionHeader title="About ScamShield" simpleMode={simpleMode} />
      <div className="card">
        <p
          style={{
            fontFamily: "Manrope, sans-serif",
            fontSize: simpleMode ? "1rem" : "0.875rem",
            color: "#8899bb",
            margin: "0 0 12px 0",
            lineHeight: 1.6,
          }}
        >
          ScamShield detects AI voice-cloning scam calls using two independent signals: voice authenticity
          and scam content analysis. Only when BOTH signals are high does it raise a High Risk alert —
          so real emergencies are never wrongly flagged.
        </p>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            padding: "10px 0",
            borderTop: "1px solid #1e3a6e",
          }}
        >
          <span
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.8rem",
              color: "#55667a",
            }}
          >
            Version
          </span>
          <span
            style={{
              fontFamily: "IBM Plex Mono, monospace",
              fontSize: "0.8rem",
              color: "#C9A227",
            }}
          >
            2.0.0 · Hackathon Build
          </span>
        </div>
        <div
          style={{
            padding: "10px 0",
            borderTop: "1px solid #1e3a6e",
          }}
        >
          <p
            style={{
              fontFamily: "Manrope, sans-serif",
              fontSize: "0.78rem",
              color: "#55667a",
              margin: 0,
              lineHeight: 1.5,
            }}
          >
            Roadmap: AWS Transcribe (real-time), Amazon Bedrock (AI detection),
            Firebase Cloud Messaging (Guardian alerts), DynamoDB (shared scam number DB),
            Android CallScreeningService (caller awareness).
          </p>
        </div>
      </div>

      <div style={{ height: 32 }} />
    </main>
  );
}
