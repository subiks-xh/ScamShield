import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "./globals.css";
import { AppShell } from "@/components/layout/AppShell";

export const metadata: Metadata = {
  title: "ScamShield — AI Scam Call Detector",
  description:
    "Detect AI voice-cloning scam calls in real time using two independent signals: voice authenticity and scam content analysis.",
  manifest: "/manifest.json",
  icons: {
    icon: "/shield-icon.png",
    apple: "/shield-icon.png",
  },
  openGraph: {
    title: "ScamShield",
    description: "Protect yourself from AI voice-cloning scam calls",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#0B1D3A",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,300..900;1,9..144,300..900&family=Manrope:wght@400;500;600;700;800&family=IBM+Plex+Mono:wght@400;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <AppShell>{children}</AppShell>
      </body>
    </html>
  );
}
