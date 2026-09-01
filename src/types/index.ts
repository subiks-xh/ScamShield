export type Verdict = "high_risk" | "medium_risk" | "low_risk";

export interface AnalysisResult {
  id: string;
  transcript: string;
  voiceAuthenticityScore: number;
  contentRiskScore: number;
  verdict: Verdict;
  callerNumber?: string;
  contactName?: string;
  voiceMatchScore?: number;
  languageDetected?: string;
  analysisMethod?: string;
  createdAt: string;
}

export interface ReportedNumber {
  phoneNumber: string;
  reportCount: number;
  lastReportedAt: string;
}

export interface NumberCheckResult {
  found: boolean;
  reportCount?: number;
  lastReportedAt?: string;
}

export interface ProtectedContact {
  id: string;
  name: string;
  relationship?: string;
  hasVoiceSample: boolean;
  createdAt: string;
}

export interface AppSettings {
  simpleMode: boolean;
  darkMode: boolean;
  autoPlaySample: boolean;
  ttsEnabled: boolean;
  guardianPairingCode?: string;
  guardianLinked: boolean;
  onboardingComplete: boolean;
}

export interface WeeklySummary {
  totalAnalyzed: number;
  highRiskCount: number;
  mediumRiskCount: number;
  lowRiskCount: number;
  weekStart: string;
  weekEnd: string;
}

export interface QuizQuestion {
  id: number;
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}

export interface ScamPattern {
  id: string;
  title: string;
  description: string;
  warningSigns: string[];
  category: "voice_cloning" | "grandparent" | "bank" | "otp" | "irs";
  emoji: string;
}
