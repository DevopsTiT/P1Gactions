# OneAgent JP PII Mask Rules

```
Settings → Collect and capture → Log monitoring
  → Configure log module → Sensitive data masking
  → Scope: Host group (prefer) or Environment
  → For each rule: Masking type = STRING, Replacement = ***
```

| Key point | Detail |
| --- | --- |
| What this is | Every OneAgent Sensitive data masking rule for the Splunk JP PII keyword list |
| Capture group | Put `(...)` only around the secret value, not the keyword |
| Rollout | Add Wave 1 first, fake-test, then Wave 2–3 |

## Summary

Use **STRING** + replacement `***` for every rule. Search expression matches `keyword` + separator (`:` `：` `=` `＝`) + **value**. Prefer host-group scope.

---

## Same settings for every rule

| Field | Value |
| --- | --- |
| Masking type | STRING |
| Replacement | `***` |
| Scope | Host group first (e.g. your `C_AGO_…` / PRD) |
| Search expression | Regex below (value in one capture group) |

Also turn on Dynatrace **generic email** masking if the UI offers it (covers `a@b.com` without a JP label).

---

## Wave 1 — create these first (must)

| # | Rule name | Search expression | Fake test line |
| --- | --- | --- | --- |
| 1 | jp-shimei | `氏名\s*[:：＝=]\s*(\S+)` | `氏名:テスト太郎` |
| 2 | jp-jusho | `住所\s*[:：＝=]\s*(.+?)(?=\s{2,}|\s+[^\s]+[:：＝=]|$)` | `住所:東京都千代田区1-1` |
| 3 | jp-denwa | `(電話番号?|固定電話)\s*[:：＝=]\s*(\S+)` | `電話番号:03-1234-5678` |
| 4 | jp-mail | `(メールアドレス|メール)\s*[:：＝=]\s*(\S+)` | `メール:a@example.com` |
| 5 | jp-mynumber | `(マイナンバー|個人番号)\s*[:：＝=]\s*(\S+)` | `マイナンバー:000012345678` |
| 6 | jp-koza | `(口座番号|銀行口座)\s*[:：＝=]\s*(\S+)` | `口座番号:1234567` |

> If your tenant requires **exactly one** capture group, and a rule has nested groups, use the **last** group as the value, or simplify to one keyword per rule (see “One keyword = one rule” below).

---

## Wave 2 — expand next

| # | Rule name | Search expression | Fake test line |
| --- | --- | --- | --- |
| 7 | jp-yubin | `郵便番号\s*[:：＝=]\s*(\S+)` | `郵便番号:100-0001` |
| 8 | jp-keitai | `(携帯電話|携帯番号|携帯)\s*[:：＝=]\s*(\S+)` | `携帯番号:090-1234-5678` |
| 9 | jp-fax | `ファックス\s*[:：＝=]\s*(\S+)` | `ファックス:03-0000-0000` |
| 10 | jp-seinengappi | `(生年月日|誕生日|生年月)\s*[:：＝=]\s*(\S+)` | `生年月日:1980-01-01` |
| 11 | jp-mibun | `(身分証明書|身分証)\s*[:：＝=]\s*(\S+)` | `身分証:AB1234567` |
| 12 | jp-menkyo | `(運転免許証|運転免許|免許証)\s*[:：＝=]\s*(\S+)` | `免許証:123456789012` |
| 13 | jp-passport | `(パスポート|旅券)\s*[:：＝=]\s*(\S+)` | `パスポート:TK1234567` |
| 14 | jp-card | `(クレジットカード|カード番号)\s*[:：＝=]\s*(\S+)` | `カード番号:4111111111111111` |

---

## Wave 3 — remaining + careful / noisy

| # | Rule name | Search expression | Note |
| --- | --- | --- | --- |
| 15 | jp-seinen | `生年\s*[:：＝=]\s*(\S+)` | Short keyword — more false hits |
| 16 | jp-seigetsu | `生月\s*[:：＝=]\s*(\S+)` | Short keyword — more false hits |
| 17 | jp-seibi | `生日\s*[:：＝=]\s*(\S+)` | Short keyword — more false hits |
| 18 | jp-nenrei | `年齢\s*[:：＝=]\s*(\S+)` | e.g. `年齢:40` |
| 19 | jp-seibetsu | `性別\s*[:：＝=]\s*(\S+)` | e.g. `性別:男` |
| 20 | jp-ginko-code | `銀行コード\s*[:：＝=]\s*(\S+)` | Bank routing code |
| 21 | jp-shiten-code | `支店コード\s*[:：＝=]\s*(\S+)` | Branch code |
| 22 | jp-card-alone | `カード\s*[:：＝=]\s*(\S+)` | **Noisy** — skip unless logs really use this label |
| 23 | jp-kaisha | `会社\s*[:：＝=]\s*(\S+)` | **Very noisy** — skip by default |

---

## Optional English / JSON keys (Wave 3+)

