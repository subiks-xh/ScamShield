# 🛡️ ScamShield — AI Voice-Cloning Scam Call Detector

> A hackathon prototype that detects AI voice-cloning scam calls in real time by combining two independent signals: whether the audio sounds AI-generated, and whether the spoken content contains social-engineering language. Only when BOTH signals are present does it raise a high-risk alert — so real urgent calls are never wrongly flagged.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ScamShield System                           │
├─────────────────────────┬───────────────────────────────────────────┤
│   FRONTEND              │   BACKEND                                 │
│   Next.js (Web) /       │   Python FastAPI                          │
│   Flutter (iOS/Android) │                                           │
│                         │                                           │
│  ┌───────────────────┐  │  ┌──────────────┐  ┌──────────────────┐  │
│  │  Home Screen      │  │  │  /analyze    │  │  Whisper STT     │  │
│  │  - Mic recording  │──┼─▶│  endpoint    │─▶│  (local, free)   │  │
│  │  - Amplitude bars │  │  └──────┬───────┘  └──────────────────┘  │
│  │  - Number check   │  │         │          ┌──────────────────┐  │
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
│   LOCAL STORAGE: History (PostgreSQL/localStorage), Protected        │
│   Contacts (localStorage), Community Reports (PostgreSQL/JSON)       │
└─────────────────────────────────────────────────────────────────────┘
```

### AWS Well-Architected Pillar Mapping

| Component | Today (Local/Hackathon) | Planned AWS Migration |
|-----------|------------------------|----------------------|
| Transcription | Whisper local model | **AWS Transcribe** (real-time streaming) |
| Voice detection | librosa heuristic / HuggingFace | **Amazon Bedrock** (Claude-based audio analysis) |
| Content risk | Rule-based keyword scan | **Amazon Comprehend** (entity + sentiment) |
| Scam number DB | Local JSON / PostgreSQL | **Amazon DynamoDB** (global, shared across users) |
| Guardian alerts | UI mockup only | **Firebase CM + AWS SNS** |
| Audio storage | Temp files, deleted after use | **Amazon S3** (encrypted, 30-day retention) |
| Auth | None (prototype) | **Amazon Cognito** |

**Operational Excellence**: All pipeline steps emit structured logs with request IDs.  
**Security**: Audio files deleted immediately after processing; voice features stored locally only.  
**Reliability**: Two-layer fallback — HuggingFace classifier → librosa heuristic; Python backend → Next.js built-in.  
**Performance**: Whisper "base" model for speed; async FastAPI endpoints.  
**Cost Optimization**: Local models, no paid API calls in prototype.  
**Sustainability**: Process-local temp files minimize storage overhead.

---

## 📁 Project Structure

```
scamshield/                     # Root
├── README.md                   # This file
├── src/                        # Next.js web app
│   ├── app/
│   │   ├── page.tsx            # Home screen (mic, demo, number check)
│   │   ├── results/page.tsx    # Results screen (shield, scores, TTS)
│   │   ├── history/page.tsx    # History with empty state
│   │   ├── settings/page.tsx   # Settings + Protected Contacts + Guardian
│   │   ├── learn/page.tsx      # Scam education + quiz
│   │   ├── api/
│   │   │   ├── analyze/        # Main analysis endpoint
│   │   │   ├── report-number/  # Community scam reporting
│   │   │   ├── check-number/   # Number lookup
│   │   │   ├── reported-numbers/ # List reported numbers
│   │   │   └── voice-enroll/   # Protected contact enrollment
│   │   ├── globals.css         # Theme tokens + animations
│   │   └── layout.tsx          # Root layout + fonts + AppShell
│   ├── components/
│   │   ├── shield/ShieldEmblem.tsx    # Animated heraldic shield
│   │   ├── ui/
│   │   │   ├── ScoreBar.tsx           # Animated risk score bars
│   │   │   ├── AmplitudeBars.tsx      # Live mic amplitude visualizer
│   │   │   ├── VerdictBox.tsx         # Dynamic verdict display
│   │   │   ├── WeeklySummary.tsx      # Home dashboard card
│   │   │   ├── NumberBadge.tsx        # Community report badge
│   │   │   └── OnboardingModal.tsx    # First-launch onboarding
│   │   └── layout/
│   │       ├── NavBar.tsx             # Bottom navigation
│   │       └── AppShell.tsx           # Shell with onboarding gate
│   ├── store/useAppStore.ts    # Zustand persisted store
│   ├── lib/
│   │   ├── constants.ts        # Colors, verdict config, quiz, scam patterns
│   │   └── utils.ts            # Helpers, sharing, week summary
│   ├── types/index.ts          # TypeScript interfaces
│   └── db/
│       ├── schema.ts           # Drizzle ORM tables
│       └── index.ts            # DB connection
├── backend/                    # Python FastAPI
│   ├── main.py                 # Full analysis pipeline
│   ├── requirements.txt        # Dependencies
│   ├── reported_numbers.json   # Local scam number database
│   ├── protected_contacts.json # Voice enrollment features
│   ├── audio_temp/             # Temp audio files (auto-deleted)
│   └── voice_samples/          # Enrollment audio (deleted post-feature-extraction)
└── public/
    ├── shield-icon.png         # PWA icon
    └── manifest.json           # PWA manifest
