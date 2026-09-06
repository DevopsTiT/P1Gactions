# Why Phased PII Rollout

```
Why not mask all keys on day 1?
  │
  ├─ Too many rules at once → hard to know what broke
  ├─ Wrong regex → false positives (ops logs go dark)
  ├─ App + OneAgent + OpenPipeline together → unclear which layer worked
  └─ Phased days → small blast radius, prove each layer, then expand
```

| Question | Answer |
| --- | --- |
| Why this rollout table? | Reduce risk while still blocking the **worst PII first** |
| Must you use exact calendar days? | No — treat as **phases** (Pilot → Pipeline → Expand → Prove → Sustain) |
| What if you skip phasing? | One big change can hide failures or break troubleshooting logs |

## Summary

The Day 1–4 / Weekly plan is a **safety sequence**, not bureaucracy. You stop the highest-risk fields first, prove OneAgent and OpenPipeline separately, then widen the key list, then prove with a scan. Weekly checks catch regressions. You do **not** need “Day 1” literally — you need the **order**.

---

## Why each phase exists

| Phase | What you do | Why you need it |
| --- | --- | --- |
| **Day 1 — App top 20** | Stop logging the worst keys (`policyHolder*`, `subscriber*`, bank, phone, email) | Highest privacy risk; app fix is the strongest control |
| **Day 1 — OneAgent (email + 5 rules)** | Capture-time mask on a **small** rule set | Safety net if app still leaks; small set is easy to test |
| **Day 2 — OpenPipeline top 20** | Central mask/remove for same keys | Catches non-OneAgent paths and anything App/OneAgent missed |
| **Day 3 — Full first-wave list** | Expand to all agreed PII keys | Only after the pattern is proven — avoids mass false positives |
| **Day 4 — Verify** | Fake traffic + 24h DQL scan | Proof it works; without this you only *assume* PII is gone |
| **Weekly — R4 scan** | Repeat detection on `C_ALJ_BU_…` | New services/keys appear; prevent silent regression |
| **Skip Related/product keys** | No `contractDate` / premium / product codes yet | Avoid blocking useful ops fields before privacy decides |

---

## What goes wrong if you skip the order

| Shortcut | Risk |
| --- | --- |
| 100 OneAgent rules on day 1 | One bad regex → lots of logs mangled; hard to find which rule |
| OpenPipeline before any test | Masking “works” in UI but you cannot tell App vs Pipeline |
| No Day 4 verify | Real PII may still be in Grail while you think you are done |
| No weekly scan | Next release re-adds `policyHolderName` logging unnoticed |
| Add Related keys immediately | May hide useful non-PII fields; privacy not aligned |

---

## Simple analogy

Think of it like fixing a leaking pipe:

1. Stop the biggest leaks first (top 20 keys)  
2. Put a small filter on the pipe (OneAgent 5 rules)  
3. Put a building filter (OpenPipeline)  
4. Check the floor is dry (verify scan)  
5. Check every week (R4)  

You do not replace every pipe in the building on hour one.

---

## Do you “need” the calendar?

| Need | Do not need |
| --- | --- |
| The **sequence** (pilot → expand → verify → sustain) | Exact “Day 1 / Day 2” labels |
| Small blast radius + proof | Doing App + 100 rules + OpenPipeline in one change window |
| Weekly detection | Adding product/metadata keys in wave 1 |

Minimum viable version of the same idea:

```
1) Top keys in App + few OneAgent rules + test
2) Same keys in OpenPipeline + test
3) Expand key list + 24h scan
4) Weekly scan forever
```

---

## Investigation

User asked why the suggested rollout table is needed; answered as phased risk control for Dynatrace PII prevention.

---

## Result

Keep the rollout **order** because it protects privacy **and** operability. Rename “Day 1–4” to “Phase 1–4” if that is clearer for your team.

---

## Data flow map

```
Phase1 App+OneAgent (top keys) → prove
  → Phase2 OpenPipeline (same keys) → prove
  → Phase3 full first-wave keys
  → Phase4 24h scan
  → Weekly scan (no Related keys until privacy OK)
```

---

## Related files

| File | Purpose |
| --- | --- |
| Prevent steps | `../8-dynatrace-pii-prevent-steps/` |
| OneAgent steps | `../9-oneagent-pii-masking-steps/` |