| # | Rule name | Search expression |
| --- | --- | --- |
| 24 | en-bankAccountNo | `"bankAccountNo"\s*:\s*"([^"]+)"` |
| 25 | en-policyHolderName | `"policyHolderName"\s*:\s*"([^"]+)"` |
| 26 | en-email-json | `"(email|mailAddress|mail)"\s*:\s*"([^"]+)"` |
| 27 | en-phone-json | `"(phone|tel|mobile)"\s*:\s*"([^"]+)"` |

---

## One keyword = one rule (safest if UI wants single capture group)

Use this list if combined OR-patterns fail validation. Same settings: STRING / `***`.

| Rule name | Search expression |
| --- | --- |
| jp-kw-氏名 | `氏名\s*[:：＝=]\s*(\S+)` |
| jp-kw-住所 | `住所\s*[:：＝=]\s*(.+?)(?=\s{2,}|\s+[^\s]+[:：＝=]|$)` |
| jp-kw-電話 | `電話\s*[:：＝=]\s*(\S+)` |
| jp-kw-電話番号 | `電話番号\s*[:：＝=]\s*(\S+)` |
| jp-kw-固定電話 | `固定電話\s*[:：＝=]\s*(\S+)` |
| jp-kw-携帯 | `携帯\s*[:：＝=]\s*(\S+)` |
| jp-kw-携帯電話 | `携帯電話\s*[:：＝=]\s*(\S+)` |
| jp-kw-携帯番号 | `携帯番号\s*[:：＝=]\s*(\S+)` |
| jp-kw-ファックス | `ファックス\s*[:：＝=]\s*(\S+)` |
| jp-kw-メール | `メール\s*[:：＝=]\s*(\S+)` |
| jp-kw-メールアドレス | `メールアドレス\s*[:：＝=]\s*(\S+)` |
| jp-kw-生年月日 | `生年月日\s*[:：＝=]\s*(\S+)` |
| jp-kw-生年月 | `生年月\s*[:：＝=]\s*(\S+)` |
| jp-kw-誕生日 | `誕生日\s*[:：＝=]\s*(\S+)` |
| jp-kw-生年 | `生年\s*[:：＝=]\s*(\S+)` |
| jp-kw-生月 | `生月\s*[:：＝=]\s*(\S+)` |
| jp-kw-生日 | `生日\s*[:：＝=]\s*(\S+)` |
| jp-kw-郵便番号 | `郵便番号\s*[:：＝=]\s*(\S+)` |
| jp-kw-年齢 | `年齢\s*[:：＝=]\s*(\S+)` |
| jp-kw-性別 | `性別\s*[:：＝=]\s*(\S+)` |
| jp-kw-身分証 | `身分証\s*[:：＝=]\s*(\S+)` |
| jp-kw-身分証明書 | `身分証明書\s*[:：＝=]\s*(\S+)` |
| jp-kw-マイナンバー | `マイナンバー\s*[:：＝=]\s*(\S+)` |
| jp-kw-個人番号 | `個人番号\s*[:：＝=]\s*(\S+)` |
| jp-kw-運転免許 | `運転免許\s*[:：＝=]\s*(\S+)` |
| jp-kw-運転免許証 | `運転免許証\s*[:：＝=]\s*(\S+)` |
| jp-kw-免許証 | `免許証\s*[:：＝=]\s*(\S+)` |
| jp-kw-パスポート | `パスポート\s*[:：＝=]\s*(\S+)` |
| jp-kw-旅券 | `旅券\s*[:：＝=]\s*(\S+)` |
| jp-kw-銀行口座 | `銀行口座\s*[:：＝=]\s*(\S+)` |
| jp-kw-口座番号 | `口座番号\s*[:：＝=]\s*(\S+)` |
| jp-kw-銀行コード | `銀行コード\s*[:：＝=]\s*(\S+)` |
| jp-kw-支店コード | `支店コード\s*[:：＝=]\s*(\S+)` |
| jp-kw-クレジットカード | `クレジットカード\s*[:：＝=]\s*(\S+)` |
| jp-kw-カード番号 | `カード番号\s*[:：＝=]\s*(\S+)` |
| jp-kw-カード | `カード\s*[:：＝=]\s*(\S+)` |
| jp-kw-会社 | `会社\s*[:：＝=]\s*(\S+)` |

Skip **カード** and **会社** unless you confirmed logs use those labels for real PII.

---

## Data flow

```
App writes log line with 氏名:… / 口座番号:…
        │
        ▼
OneAgent log module
  Sensitive data masking rules (this file)
  → value → ***
        │
        ▼
Dynatrace ingest → Logs (OpenPipeline can re-mask as 2nd net)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `24.sh` | UI path one-liners |
| `../22-prevent-jp-pii-oneagent-openpipeline/` | Full prevent guide |
| `../23-jp-pii-prevent-ppt/` | PPT + filter examples |

## Commands

See `24.sh`.
