"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { AnalysisResult, AppSettings, ProtectedContact } from "@/types";
import { generatePairingCode } from "@/lib/utils";

interface AppStore {
  // Current result (in-memory, not persisted)
  currentResult: AnalysisResult | null;
  setCurrentResult: (result: AnalysisResult | null) => void;

  // History (persisted)
  history: AnalysisResult[];
  addToHistory: (result: AnalysisResult) => void;
  clearHistory: () => void;
  removeFromHistory: (id: string) => void;

  // Settings (persisted)
  settings: AppSettings;
  updateSetting: <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => void;

  // Protected contacts (persisted)
  protectedContacts: ProtectedContact[];
  addContact: (contact: ProtectedContact) => void;
  removeContact: (id: string) => void;

  // Onboarding (persisted)
  onboardingComplete: boolean;
  setOnboardingComplete: (done: boolean) => void;

  // Guardian pairing code (persisted)
  guardianCode: string;
  regenerateGuardianCode: () => void;
}

const DEFAULT_SETTINGS: AppSettings = {
  simpleMode: false,
  darkMode: true,
  autoPlaySample: false,
  ttsEnabled: true,
  guardianLinked: false,
  onboardingComplete: false,
};

export const useAppStore = create<AppStore>()(
  persist(
    (set, get) => ({
      // Current result — not persisted
      currentResult: null,
      setCurrentResult: (result) => set({ currentResult: result }),

      // History
      history: [],
      addToHistory: (result) =>
        set((state) => ({
          history: [result, ...state.history].slice(0, 200), // keep last 200
        })),
      clearHistory: () => set({ history: [] }),
      removeFromHistory: (id) =>
        set((state) => ({
          history: state.history.filter((r) => r.id !== id),
        })),

      // Settings
      settings: DEFAULT_SETTINGS,
      updateSetting: (key, value) =>
        set((state) => ({
          settings: { ...state.settings, [key]: value },
        })),

      // Protected contacts
      protectedContacts: [],
      addContact: (contact) =>
        set((state) => ({
          protectedContacts: [
            ...state.protectedContacts.filter((c) => c.id !== contact.id),
            contact,
          ],
        })),
      removeContact: (id) =>
        set((state) => ({
          protectedContacts: state.protectedContacts.filter((c) => c.id !== id),
        })),

      // Onboarding
      onboardingComplete: false,
      setOnboardingComplete: (done) => set({ onboardingComplete: done }),

      // Guardian pairing
      guardianCode: generatePairingCode(),
      regenerateGuardianCode: () => set({ guardianCode: generatePairingCode() }),
    }),
    {
      name: "scamshield-store",
      storage: createJSONStorage(() =>
        typeof window !== "undefined" ? localStorage : {
          getItem: () => null,
          setItem: () => {},
          removeItem: () => {},
        }
      ),
      partialize: (state) => ({
        history: state.history,
        settings: state.settings,
        protectedContacts: state.protectedContacts,
        onboardingComplete: state.onboardingComplete,
        guardianCode: state.guardianCode,
      }),
    }
  )
);