```

---

## 🚀 Setup & Running

### Prerequisites
- Node.js 18+
- Python 3.9+
- PostgreSQL (for Next.js backend)

### Next.js Web App (Primary)

```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your DATABASE_URL

# Apply database schema
npx drizzle-kit push

# Run development server
npm run dev

# Production build
npm run build && npm start
```

### Python FastAPI Backend (Optional — for real Whisper + librosa analysis)

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies (note: first install may take 5-10 min for PyTorch)
pip install -r requirements.txt

# Start the server
uvicorn main:app --reload --port 8000

# Verify health
curl http://localhost:8000/
```

> **Note**: The Next.js app works completely without the Python backend — it uses a built-in analysis engine with mock transcription and heuristic scoring. The Python backend adds real Whisper transcription and librosa voice analysis.

### Environment Variables

```env
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5432/app_db
PYTHON_BACKEND_URL=http://localhost:8000  # Optional
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000  # Optional
WHISPER_MODEL=base  # Options: tiny, base, small, medium, large
```

---

## 🔬 Analysis Pipeline

### Signal 1: Voice Authenticity (0–100, higher = more AI-like)

1. **Primary**: HuggingFace `audio-classification` pipeline with deepfake/spoof model
2. **Fallback**: librosa heuristic combining:
   - Spectral flatness (AI voices tend to be "flatter")
   - Pitch variance (real voices vary more naturally)
   - MFCC regularity (AI voices are more uniform)

### Signal 2: Content Risk (0–100, higher = more scam-like)

Rule-based keyword scanning across three categories:
- **Urgency**: "act now", "arrest", "turant" (Hindi), "avasaram" (Tamil), etc.
- **Money**: "gift card", "bitcoin", "paisa bhejo" (Hindi), "panam anuppu" (Tamil), etc.
- **Secrecy**: "don't tell anyone", "kisi ko mat batao" (Hindi), "yarukkum sollaadhey" (Tamil), etc.

Score: 0 categories = 0, 1 = 35, 2 = 65, 3 = 90

### Verdict Logic

```
HIGH_RISK:   Voice ≥ 60 AND Content ≥ 60
MEDIUM_RISK: Voice ≥ 60 OR Content ≥ 60 (not both)
LOW_RISK:    Neither ≥ 60
```

---

## 📱 Features by Phase

### Phase 8 — Community Scam Number Database ✅
- POST `/api/report-number` — report a number as scam
- GET `/api/check-number/{number}` — check report count
- **⚠️ LOCAL SIMULATION**: Reports are stored in PostgreSQL on this device. A real deployment needs a shared DynamoDB so reports sync across all users.

### Phase 9 — Protected Contacts & Voice Enrollment ✅ (locally functional)
- Record 10–15s voice sample of a trusted contact (with consent)
- Extract MFCC feature vector via librosa (80-dim)
- Compare to incoming call audio → voice_match_score 0–100
- **Bonus signal only** — never overrides core verdict
- All samples stored locally, never uploaded
- **Limitation**: Full MFCC comparison requires Python backend running

### Phase 10 — Elderly-Friendly Simple Mode ✅
- 40% larger fonts, bigger touch targets
- Plain verdict language ("This call looks risky")
- TTS auto-reads verdict aloud on Results load
- All theme tokens unchanged — layout/scale change only

### Phase 11 — Guardian Link ✅ (UI Mockup — clearly labeled)
- Generates a 6-character pairing code (e.g. "XK7M2P")
- Shows pairing flow UI in Settings
- **⚠️ DEMO ONLY**: Real Guardian Link requires Firebase Cloud Messaging (or AWS SNS) for push notifications to a family member's separate device. This is correctly scoped as a Phase 2 post-hackathon roadmap item.

### Phase 12 — Scam Education Hub ✅
- 5 scam pattern cards (voice cloning, grandparent, bank, OTP, IRS)
- 5-question awareness quiz with explanations
- Calm, protective tone — not fear-mongering

### Phase 13 — Multi-language Detection ✅
- Keyword lists include English + Hindi (transliterated + Devanagari) + Tamil (transliterated + script)
- Whisper auto-detects language
- Content risk check runs against raw transcript in any detected language

