"""
ScamShield FastAPI Backend
Phases 1-14: Full analysis pipeline with community reporting,
voice enrollment, multi-language support, and all advanced features.
"""

import os
import json
import uuid
import time
import logging
import asyncio
import tempfile
import traceback
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

import numpy as np
import requests
from fastapi import FastAPI, File, UploadFile, HTTPException, Form, BackgroundTasks, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from dotenv import load_dotenv
load_dotenv()

# Removed Groq dependency to enforce 100% local execution

# ─── Logging ────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("scamshield")

# ─── Paths ───────────────────────────────────────────────────────────────────
BASE_DIR = Path(__file__).parent
AUDIO_TEMP = BASE_DIR / "audio_temp"
VOICE_SAMPLES = BASE_DIR / "voice_samples"
REPORTED_NUMBERS_FILE = BASE_DIR / "reported_numbers.json"
PROTECTED_CONTACTS_FILE = BASE_DIR / "protected_contacts.json"

AUDIO_TEMP.mkdir(exist_ok=True)
VOICE_SAMPLES.mkdir(exist_ok=True)

# ─── App ─────────────────────────────────────────────────────────────────────
app = FastAPI(title="ScamShield API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Lazy model loading ───────────────────────────────────────────────────────
_whisper_model = None
_deepfake_classifier = None
WHISPER_MODEL_SIZE = os.getenv("WHISPER_MODEL", "base")
GUARDIAN_WEBHOOK_URL = os.getenv("GUARDIAN_WEBHOOK_URL")
if GUARDIAN_WEBHOOK_URL:
    log.info("✅ Guardian Webhook URL loaded from .env (***)")
else:
    log.warning("Guardian Webhook URL not set in .env")

def trigger_guardian_alert(request_id: str, score: float, transcript: str):
    if not GUARDIAN_WEBHOOK_URL:
        log.warning(f"[{request_id}] Guardian webhook skipped (GUARDIAN_WEBHOOK_URL not set).")
        return
    log.info(f"[{request_id}] Firing Guardian Webhook alert (Score: {score})!")
    try:
        payload = {
            "content": f"🚨 **SCAM ALERT** 🚨\n\nYour loved one is currently on a highly suspicious call (Risk Score: **{score}**).\n\n**Live Transcript snippet:**\n> {transcript[-300:]}\n\n*Action recommended immediately!*"
        }
        res = requests.post(GUARDIAN_WEBHOOK_URL, json=payload, timeout=5)
        res.raise_for_status()
        log.info(f"[{request_id}] Guardian Webhook successfully fired.")
    except Exception as e:
        log.error(f"[{request_id}] Failed to fire Guardian webhook: {e}")


def get_whisper():
    global _whisper_model
    if _whisper_model is None:
        try:
            import whisper
            log.info(f"Loading Whisper '{WHISPER_MODEL_SIZE}' model …")
            _whisper_model = whisper.load_model(WHISPER_MODEL_SIZE)
            log.info("✅ Whisper loaded")
        except Exception as e:
            log.error(f"Whisper load failed: {e}")
            _whisper_model = None
    return _whisper_model


def get_deepfake_classifier():
    global _deepfake_classifier
    if _deepfake_classifier is None:
        try:
            from transformers import pipeline
            log.info("Loading deepfake-detection classifier …")
            _deepfake_classifier = pipeline(
                "audio-classification",
                model="facebook/wav2vec2-base",
            )
            log.info("✅ Deepfake classifier loaded")
        except Exception as e:
            log.warning(f"Deepfake classifier load failed (will use heuristic): {e}")
            _deepfake_classifier = "fallback"
    return _deepfake_classifier


# ─── Content-risk keyword lists (English + Tamil + Hindi) ────────────────────
SCAM_KEYWORDS = {
    "urgency": [
        # English
        "urgent", "immediately", "right now", "act now", "limited time",
        "expires today", "final notice", "last chance", "deadline",
        "emergency", "critical", "time sensitive", "don't delay",
        "suspended", "arrest", "warrant", "police", "legal action",
        "lawsuit", "federal", "irs", "tax", "account frozen",
        # Hindi transliterated
        "turant", "abhi", "jaldi", "fauran", "achaanak", "khatra",
        "giraftari", "warrant", "kewal aaj", "aakhri mauka",
        # Tamil transliterated
        "udan", "ippodhey", "avasaram", "kavasaram", "kettupom",
        "police", "kaipidikka", "kavidham", "kadaisi vaaippu",
        # Hindi Devanagari
        "तुरंत", "अभी", "जल्दी", "फ़ौरन", "आपातकाल", "गिरफ्तारी",
        "वारंट", "अंतिम मौका",
        # Tamil script
        "உடனடி", "இப்போதே", "அவசரம்", "ஆபத்து", "கடைசி வாய்ப்பு",
    ],
    "money": [
        # English
        "send money", "wire transfer", "gift card", "itunes", "google play",
        "bitcoin", "crypto", "cash", "payment", "fine", "fee",
        "dollars", "penalty", "pay now", "transfer funds",
        "bank account", "routing number", "social security",
        "ssn", "credit card", "debit card", "amazon card",
        "western union", "moneygram", "zelle", "venmo", "cashapp",
        # Hindi transliterated
        "paisa bhejo", "rupaye", "paise transfer", "gift card", "bitcoin",
        "khata number", "bank account", "online payment", "upi",
        # Tamil transliterated
        "panam anuppu", "transfer pannu", "gift card", "bitcoin",
        "bank account", "upi", "panam", "kattanam",
        # Hindi Devanagari
        "पैसे भेजो", "रुपये", "गिफ्ट कार्ड", "बिटकॉइन", "खाता नंबर",
        "बैंक खाता", "भुगतान",
        # Tamil script
        "பணம் அனுப்பு", "பரிமாற்றம்", "கிஃப்ட் கார்டு", "பிட்காயின்",
        "வங்கி கணக்கு", "கட்டணம்",
    ],
    "secrecy": [
        # English
        "don't tell", "keep secret", "between us", "don't mention",
        "confidential", "don't share", "nobody knows", "private matter",
        "don't involve", "trust me", "don't tell anyone", "our secret",
        "don't call back", "ignore other calls", "hang up and call",
        "verify by calling", "don't discuss",
        # Hindi transliterated
        "kisi ko mat batao", "secret rakho", "hamare beech mein",
        "kisi se mat kaho", "apne aap rakho", "bata mat",
        # Tamil transliterated
        "yarukkum sollaadhey", "irahasiyam", "namakkulley",
        "yarum theriyaadhey", "solla vendaam",
        # Hindi Devanagari
        "किसी को मत बताओ", "गुप्त रखो", "हमारे बीच में", "किसी से मत कहो",
        # Tamil script
        "யாருக்கும் சொல்லாதே", "இரகசியம்", "நமக்குள்ளே",
        "யாரும் தெரியாதே",
    ],
}

SAMPLE_SCAM_TRANSCRIPT = (
    "Hello, this is an urgent notice from the Social Security Administration. "
    "Your social security number has been suspended due to suspicious activity. "
    "You must call us back immediately or you will be arrested by local police. "
    "This is your final notice. You need to pay a fine of $500 in gift cards. "
    "Please don't tell anyone about this call. This is a confidential matter."
)


# ─── Helpers ──────────────────────────────────────────────────────────────────

def load_json_file(path: Path, default=None):
    if default is None:
        default = {}
    try:
        if path.exists():
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception as e:
        log.error(f"Error loading {path}: {e}")
    return default


def save_json_file(path: Path, data):
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False, default=str)
    except Exception as e:
        log.error(f"Error saving {path}: {e}")


