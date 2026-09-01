"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_ITEMS = [
  { href: "/", label: "Home", icon: "🛡️" },
  { href: "/history", label: "History", icon: "📋" },
  { href: "/learn", label: "Learn", icon: "📚" },
  { href: "/settings", label: "Settings", icon: "⚙️" },
];

export function NavBar() {
  const pathname = usePathname();

  // Don't show on results page (it's a full-screen push)
  if (pathname === "/results") return null;

  return (
    <nav
      style={{
        position: "fixed",
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 100,
        background: "linear-gradient(180deg, #0B1D3Aee 0%, #0B1D3Aff 100%)",
        borderTop: "1px solid #1e3a6e",
        backdropFilter: "blur(12px)",
        WebkitBackdropFilter: "blur(12px)",
        paddingBottom: "env(safe-area-inset-bottom, 0px)",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-around",
          alignItems: "center",
          maxWidth: 480,
          margin: "0 auto",
          padding: "8px 0",
        }}
      >
        {NAV_ITEMS.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 3,
                padding: "8px 16px",
                borderRadius: 12,
                textDecoration: "none",
                background: isActive ? "#C9A22720" : "transparent",
                transition: "all 0.2s ease",
                minWidth: 64,
                minHeight: 52,
                justifyContent: "center",
              }}
              aria-label={item.label}
              aria-current={isActive ? "page" : undefined}
            >
              <span style={{ fontSize: "1.4rem", lineHeight: 1 }}>{item.icon}</span>
              <span
                style={{
                  fontFamily: "Manrope, sans-serif",
                  fontSize: "0.65rem",
                  fontWeight: isActive ? 700 : 500,
                  color: isActive ? "#C9A227" : "#8899bb",
                  letterSpacing: "0.04em",
                  textTransform: "uppercase",
                }}
              >
                {item.label}
              </span>
              {isActive && (
                <div
                  style={{
                    position: "absolute",
                    bottom: 4,
                    width: 4,
                    height: 4,
                    borderRadius: "50%",
                    background: "#C9A227",
                  }}
                />
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
