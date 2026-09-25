# 🛡️ ScamShield — AI Voice-Cloning Scam Call Detector

> A hackathon prototype that detects AI voice-cloning scam calls in real time by combining two independent signals: whether the audio sounds AI-generated, and whether the spoken content contains social-engineering language. Only when BOTH signals are present does it raise a high-risk alert — so real urgent calls are never wrongly flagged.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ScamShield System                           │
├─────────────────────────┬───────────────────────────────────────────┤
│   FRONTEND              │   BACKEND                                 │
│   Flutter (iOS/Android) │   Python FastAPI                          │
│                         │                                           │
│  ┌───────────────────┐  │  ┌──────────────┐  ┌──────────────────┐  │
│  │  Home Screen      │  │  │  /analyze    │  │  Whisper STT     │  │
│  │  - Mic recording  │──┼─▶│  endpoint    │─▶│  (local, free)   │  │
│  │  - Live WS Stream │  │  └──────┬───────┘  └──────────────────┘  │
│  │  - Amplitude bars │  │         │          ┌──────────────────┐  │
│  └───────────────────┘  │         ├─────────▶│  Voice Auth Check│  │
│  ┌───────────────────┐  │         │          │  (HuggingFace or │  │
│  │  Results Screen   │  │         │          │   librosa fallbk)│  │
│  │  - Shield emblem  │  │         │          └──────────────────┘  │
│  │  - Score bars     │  │         │          ┌──────────────────┐  │
│  │  - Verdict box    │  │         ├─────────▶│  Content Risk    │  │
│  │  - TTS readout    │  │         │          │  (rule-based,    │  │
│  └───────────────────┘  │         │          │   EN+HI+TA)      │  │
│  ┌───────────────────┐  │         │          └──────────────────┘  │
│  │  History          │  │         ▼          ┌──────────────────┐  │
│  │  Settings         │  │  ┌──────────────┐  │  Verdict Logic   │  │
│  │  Learn Hub        │  │  │  Response    │  │  Both>60=HIGH    │  │
│  └───────────────────┘  │  └──────────────┘  └──────────────────┘  │
├─────────────────────────┴───────────────────────────────────────────┤
│   LOCAL STORAGE: Hive / SharedPreferences / Temp Audio Buffers      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
scamshield/                     # Flutter App
├── lib/
│   ├── main.dart               # Entry point & go_router setup
│   ├── screens/                # UI screens (Home, Results, History, etc.)
│   ├── widgets/                # Reusable components (Shield, ScoreBar)
│   ├── services/               # API service, WebSocket logic
│   ├── theme/                  # Colors, fonts, layout tokens
│   └── models/                 # Data classes (AnalysisResult, etc.)
├── pubspec.yaml                # Flutter dependencies
└── android/                    # Android platform code (CallScreeningService)
backend/                        # Python FastAPI Backend
├── main.py                     # Full analysis pipeline & WS live route
├── requirements.txt            # Dependencies
├── reported_numbers.json       # Local scam number database
├── protected_contacts.json     # Voice enrollment features
└── audio_temp/                 # Temp audio files (auto-deleted)
```

---

## 🚀 Setup & Running

### Prerequisites
- Flutter SDK (3.0+)
- Python 3.9+
- Android Studio / Emulator (or physical device)

### Python FastAPI Backend (Required for real analysis)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Flutter Mobile App

```bash
cd scamshield
flutter pub get
flutter run -d android  # Or windows for local desktop testing
```

> **Note**: For Android emulator testing, the app defaults to `http://10.0.2.2:8000` to connect to your local backend. You can override this in `api_service.dart`.

---

## 🔬 Analysis Pipeline

### Signal 1: Voice Authenticity (0–100, higher = more AI-like)
1. **Primary**: HuggingFace `audio-classification` pipeline with deepfake/spoof model
2. **Fallback**: librosa heuristic (Spectral flatness, Pitch variance, MFCC regularity)

### Signal 2: Content Risk (0–100, higher = more scam-like)
Rule-based keyword scanning across Urgency, Money, and Secrecy categories (English, Hindi, Tamil).

### Verdict Logic
```
HIGH_RISK:   Voice ≥ 60 AND Content ≥ 60
MEDIUM_RISK: Voice ≥ 60 OR Content ≥ 60 (not both)
LOW_RISK:    Neither ≥ 60
```

---

## 🛑 Live-Streaming & Webhook Trade-offs

During active microphone recording, the app streams raw PCM audio to the backend (`/ws/analyze-live`) to display a live transcript and risk score on the Home screen. 

**Important Trade-off**: The live streaming loop *only* computes the Content Risk score because running the HuggingFace deepfake voice model every 3.5 seconds is too slow for real-time processing. 

As a result:
- The **Guardian Webhook** (Discord alert) fires dynamically during the live phase if the *Content Risk* score hits ≥ 90. This means it may false-trigger on a real, high-stress family emergency call that uses urgent language. This is a conscious safety-net trade-off for live alerting.
- When you tap **Stop Recording**, the Flutter app performs a final full REST pass (`/analyze`) on the entire audio buffer. This guarantees the **Results Screen** and **History** ALWAYS show the authoritative two-signal verdict (Voice + Content).

---

## 📱 Features

- **Elderly-Friendly Simple Mode** — Larger UI and plain language.
- **Scam Education Hub** — Scam patterns & quiz.
- **Weekly Safety Summary** — Dashboard stats based on local Hive history.
- **Protected Contacts Voice Enrollment** — Saves an MFCC fingerprint locally.
- **Community Number Database** — Report scam numbers directly from results.
- **Multi-language Detection** — Native script and transliterated Hindi/Tamil.

---

## 🚦 Known Limitations
- 📵 **Live phone call interception**: This prototype simulates call audio via microphone input. Real phone call interception on modern Android requires Carrier partnerships or `PROCESS_OUTGOING_CALLS`.
- 🎨 **Guardian Link**: Push notifications are a mockup. Real alerting requires Firebase Cloud Messaging (FCM) or AWS SNS.