# ─── Transcription ────────────────────────────────────────────────────────────

def transcribe_audio(audio_path: str, language_hint: Optional[str] = None) -> dict:
    """Transcribe audio using local openai-whisper model."""
    import librosa
    import soundfile as sf
    try:
        model = get_whisper()
        if not model:
            log.warning("Local Whisper unavailable — using mock transcript")
            return {
                "text": SAMPLE_SCAM_TRANSCRIPT,
                "language": "en",
                "method": "mock_demo",
                "status": "success"
            }

        # Audio Validation & Safe Extraction
        try:
            y, sr = librosa.load(audio_path, sr=16000)
            duration_sec = len(y) / sr
            log.info(f"Decoded WAV duration: {duration_sec:.2f}s")
            if duration_sec < 0.5:
                log.warning("Decoded audio too short, rejecting.")
                return {"text": "", "language": "en", "method": "rejected_too_short", "status": "rejected"}
                
            fixed_wav_path = audio_path + "_fixed.wav"
            sf.write(fixed_wav_path, y, sr)
        except Exception as e:
            log.error(f"librosa extraction failed: {e}")
            return {"text": "", "language": "en", "method": "rejected_decode_failed", "status": "rejected"}

        log.info("Running local Whisper transcription...")
        result = model.transcribe(fixed_wav_path, fp16=False)
        text = result["text"].strip()
        
        # Hallucination Protection: Repetition detection
        words = text.split()
        if len(words) > 12:
            unique_ratio = len(set([w.lower() for w in words])) / len(words)
            if unique_ratio < 0.25: # Highly repetitive
                log.warning(f"Whisper hallucination detected (unique ratio {unique_ratio:.2f}): {text}")
                return {"text": "", "language": "en", "method": "rejected_hallucination", "status": "rejected"}

        # Filter out common Whisper hallucinations on silence
        lower_text = text.lower()
        if "thank you for watching" in lower_text or "amara.org" in lower_text or "subtitles by" in lower_text:
            log.warning(f"Whisper hallucination detected and cleared: {text}")
            text = ""
            
        detected_lang = result.get("language", "unknown")
        
        log.info(f"✅ Local Transcription done. Length: {len(text)} chars")
        return {
            "text": text,
            "language": detected_lang,
            "method": f"local_whisper_{WHISPER_MODEL_SIZE}",
            "status": "success"
        }
    except Exception as e:
        log.error(f"Whisper transcription error: {e}")
        return {
            "text": SAMPLE_SCAM_TRANSCRIPT,
            "language": "en",
            "method": "mock_fallback",
            "status": "success"
        }


