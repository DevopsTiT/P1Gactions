# Pic — JSON second filter

```
Exported JSON still noisy?
  │
  ├─ Tighten DQL first (seq 32) → re-export
  │
  ├─ Or filter file:
  │     KEEP content matches Value=/AddressKana/phone…
  │     DROP CleansingResult
  │     tools: python script or jq
  │
  └─ For tickets → --redact (no full content)
```
