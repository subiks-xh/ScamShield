import { pgTable, text, integer, timestamp, jsonb, real } from "drizzle-orm/pg-core";

export const analysisHistory = pgTable("analysis_history", {
  id: text("id").primaryKey(),
  transcript: text("transcript").notNull(),
  voiceAuthenticityScore: real("voice_authenticity_score").notNull(),
  contentRiskScore: real("content_risk_score").notNull(),
  verdict: text("verdict").notNull(),
  callerNumber: text("caller_number"),
  contactName: text("contact_name"),
  voiceMatchScore: real("voice_match_score"),
  languageDetected: text("language_detected"),
  analysisMethod: text("analysis_method"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const reportedNumbers = pgTable("reported_numbers", {
  phoneNumber: text("phone_number").primaryKey(),
  reportCount: integer("report_count").notNull().default(1),
  lastReportedAt: timestamp("last_reported_at").defaultNow().notNull(),
  reportDetails: jsonb("report_details"),
});

export const protectedContacts = pgTable("protected_contacts", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  relationship: text("relationship"),
  voiceFeaturesJson: text("voice_features_json"),
  hasVoiceSample: integer("has_voice_sample").notNull().default(0),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const appSettings = pgTable("app_settings", {
  key: text("key").primaryKey(),
  value: text("value").notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