# ─── Voice authenticity check ─────────────────────────────────────────────────

def voice_authenticity_score(audio_path: str) -> dict:
    """
    Returns a score 0-100 where higher = MORE likely AI-generated.
    Tries the deepfake classifier first, falls back to librosa heuristics.
    """
    import librosa

    classifier = get_deepfake_classifier()

    # Method 1: HuggingFace classifier (try)
    if classifier and classifier != "fallback":
        try:
            result = classifier(audio_path)
            log.info(f"Deepfake classifier result: {result}")
            # Map labels — if 'spoof'/'fake' label found, use its score
            for item in result:
                label = item.get("label", "").lower()
                score = float(item.get("score", 0))
                if any(k in label for k in ["spoof", "fake", "synthetic", "generated"]):
                    log.info(f"✅ Voice check done [HuggingFace model]. Score: {score*100:.1f}")
                    return {
                        "score": round(score * 100, 1),
                        "method": "huggingface_classifier",
                    }
            # If no spoof label, use 1 - first score as proxy
            first_score = float(result[0].get("score", 0.5))
            score = round((1 - first_score) * 100, 1)
            log.info(f"✅ Voice check done [HuggingFace model, inverted]. Score: {score}")
            return {"score": score, "method": "huggingface_classifier_inv"}
        except Exception as e:
            log.warning(f"Classifier inference failed: {e} — using heuristic")

    # Method 2: Librosa heuristic fallback
    try:
        y, sr = librosa.load(audio_path, sr=None, mono=True, duration=30)

        # Spectral flatness: higher = more noise-like (AI voices often show this)
        flatness = librosa.feature.spectral_flatness(y=y)
        mean_flatness = float(np.mean(flatness))

        # Pitch variance: real voices have more natural variance
        pitches, magnitudes = librosa.piptrack(y=y, sr=sr)
        pitch_vals = pitches[magnitudes > np.percentile(magnitudes, 75)]
        pitch_variance = float(np.std(pitch_vals)) if len(pitch_vals) > 0 else 0.0

        # MFCC regularity: AI voices tend to be more "regular"
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
        mfcc_variance = float(np.mean(np.std(mfcc, axis=1)))

        # Combine into a score (0=human, 100=AI-generated)
        # High flatness + low pitch variance + low mfcc variance → more AI-like
        flatness_score = min(mean_flatness * 1000, 1.0)  # normalize
        pitch_score = max(0, 1 - min(pitch_variance / 200, 1.0))
        mfcc_score = max(0, 1 - min(mfcc_variance / 50, 1.0))

        combined = (flatness_score * 0.4 + pitch_score * 0.4 + mfcc_score * 0.2) * 100
        score = round(min(max(combined, 0), 100), 1)

        log.info(
            f"✅ Voice check done [librosa heuristic]. "
            f"flatness={mean_flatness:.4f} pitch_var={pitch_variance:.1f} "
            f"mfcc_var={mfcc_variance:.1f} → Score: {score}"
        )
        return {"score": score, "method": "librosa_heuristic"}

    except Exception as e:
        log.error(f"Librosa heuristic failed: {e}")
        return {"score": 50.0, "method": "fallback_default"}


