"use client";

import { NavBar } from "./NavBar";
import { OnboardingModal } from "@/components/ui/OnboardingModal";
import { useAppStore } from "@/store/useAppStore";

interface AppShellProps {
  children: React.ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  const { onboardingComplete, setOnboardingComplete, settings } = useAppStore();

  return (
    <div
      className={settings.simpleMode ? "simple-mode" : ""}
      style={{
        minHeight: "100dvh",
        background: "linear-gradient(160deg, #0B1D3A 0%, #0a1830 50%, #0B1D3A 100%)",
        paddingBottom: 80,
      }}
    >
      {children}
      <NavBar />
      {!onboardingComplete && (
        <OnboardingModal onClose={() => setOnboardingComplete(true)} />
      )}
    </div>
  );
}
