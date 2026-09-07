# Prevent JP PII Without App Layer

```
Skip App scrub (per request)
  │
  ├─ Step A  OneAgent Sensitive data masking
  ├─ Step B  OpenPipeline content mask
  └─ Step C  DQL verify (JP chars → keywords)
```

| Key point | Detail |
| --- | --- |
| In scope | OneAgent + OpenPipeline + verify |
| Out of scope | App logger deny-list / payload bans |
| Basis | Same JP PII keywords as the Splunk chat |

## Summary

Configure Dynatrace-side masking so future logs that contain 氏名 / 住所 / 電話 / マイナンバー / 口座番号 (and related keywords) store `***` instead of raw values. Then verify with DQL.

---

## Keywords to mask (basis)

氏名, 住所, 電話, 生年月日, 郵便番号, メール, メールアドレス, 携帯, 携帯電話, 携帯番号, 固定電話, 電話番号, ファックス, 生年月, 誕生日, 生年, 生月, 生日, 年齢, 性別, 身分証, 身分証明書, マイナンバー, 個人番号, 運転免許, 免許証, パスポート, 旅券, 銀行口座, 口座番号, 銀行コード, 支店コード, クレジットカード, カード番号, カード, 会社  

Optional JSON keys later: `bankAccountNo`, `policyHolderName`, emails, phones.

---

## Step A — OneAgent Sensitive data masking (do first)

### A1 — Open the setting

1. Dynatrace → **Settings**
2. **Collect and capture**
3. **Log monitoring**
4. **Configure log module**
5. Open **Sensitive data masking**

### A2 — Choose scope

1. Prefer **Host group** (e.g. your `C_AGO_…` / PRD groups)  
2. Or **Environment** if you want all hosts at once (broader blast radius)
3. Create / edit rules for that scope

### A3 — Add one mask rule (template)

For each rule:

| Field | What to set |
| --- | --- |
| Masking type | **STRING** |
| Replacement | `***` |
| Search expression | Regex that captures the **value** after the keyword |

### A4 — Add rules in a small first wave (manual)

Add **one rule at a time**, Save, then test with **fake** log lines only.

| Rule name (example) | Search expression idea |
| --- | --- |
| jp-name | `氏名\s*[:：＝=]\s*(\S+)` |
| jp-address | `住所\s*[:：＝=]\s*(.+?)(?=\s{2,}|,\s*\w+\s*[:：]|$)` |
| jp-phone | `(電話番号?\|携帯(電話\|番号)?\|固定電話)\s*[:：＝=]\s*(\S+)` |
| jp-email | `(メール(アドレス)?)\s*[:：＝=]\s*(\S+)` |
| jp-mynumber | `(マイナンバー\|個人番号)\s*[:：＝=]\s*(\S+)` |
| jp-bank | `(口座番号\|銀行口座)\s*[:：＝=]\s*(\S+)` |
| jp-card | `(クレジットカード\|カード番号)\s*[:：＝=]\s*(\S+)` |

Also enable Dynatrace **generic email** masking if the UI offers it.

> Exact regex must match **one capture group** for the value if your tenant requires it. If the UI asks for a capture group, wrap only the secret part in `(...)`.

### A5 — Fake test (OneAgent)

1. On a **test** host in the same host group, emit a fake line, e.g.  
   `氏名:テスト太郎 口座番号:0000000`  
   (never real customer data)
2. Wait for ingest
3. Open **Logs** → search that host → confirm values show as `***` (or masked)
4. If not masked: fix regex, check scope (host group), check OneAgent log module is active

### A6 — Expand waves

| Wave | Keywords |
| --- | --- |
| Wave 1 | 氏名, 住所, 電話/電話番号, メール, マイナンバー, 口座番号 |
| Wave 2 | 生年月日, 郵便番号, 携帯*, 身分証*, パスポート, クレジットカード |
| Wave 3 | Remaining list + English JSON `"key":"(.*?)"` patterns |

---

## Step B — OpenPipeline content mask (second net)

### B1 — Open OpenPipeline

1. Dynatrace → **OpenPipeline** (or Settings path for OpenPipeline / Log processing in your version)
2. Open the pipeline that handles **Logs** ingest for your environment

### B2 — Add a processing stage / rule

1. Add processor: **Mask sensitive data** / **Technology** content replace / **DQL processor** — use whatever your tenant labels for **content masking**
2. Match condition: log content contains JP keywords **or** always run mask expressions on content
3. Replacement: `***`

### B3 — Same keyword patterns as OneAgent

Reuse Wave 1 expressions first so OpenPipeline catches:

- Paths that bypass OneAgent mask  
- Other ingest APIs  

### B4 — Optional: drop vs mask

| Choice | When |
| --- | --- |
| **Mask** (preferred) | Keep ERROR logs for ops; hide PII values |
| Drop entire record | Only if privacy requires — can hide useful errors |

### B5 — Fake test (OpenPipeline)

1. Send the same fake JP PII line through the ingest path OpenPipeline covers
2. Confirm in Logs: no raw 氏名/口座番号 values
3. Only then expand more keywords

---

## Step C — Verify with DQL (after A + B)

### C1 — Open Logs or Notebooks

1. Dynatrace → **Logs** (advanced / DQL) or **Notebooks**
2. Timeframe: last 2h or 24h after enabling rules

### C2 — Run verify (JP first, then keywords)

```dql
fetch logs
| filter matchesValue(content, ".*[\\u3000-\\u30FF\\u4E00-\\u9FFF].*")
| filter matchesValue(content, ".*(氏名|住所|電話|生年月日|郵便番号|メール|マイナンバー|口座番号|クレジットカード).*")
| summarize hits = count(), by: { host.name }
| sort hits desc
| limit 50
```

### C3 — Read results

| Result | Meaning | Next |
| --- | --- | --- |
| 0 hits | Good for those keywords in range | Expand keywords; weekly re-check |
| Hits but content is `***` only | Mask working | OK |
| Hits with real names/numbers | Mask missed | Fix OneAgent/OpenPipeline regex or scope |

Detail sample:

```dql
fetch logs
| filter matchesValue(content, ".*[\\u3000-\\u30FF\\u4E00-\\u9FFF].*")
| filter matchesValue(content, ".*(氏名|住所|電話|メール|マイナンバー|口座番号).*")
| sort timestamp desc
| fields timestamp, host.name, content
| limit 50
```

Full file: `pii-jp-prevent-verify.dql`

---

## End-to-end checklist

| Step | Action | Pass |
| --- | --- | --- |
| A | OneAgent Wave 1 masks on host group | Fake line → `***` |
| B | OpenPipeline same Wave 1 | Fake line still safe |
| C | DQL verify | No raw PII (or only masked) |
| Later | Wave 2–3 keywords | Still clean |
| Weekly | Re-run verify DQL | No regression |

---

## Related files

| File | Purpose |
| --- | --- |
| `pii-jp-prevent-verify.dql` | Step C queries |
| `22.sh` | UI path reminders |