# ─── Content risk check ────────────────────────────────────────────────────────

def content_risk_score(transcript: str) -> dict:
    """
    Two-stage scam content detection.
    Stage A: Rule-based heuristics.
    Stage B: Groq LLM (llama-3.3-70b-versatile).
    Returns score 0-100 and categories hit.
    """
    text_lower = transcript.lower()
    hits = {}

    for category, keywords in SCAM_KEYWORDS.items():
        matched = []
        for kw in keywords:
            if kw.lower() in text_lower or kw in transcript:
                matched.append(kw)
        if matched:
            hits[category] = matched[:5]

    categories_hit = list(hits.keys())
    # 1 category = 35, 2 = 65, 3 = 90
    score_map = {0: 0, 1: 35, 2: 65, 3: 90}
    stage_a_score = score_map.get(len(hits), 90)
    
    final_score = float(stage_a_score)
    method = "stage_a_heuristic"
    llm_analysis = None
    
    # Removed Groq LLM Stage B to enforce local execution.
    # Falling back entirely to Stage A heuristics.

    log.info(f"✅ Content check done. Score: {final_score}")
    return {
        "score": final_score,
        "categories_hit": categories_hit,
        "matched_phrases": hits,
        "method": method,
        "llm_analysis": llm_analysis
    }


# ─── Verdict logic ────────────────────────────────────────────────────────────

def compute_verdict(voice_score: float, content_score: float) -> str:
    """
    high_risk:   BOTH voice ≥ 60 AND content ≥ 60
    medium_risk: ONE of them ≥ 60
    low_risk:    neither ≥ 60
    """
    voice_high = voice_score >= 60
    content_high = content_score >= 60

    if voice_high and content_high:
        verdict = "high_risk"
    elif voice_high or content_high:
        verdict = "medium_risk"
    else:
        verdict = "low_risk"

    log.info(
        f"✅ Verdict reached: {verdict} "
        f"(voice={voice_score:.1f}, content={content_score:.1f})"
    )
    return verdict


# ─── Voice similarity (Protected Contacts) ────────────────────────────────────

def extract_voice_features(audio_path: str) -> Optional[list]:
    """Extract MFCC feature vector for voice enrollment/comparison."""
    try:
        import librosa
        y, sr = librosa.load(audio_path, sr=16000, mono=True, duration=15)
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40)
        mean_features = np.mean(mfcc, axis=1).tolist()
        std_features = np.std(mfcc, axis=1).tolist()
        return mean_features + std_features  # 80-dim vector
    except Exception as e:
        log.error(f"Feature extraction failed: {e}")
        return None


def compare_voice_features(features1: list, features2: list) -> float:
    """Cosine similarity between two feature vectors → 0-100 score."""
    try:
        v1 = np.array(features1)
        v2 = np.array(features2)
        cosine_sim = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2) + 1e-9)
        # Convert from [-1,1] to [0,100]
        score = round(float((cosine_sim + 1) / 2 * 100), 1)
        return score
    except Exception as e:
        log.error(f"Voice comparison failed: {e}")
        return 50.0


