# Pic — PII Prevent Before Import

## Decision

```
Important data NOT in Dynatrace yet
  │
  ├─ Wait for import then scrub?
  │     → Late — PII already stored
  │
  └─ Use keyword list as gates NOW
        App deny → OneAgent mask → OpenPipeline → fake test → weekly scan
```

## Data flow

```
App JSON
  → scrub blocklist keys
  → OneAgent *** 
  → OpenPipeline remove/mask
  → Grail
  → DQL scan when real traffic starts
```
