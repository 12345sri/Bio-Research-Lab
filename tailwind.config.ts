import type { Config } from "tailwindcss";

export default {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: { ink: "#1B2140", signal: "#B4122B", omics: "#0B7A78", paper: "#F6F7F9", line: "#E2E5EA", muted: "#5B6275" },
    },
  },
  plugins: [],
} satisfies Config;