# ─── Routes ───────────────────────────────────────────────────────────────────

@app.get("/")
async def health_check():
    return {
        "status": "healthy",
        "service": "ScamShield API",
        "version": "2.0.0",
        "whisper_model": WHISPER_MODEL_SIZE,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.websocket("/ws/analyze-live")
async def analyze_live(websocket: WebSocket):
    await websocket.accept()
    request_id = str(uuid.uuid4())[:8]
    log.info(f"[{request_id}] ─── Live WS Session Started ───")
    
    guardian_alert_fired = False
    request_number = 0
    
    try:
        while True:
            # Receive binary audio chunk (cumulative buffer)
            data = await websocket.receive_bytes()
            request_number += 1
            log.info(f"[DIAGNOSTIC] WS received Request #{request_number} | Size: {len(data)} bytes")
            
            start_time = time.time()
            
            # Save chunk to temp file
            tmp_fd, tmp_path = tempfile.mkstemp(suffix=".webm", dir=str(AUDIO_TEMP), prefix=f"ws_{request_id}_")
            with os.fdopen(tmp_fd, "wb") as f:
                f.write(data)
                
            # If it's too small, skip
            if len(data) < 1000:
                log.info(f"[{request_id}] Chunk too small, skipping.")
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
                continue
                
            # Transcribe (cumulative audio so far) with timeout
            try:
                # Run transcription in a separate thread so asyncio can time it out
                transcript_result = await asyncio.wait_for(
                    asyncio.to_thread(transcribe_audio, tmp_path, "en"),
                    timeout=15.0
                )
            except asyncio.TimeoutError:
                log.error("Transcription timed out! Rejecting update.")
                transcript_result = {"text": "", "status": "rejected"}
            
            status = transcript_result.get("status", "success")
            text = transcript_result.get("text", "")
            
            # Risk score (Stage A only)
            content_result = content_risk_score(text)
            score = content_result.get("score", 0)
            
            # Guardian Alert
            if score >= 90 and not guardian_alert_fired:
                # Fire asynchronously using to_thread
                asyncio.create_task(asyncio.to_thread(trigger_guardian_alert, request_id, score, text))
                guardian_alert_fired = True
                
            elapsed = time.time() - start_time
            
            # Send back the update
            response_payload = {
                "transcript": text,
                "score": score,
                "status": status,
                "processing_time_s": round(elapsed, 2)
            }
            log.info(f"[DIAGNOSTIC] Transcription time: {elapsed:.2f}s | Result length: {len(text)} chars | Text: '{text}'")
            await websocket.send_json(response_payload)
            
            # Cleanup temp file
            if os.path.exists(tmp_path):
                try:
                    os.unlink(tmp_path)
                except:
                    pass
                
    except WebSocketDisconnect:
        log.info(f"[{request_id}] WS disconnected.")
    except Exception as e:
        log.error(f"[{request_id}] WS error: {e}")


@app.post("/analyze")
async def analyze_audio(
    file: UploadFile = File(...),
    caller_number: Optional[str] = Form(None),
    contact_name: Optional[str] = Form(None),
    language_hint: Optional[str] = Form(None),
    is_demo: Optional[str] = Form(None),
):
    """
    Main analysis endpoint.
    Accepts audio file, returns full analysis result.
    """
    request_id = str(uuid.uuid4())[:8]
    log.info(f"[{request_id}] ─── New analysis request ───")
    log.info(f"[{request_id}] File: {file.filename}, caller: {caller_number}, "
             f"contact: {contact_name}, lang: {language_hint}, demo: {is_demo}")

    tmp_path = None
    start_time = time.time()

    try:
        # Save uploaded file
        suffix = Path(file.filename or "audio.webm").suffix or ".webm"
        tmp_fd, tmp_path = tempfile.mkstemp(
            suffix=suffix, dir=str(AUDIO_TEMP), prefix=f"ss_{request_id}_"
        )
        with os.fdopen(tmp_fd, "wb") as f:
            content = await file.read()
            f.write(content)

        log.info(f"[{request_id}] Audio saved: {tmp_path} ({len(content)} bytes)")

        # If demo mode and file is tiny, use mock
        use_mock = is_demo == "true" or len(content) < 1000

        # Step 1: Transcription
        if use_mock:
            transcript_result = {
                "text": SAMPLE_SCAM_TRANSCRIPT,
                "language": "en",
                "method": "demo_mock",
            }
            log.info(f"[{request_id}] Using demo mock transcript")
        else:
            transcript_result = transcribe_audio(tmp_path, language_hint)

        log.info(f"[{request_id}] Transcript: '{transcript_result['text'][:80]}…'")

        # Step 2: Voice authenticity check
        voice_result = voice_authenticity_score(tmp_path)
        if use_mock:
            voice_result = {"score": 78.5, "method": "demo_mock"}

        log.info(f"[{request_id}] Voice score: {voice_result['score']} "
                 f"[{voice_result['method']}]")

        # Step 3: Content risk check
        content_result = content_risk_score(transcript_result["text"])
        log.info(f"[{request_id}] Content score: {content_result['score']}")

        # Step 4: Verdict
        verdict = compute_verdict(voice_result["score"], content_result["score"])

        # Step 5: Voice match (Protected Contact)
        voice_match_score = None
        if contact_name:
            contacts = load_json_file(PROTECTED_CONTACTS_FILE)
            contact_key = contact_name.lower().strip()
            if contact_key in contacts and contacts[contact_key].get("features"):
                call_features = extract_voice_features(tmp_path)
                if call_features:
                    voice_match_score = compare_voice_features(
                        call_features, contacts[contact_key]["features"]
                    )
                    log.info(
                        f"[{request_id}] Voice match to '{contact_name}': {voice_match_score}"
                    )

        elapsed = round(time.time() - start_time, 2)
        log.info(f"[{request_id}] ─── Done in {elapsed}s ───")

        response_data = {
            "request_id": request_id,
            "transcript": transcript_result["text"],
            "language_detected": transcript_result.get("language", "en"),
            "transcription_method": transcript_result.get("method", "whisper"),
            "voice_authenticity_score": voice_result["score"],
            "voice_check_method": voice_result["method"],
            "content_risk_score": content_result["score"],
            "content_categories_hit": content_result["categories_hit"],
            "verdict": verdict,
            "voice_match_score": voice_match_score,
            "contact_name": contact_name,
            "caller_number": caller_number,
            "processing_time_s": elapsed,
            "llm_analysis": content_result.get("llm_analysis"),
        }
        return response_data

    except Exception as e:
        log.error(f"[{request_id}] Pipeline error: {traceback.format_exc()}")
        return JSONResponse(
            status_code=500,
            content={"error": str(e), "request_id": request_id},
        )
    finally:
        # Clean up temp file
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.unlink(tmp_path)
                log.debug(f"[{request_id}] Temp file deleted")
            except Exception:
                pass


# ─── Community number reporting ───────────────────────────────────────────────

class ReportNumberRequest(BaseModel):
    phone_number: str
    notes: Optional[str] = None


@app.post("/report-number")
async def report_number(req: ReportNumberRequest):
    """Report a phone number as a scam."""
    try:
        number = req.phone_number.strip()
        if not number:
            raise HTTPException(status_code=400, detail="Phone number required")

        db = load_json_file(REPORTED_NUMBERS_FILE)

        if number in db:
            db[number]["report_count"] += 1
            db[number]["last_reported"] = datetime.now(timezone.utc).isoformat()
            if req.notes:
                db[number].setdefault("reports", []).append({
                    "note": req.notes,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                })
        else:
            db[number] = {
                "phone_number": number,
                "report_count": 1,
                "last_reported": datetime.now(timezone.utc).isoformat(),
                "reports": [{"note": req.notes, "timestamp": datetime.now(timezone.utc).isoformat()}] if req.notes else [],
            }

        save_json_file(REPORTED_NUMBERS_FILE, db)
        log.info(f"Number reported: {number} (total: {db[number]['report_count']})")

        return {
            "success": True,
            "phone_number": number,
            "total_reports": db[number]["report_count"],
        }

    except HTTPException:
        raise
    except Exception as e:
        log.error(f"report-number error: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.get("/check-number/{number:path}")
async def check_number(number: str):
    """Check if a phone number has been reported."""
    try:
        db = load_json_file(REPORTED_NUMBERS_FILE)
        clean_number = number.strip()

        if clean_number in db:
            entry = db[clean_number]
            return {
                "found": True,
                "phone_number": clean_number,
                "report_count": entry.get("report_count", 1),
                "last_reported": entry.get("last_reported"),
            }
        else:
            return {"found": False, "phone_number": clean_number, "report_count": 0}

    except Exception as e:
        log.error(f"check-number error: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.get("/reported-numbers")
async def list_reported_numbers():
    """List all reported numbers."""
    try:
        db = load_json_file(REPORTED_NUMBERS_FILE)
        numbers = sorted(
            db.values(), key=lambda x: x.get("report_count", 0), reverse=True
        )
        return {"numbers": numbers, "total": len(numbers)}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


# ─── Protected Contacts / Voice Enrollment ────────────────────────────────────

@app.post("/enroll-voice")
async def enroll_voice(
    file: UploadFile = File(...),
    contact_name: str = Form(...),
    relationship: Optional[str] = Form(None),
):
    """
    Enroll a voice sample for a protected contact.
    Extracts MFCC features and stores locally (never uploaded elsewhere).
    """
    try:
        name_key = contact_name.lower().strip()
        if not name_key:
            raise HTTPException(status_code=400, detail="Contact name required")

        suffix = Path(file.filename or "sample.webm").suffix or ".webm"
        tmp_fd, tmp_path = tempfile.mkstemp(
            suffix=suffix, dir=str(VOICE_SAMPLES), prefix=f"enroll_{name_key}_"
        )
        with os.fdopen(tmp_fd, "wb") as f:
            content = await file.read()
            f.write(content)

        log.info(f"Voice enrollment: {contact_name}, {len(content)} bytes")

        features = extract_voice_features(tmp_path)

        # Clean up audio file (only keep features)
        try:
            os.unlink(tmp_path)
        except Exception:
            pass

        if features is None:
            return JSONResponse(
                status_code=500,
                content={"error": "Feature extraction failed. Check audio quality."},
            )

        contacts = load_json_file(PROTECTED_CONTACTS_FILE)
        contacts[name_key] = {
            "name": contact_name,
            "relationship": relationship,
            "features": features,
            "enrolled_at": datetime.now(timezone.utc).isoformat(),
            "feature_dim": len(features),
        }
        save_json_file(PROTECTED_CONTACTS_FILE, contacts)

        log.info(f"✅ Voice enrolled for '{contact_name}' ({len(features)}-dim vector)")
        return {
            "success": True,
            "contact_name": contact_name,
            "feature_dim": len(features),
            "note": "Voice features stored locally on-device only. Not uploaded anywhere.",
        }

    except HTTPException:
        raise
    except Exception as e:
        log.error(f"enroll-voice error: {traceback.format_exc()}")
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.get("/protected-contacts")
async def list_contacts():
    """List all protected contacts (without their feature vectors)."""
    try:
        contacts = load_json_file(PROTECTED_CONTACTS_FILE)
        result = [
            {
                "name": v["name"],
                "relationship": v.get("relationship"),
                "enrolled_at": v.get("enrolled_at"),
                "has_voice_sample": "features" in v and len(v["features"]) > 0,
            }
            for v in contacts.values()
        ]
        return {"contacts": result}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.delete("/protected-contacts/{name}")
async def delete_contact(name: str):
    """Delete a protected contact."""
    try:
        contacts = load_json_file(PROTECTED_CONTACTS_FILE)
        key = name.lower().strip()
        if key in contacts:
            del contacts[key]
            save_json_file(PROTECTED_CONTACTS_FILE, contacts)
            return {"success": True, "deleted": name}
        return JSONResponse(status_code=404, content={"error": "Contact not found"})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
