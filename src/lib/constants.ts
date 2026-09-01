export const COLORS = {
  royalNavy: "#0B1D3A",
  royalPurple: "#3B1E54",
  antiqueGold: "#C9A227",
  ivory: "#F8F5EF",
  deepCrimson: "#8B1E3F",
  amberWarn: "#B8860B",
  deepEmerald: "#3D6B4C",
  surface: "#112244",
  surfaceLight: "#1a2f5e",
} as const;

export const VERDICT_CONFIG = {
  high_risk: {
    label: "HIGH RISK",
    simpleLabel: "This call looks risky",
    color: COLORS.deepCrimson,
    bg: "bg-crimson",
    emoji: "🚨",
    message: "Both signals indicate this is likely an AI-generated scam call.",
    ttsText: "Warning. This call looks very risky. It may be a scam. Do not give any personal information or money.",
  },
  medium_risk: {
    label: "MEDIUM RISK",
    simpleLabel: "This call needs caution",
    color: COLORS.amberWarn,
    bg: "bg-amber",
    emoji: "⚠️",
    message: "One signal is elevated. Proceed with caution.",
    ttsText: "Caution. This call shows some suspicious signs. Be careful before sharing any information.",
  },
  low_risk: {
    label: "LOW RISK",
    simpleLabel: "This call looks safe",
    color: COLORS.deepEmerald,
    bg: "bg-emerald",
    emoji: "✅",
    message: "No significant scam signals detected.",
    ttsText: "This call appears safe. No significant scam signals were detected.",
  },
} as const;

export const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000";

export const QUIZ_QUESTIONS = [
  {
    id: 1,
    question: "You get a call from someone claiming to be your grandchild in trouble. They beg you not to tell anyone. What should you do?",
    options: [
      "Send money right away to help",
      "Hang up and call your grandchild directly on their known number",
      "Keep it secret as they asked",
      "Give them your bank details",
    ],
    correctIndex: 1,
    explanation: "Always verify by calling the person directly on a number you already know. Scammers count on urgency and secrecy to prevent you from checking.",
  },
  {
    id: 2,
    question: "A caller says your bank account is frozen and asks for your OTP to unfreeze it. What is the red flag?",
    options: [
      "They mentioned your bank name",
      "They sound friendly",
      "Banks never ask for OTPs over the phone",
      "They called in the morning",
    ],
    correctIndex: 2,
    explanation: "No legitimate bank, government, or service will ever ask you for an OTP, PIN, or password over the phone. This is always a scam.",
  },
  {
    id: 3,
    question: "Someone claiming to be from the IRS calls and says you'll be arrested unless you pay in gift cards. What should you do?",
    options: [
      "Pay with gift cards to avoid arrest",
      "Ask them to call back later",
      "Hang up — government agencies never demand gift card payments",
      "Give them your address",
    ],
    correctIndex: 2,
    explanation: "The IRS and all government agencies communicate via postal mail first. They never demand immediate payment in gift cards, cryptocurrency, or wire transfers.",
  },
  {
    id: 4,
    question: "How can you tell if a voice on a call might be AI-generated?",
    options: [
      "It speaks very fast",
      "It sounds oddly smooth, lacks natural pauses/breaths, or pitch doesn't vary naturally",
      "It has an accent",
      "It calls at night",
    ],
    correctIndex: 1,
    explanation: "AI voice clones often sound unnaturally smooth, with consistent pitch and fewer natural speech imperfections like breathing pauses or filler words.",
  },
  {
    id: 5,
    question: "Which combination of factors should make you MOST suspicious of a call?",
    options: [
      "The caller is polite and patient",
      "The caller wants to discuss a bill",
      "Urgent demand + request for secrecy + asking for money",
      "The caller knows your name",
    ],
    correctIndex: 2,
    explanation: "The scam trifecta is: urgency (act now!), secrecy (don't tell anyone), and a money request. Any one alone is suspicious; all three together is almost certainly a scam.",
  },
];

export const SCAM_PATTERNS = [
  {
    id: "voice_cloning",
    title: "AI Voice Cloning Scam",
    description: "Scammers use AI to clone a loved one's voice from social media clips, then call you pretending to be them in an emergency.",
    warningSigns: [
      "Voice sounds slightly 'off' or too smooth",
      "Claims to be in immediate danger",
      "Asks you not to contact anyone else",
      "Requests money urgently",
    ],
    category: "voice_cloning" as const,
    emoji: "🤖",
  },
  {
    id: "grandparent",
    title: "Grandparent Scam",
    description: "A caller pretends to be your grandchild (or their lawyer/police officer) claiming they're in trouble and need bail money immediately.",
    warningSigns: [
      "\"Don't tell Mom/Dad\"",
      "Needs money for bail or emergency",
      "Says to keep it secret",
      "Asks for wire transfer or gift cards",
    ],
    category: "grandparent" as const,
    emoji: "👴",
  },
  {
    id: "bank",
    title: "Fake Bank Call",
    description: "Imposters call claiming to be your bank's fraud department, saying your account is compromised and asking you to 'verify' by sharing your PIN or OTP.",
    warningSigns: [
      "Asks for OTP, PIN, or password",
      "Claims your account is frozen",
      "Urgent pressure to act immediately",
      "May already know your account number (from data breaches)",
    ],
    category: "bank" as const,
    emoji: "🏦",
  },
  {
    id: "otp",
    title: "OTP Theft / SIM Swap",
    description: "Scammers who already have your personal info call to get the one-time password sent to your phone, giving them full access to your accounts.",
    warningSigns: [
      "You receive an unexpected OTP",
      "Caller asks you to read it aloud",
      "Claims to be verifying your identity",
      "Creates urgency: 'your account will be locked'",
    ],
    category: "otp" as const,
    emoji: "📱",
  },
  {
    id: "irs",
    title: "Government Impersonator Scam",
    description: "Callers impersonate IRS agents, Social Security Administration, or police, threatening arrest, fines, or benefit suspension unless you pay immediately.",
    warningSigns: [
      "Threat of arrest or legal action",
      "Demands immediate payment",
      "Accepts only gift cards or cryptocurrency",
      "Uses official-sounding titles and case numbers",
    ],
    category: "irs" as const,
    emoji: "🏛️",
  },
];
