# Prevent JP PII Logs Into Dynatrace

```
Splunk basis (your chat)
  1) Japanese chars in line
  2) JP PII keywords (氏名|住所|電話|…)
  → find where PII appears

Prevent FUTURE ingest into Dynatrace
  App scrub (strongest)
    → OneAgent Sensitive data masking
      → OpenPipeline mask / drop
        → Verify with DQL (same keyword idea)
```

| Key point | Detail |
| --- | --- |
| Basis | Same JP keyword list as the Splunk query |
| Goal | Future logs must not store raw PII in Grail |
| Best order | **App first**, then OneAgent, then OpenPipeline |
| Scan alone | Only finds PII — does **not** prevent ingest |

## Summary

The Splunk query tells you **what patterns** to block. In Dynatrace, prevention means those keywords/values never land as cleartext: stop logging them in the app, mask at OneAgent, and mask/drop again in OpenPipeline. Use a Dynatrace DQL check (JP chars → keywords) only to **verify**.

---

## What the Splunk basis means

| Step in Splunk | Meaning for Dynatrace prevent |
| --- | --- |
| Japanese Unicode filter | Prefer rules that target JP text / JP labels |
| Keyword list (氏名, 住所, 電話, マイナンバー, 口座番号, …) | **Blocklist of PII labels** to mask or omit |
| Stats by index | In Dynatrace: check by **host** / **host group** / log source instead of Splunk index |

### Keyword list (copy for rules)

氏名, 住所, 電話, 生年月日, 郵便番号, メール, メールアドレス, 携帯, 携帯電話, 携帯番号, 固定電話, 電話番号, ファックス, 生年月, 誕生日, 生年, 生月, 生日, 年齢, 性別, 身分証, 身分証明書, マイナンバー, 個人番号, 運転免許, 免許証, パスポート, 旅券, 銀行口座, 口座番号, 銀行コード, 支店コード, クレジットカード, カード番号, カード, 会社

Also keep your JSON keys (`policyHolder*`, `bankAccountNo`, …) as a second wave.

---

## Prevention layers (do in order)

### Layer 1 — App (strongest)

| Action | Why |
| --- | --- |
| Do not log request/response bodies that contain these fields | PII never leaves the app |
| Deny-list the JP keywords + English JSON keys in the logger | Omit key or replace value with `***` |
| Ban full payload dumps in PRD | Biggest leak source |

**Good log:** `policyId`, `result`, `durationMs` only.  
**Bad log:** 氏名 / 口座番号 / `bankAccountNo` with real values.

---

### Layer 2 — OneAgent Sensitive data masking

**UI path:**

`Settings → Collect and capture → Log monitoring → Configure log module → Sensitive data masking`

| Setting | Value |
| --- | --- |
| Scope | Host group (e.g. `C_AGO_…`) or environment |
| Type | STRING |
| Replacement | `***` |

**Idea:** mask values next to JP labels in log text. Example search patterns (adjust in UI; test with **fake** data only):

| Pattern idea | Purpose |
| --- | --- |
| `氏名\s*[:：＝=]\s*\S+` | Mask after 氏名 |
| `住所\s*[:：＝=]\s*.+` | Mask after 住所 |
| `電話番号?\s*[:：＝=]\s*\S+` | Phone |
| `メール(アドレス)?\s*[:：＝=]\s*\S+` | Email |
| `マイナンバー\s*[:：＝=]\s*\S+` | My Number |
| `口座番号\s*[:：＝=]\s*\S+` | Bank account |
| `"bankAccountNo"\s*:\s*"(.*?)"` | JSON English keys |

Add rules in small waves (top keywords first). Enable generic **email** rule if available.

---

### Layer 3 — OpenPipeline (second net at ingest)

For the **Logs** pipeline that receives your hosts:

| Rule | Purpose |
| --- | --- |
| Content mask | Same JP keyword / JSON key regex → `***` |
| Optional drop | Drop entire record if matched **and** privacy says drop (stricter; can lose useful ERROR lines) |
| Prefer mask over drop | Keep ops signal, hide PII values |

Apply to the same host groups that will ingest future logs — **before** turning on noisy sources.

---

### Layer 4 — Verify (not prevent)

After rules are on, prove with **fake** traffic, then scan:

```dql
fetch logs
| filter matchesValue(content, ".*[\\u3000-\\u30FF\\u4E00-\\u9FFF].*")
| filter matchesValue(content, ".*(氏名|住所|電話|生年月日|郵便番号|メール|マイナンバー|口座番号|クレジットカード).*")
| summarize hits = count(), by: { host.name }
| sort hits desc
| limit 50
```

**Pass:** hits are 0, or only `***` / no raw values.  
Full queries: `pii-jp-prevent-verify.dql`

---

## Step-by-step (manual UI)

| Step | Action | Done when |
| --- | --- | --- |
| 1 | Agree keyword blocklist (this JP list + JSON keys) | Privacy/SRE signed off |
| 2 | App: stop logging those fields in PRD | Code review / release |
| 3 | OneAgent: add 5–10 mask rules → fake test | Values show `***` |
| 4 | OpenPipeline: same masks for Logs ingest | Fake line still safe |
| 5 | Expand keyword rules in waves | No false-positive storm |
| 6 | Weekly DQL verify | No raw JP PII rebound |

---

## Do / Don’t

| Do | Don’t |
| --- | --- |
| Prevent **before** Grail | Rely only on Splunk/Dynatrace **scan** after ingest |
| Mask values; keep ERROR level for ops | Drop all Japanese logs (too broad) |
| Test with fake names/accounts | Test with real customer PII |
| Scope by host group | One giant untested regex on day one |

---

## Related files

| File | Purpose |
| --- | --- |
| `pii-jp-prevent-verify.dql` | Post-rule verify scan |
| Earlier JP scan | `5-pii-jp-first-then-keywords` |
| Host `app` tags | Ops filter — separate from PII prevent |