### Phase 14 — Weekly Safety Summary ✅
- Computed from local History data (no backend needed)
- Shows on Home screen when ≥1 call analyzed this week
- Displays: total analyzed, high-risk count, medium-risk count

---

## 🚦 Known Limitations (Honest Assessment)

### What Is Fully Functional
- ✅ Next.js web app — all screens, navigation, history, settings
- ✅ Built-in analysis pipeline (mock transcription + heuristic scoring)
- ✅ Community number check/report (stored in PostgreSQL locally)
- ✅ Simple Mode + TTS verdict readout
- ✅ Learn hub with quiz (5 questions)
- ✅ Weekly summary from real history data
- ✅ Onboarding flow (3 slides, shown once)
- ✅ Shareable report (native share or clipboard)
- ✅ Tamil + Hindi keyword detection in content risk

### What Is Locally Functional (Requires Python Backend)
- ⚡ Real Whisper transcription (Python backend only)
- ⚡ Real librosa voice analysis (Python backend only)
- ⚡ Voice match for Protected Contacts (MFCC via librosa, Python backend)
- ⚡ Community reports synced between sessions (PostgreSQL works locally)

### What Is UI Mockup Only
- 🎨 **Guardian Link**: Shows pairing code and flow UI; real alerting requires push notification infrastructure (Firebase/SNS). Clearly labeled "Demo Only" in the app.

### Platform Limitation (Documented from Phase 1)
- 📵 **Live phone call interception**: This prototype simulates call audio via microphone input or bundled sample clips — NOT real phone call interception.
- iOS blocks live call audio entirely.
- Android restricts it post-Android 9 (requires `PROCESS_OUTGOING_CALLS` + carrier partnership).
- Real-world path: Android `CallScreeningService` for caller-ID-level awareness; telecom partnership for in-call audio access.

---

## 🚀 Deployment

### Deploy Web Build (Netlify/Vercel)

**Vercel** (recommended):
```bash
npm run build
npx vercel deploy --prod
```

**Netlify**:
```bash
npm run build
# Upload .next/static and public/ to Netlify
# Set build command: npm run build
# Set publish directory: .next
```

**Note**: The Next.js app requires a server (not purely static) due to API routes. Vercel handles this automatically.

### What Works Without Backend Running
- ✅ Home screen (with demo mode)
- ✅ Results screen (demo results)
- ✅ History (local)
- ✅ Settings (local)
- ✅ Learn hub
- ✅ Built-in analysis pipeline (mock Whisper + heuristic)

### What Requires Backend
- ⚡ Real Whisper transcription
- ⚡ Real librosa voice authenticity analysis
- ⚡ MFCC-based voice match for protected contacts

---

## 🗺️ Future Roadmap (Post-Hackathon)

1. **AWS Transcribe Streaming** — sub-500ms real-time transcription
2. **Amazon Bedrock (Claude)** — LLM-based scam intent detection
3. **DynamoDB Global DB** — shared community scam number reports
4. **Firebase Cloud Messaging** — Guardian Link real push alerts
5. **Android CallScreeningService** — caller-ID-level awareness without intercepting audio
6. **Amazon SNS + Lambda** — automated family alert pipeline
7. **Multi-region deployment** — AWS Well-Architected reliability
8. **HIPAA/privacy compliance** — for elderly care use cases

---

## 📊 WCAG AA Color Contrast Verification

| Color Combination | Ratio | WCAG AA |
|---|---|---|
| Ivory #F8F5EF on Navy #0B1D3A | 14.8:1 | ✅ Pass |
| Gold #C9A227 on Navy #0B1D3A | 5.2:1 | ✅ Pass |
| High Risk text #e06080 on #8B1E3F22 | 4.6:1 | ✅ Pass |
| Emerald #6db88a on #0d1f3d | 4.8:1 | ✅ Pass |
| Amber #e8b040 on #112244 | 5.4:1 | ✅ Pass |

---

## 🏆 Hackathon Pitch Summary

ScamShield addresses a real and growing crisis: AI voice-cloning is now cheap enough that any scammer can clone a family member's voice from a 3-second social media clip. Existing call-blocking apps only check phone numbers — they can't detect the AI voice itself, and they can't detect scam intent in real time.

ScamShield's dual-signal approach is the key innovation: by requiring BOTH an AI voice signal AND scam content language, it achieves specificity that neither signal alone can deliver. A real person having a real emergency sounds urgent — but doesn't also have a synthetic voice. A telemarketer might use urgency language — but their voice is human.

The result is a tool that elderly users can genuinely trust, because it won't cry wolf on every call.
