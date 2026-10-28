# PagerDuty AI Gate0 Page3

```
Business Requirements (3/4) — 3rd party only?
  column 1 → PagerDuty AI (Advance) in Microsoft Teams  ← implement
  column 2 → Dynatrace Assist (already the detector)
  column 3 → Splunk AI Assistant (already the log store)
  model name unknown → say so, do not invent one
  cost missing on the tool sheet → ask the vendor, do not type a price
  Group AI / Secure GPT / RAG → this banner says those boxes are not this page
```

| Key point | Detail |
|---|---|
| Slide | Business Requirements (3/4). Eight rows, three vendor columns. |
| Choice | Column 1. The incident already lives in PagerDuty, and the assist is documented in Microsoft Teams. |
| Other two | Kept because ALJ already runs Dynatrace and Splunk. They answer inside their own tool. |
| Cost | No yen figure. The ALJ tool sheet does not print a price. |

## Summary

Fill three known products. Implement PagerDuty AI as a cloud add-on on the pager you already use. Use Dynatrace Assist and the Splunk assistant as the comparison columns, because each one helps only inside its own tool.

## Investigation

| Source | What it shows |
|---|---|
| This slide | Up to three third-party products. Name, vendor URL, outline, model, solution type, pros, cons, cost. |
| Banner | Group AI solutions, document understanding, RAG, and Secure GPT are not required on this page. |
| Form note | If the model name is unknown, leave it and fill it in when the vendor states it. |
| PagerDuty docs | Product name is PagerDuty AI, also labeled Advance. Assistant and status drafts work in Microsoft Teams. Included on the Reliability Platform plan, or sold as an add-on on Professional, Business, and Enterprise. Model providers are in the Advance AI Disclosure. PagerDuty states it does not train those models on customer data. |
| Dynatrace | Generative chat is now Dynatrace Assist, the later name of Davis CoPilot, inside Dynatrace Intelligence. |
| Splunk | Splunk AI Assistant writes and explains searches and can summarize results. Splunk states Azure OpenAI models and Splunk-hosted models. Extra fee is not charged on top of an eligible Cloud or Enterprise subscription. |
| ALJ tool sheet | Dynatrace, Splunk, and PagerDuty are already listed. Splunk’s platform cell says PlaaS/Internal PIC. No prices. |

## Result

Paste column 1 as the solution to implement. Paste columns 2 and 3 so the reviewer can see why they stay in their own tools.

### Row 1 — Name

| Column 1 | Column 2 | Column 3 |
|---|---|---|
| PagerDuty AI (also labeled PagerDuty Advance) | Dynatrace Assist | Splunk AI Assistant |

### Row 2 — Vendor and URL

| Column | Vendor | Product URL |
|---|---|---|
| 1 | PagerDuty | https://support.pagerduty.com/main/docs/pagerduty-advance |
| 2 | Dynatrace | https://www.dynatrace.com/platform/artificial-intelligence/ |
| 3 | Splunk | https://www.splunk.com/en_us/products/splunk-ai-assistant.html |

### Row 3 — Product outline

| Column | Outline |
|---|---|
| 1 | After PagerDuty has opened the incident, a person asks in Microsoft Teams for a summary, starter checks, and a status draft. A bridge can be turned into notes. A person checks the reply before they act. |
| 2 | Inside Dynatrace, a person asks Assist about a problem, the probable cause, and the next check. The answer uses Dynatrace’s own topology and problem data. |
| 3 | Inside Splunk, a person asks in plain language. The assistant writes or explains a search and can summarize the log results. |

### Row 4 — AI model type

| Column | Model |
|---|---|
| 1 | No single public model name. Providers are listed in the PagerDuty Advance AI Disclosure. Fill the exact name when that document is downloaded. |
| 2 | Dynatrace-hosted models, including one tuned for its own query language. No public version string on the product page. |
| 3 | Splunk states Azure OpenAI models and Splunk-hosted models. No public version string. |

### Row 5 — Solution type

| Column | Tick |
|---|---|
| 1 | [X] Entire solution (on premise or cloud based). It is the PagerDuty cloud add-on. |
| 2 | [X] Entire solution (on premise or cloud based). It is chat inside the Dynatrace product. |
| 3 | [X] Other (Explain): assistant inside the Splunk deployment. The ALJ row says PlaaS/Internal PIC, so confirm that deployment is eligible before calling it cloud SaaS. |

### Row 6 — Pros

| Column | Pros |
|---|---|
| 1 | The incident, the call, and the SMS are already in PagerDuty. The Teams assist and the status draft sit on that same incident. PagerDuty states it does not train its models on customer data. |
| 2 | ALJ already uses Dynatrace for application, user, and host signals. Assist can explain a problem without a new detector. |
| 3 | ALJ already uses Splunk for logs. The assistant lets a person ask for a search in plain language. Splunk states no extra fee on an eligible Cloud or Enterprise subscription. |

### Row 7 — Cons

| Column | Cons |
|---|---|
| 1 | The reply can be wrong. A person confirms it before they acknowledge, escalate, or tell stakeholders. It does not replace Dynatrace or Splunk detection, and it does not write the ServiceNow or Silva correlation. |
| 2 | The answer stays in Dynatrace. It does not post the war-room briefing into the Teams incident channel, and it does not place the call or SMS. Whether Assist is in the current contract is not on the tool sheet. |
| 3 | The answer stays in Splunk. It does not know the PagerDuty escalation or the bridge. Eligibility for PlaaS/Internal PIC is unconfirmed. Splunk states some prompts use Azure OpenAI, so security should confirm the data path. |

### Row 8 — Cost

| Column | Cost |
|---|---|
| 1 | No price on the ALJ tool sheet. Included with the PagerDuty Reliability Platform plan, or sold as the Advance add-on on Professional, Business, and Enterprise. Ask PagerDuty whether the current agreement already includes it. |
| 2 | No price on the ALJ tool sheet. Confirm with the Dynatrace agreement whether Assist is included. |
| 3 | No price on the ALJ tool sheet. Splunk states no fee on top of an eligible Cloud or Enterprise subscription. Confirm the Internal PIC deployment qualifies. |

## Data flow map

```
COLUMN 1 (implement)
  [PagerDuty incident] → [Teams ask] → [person confirms] → [act in PagerDuty]

COLUMN 2 (keep as detector chat)
  [Dynatrace problem] → [Dynatrace Assist] → person still carries the finding to the war room

COLUMN 3 (keep as log chat)
  [Splunk logs] → [Splunk AI Assistant] → person still carries the finding to the war room
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/4-pagerduty-ai-gate0-page2/` | Capability ticks and value. This page is the product comparison for that value. |
| `Daily Files/2026-10-28/3-pagerduty-ai-pic1-alj-tools/` | Tool owners and the 24x7 path. |
| `5.sh` | Copy and git one-liners. Review before running. |

## Commands

See [5.sh](5.sh). Do not commit or push until you ask for that.
