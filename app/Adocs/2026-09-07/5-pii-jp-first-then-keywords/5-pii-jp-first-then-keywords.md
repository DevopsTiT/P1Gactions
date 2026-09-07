# PII Scan Japanese First Then Keywords

```
Scan logs for PII (JP)
  │
  ├─ Step 1  Filter lines that contain Japanese characters
  └─ Step 2  Filter / extract JP PII keywords (氏名, 住所, 電話, …)
        → count by source / host / keyword
```

| Key point | Detail |
| --- | --- |
| Order | **Japanese text first**, then keyword list |
| Why | Cuts noise from English-only infra logs |
| Dynatrace | Use DQL below (`fetch logs`) |
| Splunk (your chat) | Same logic as the SPL in the screenshot |

## Summary

Do not start with every keyword on all logs. First keep lines that look Japanese (Hiragana/Katakana/Kanji), then match PII label words like 氏名 / 住所 / 電話. That matches your team’s Splunk approach, adapted for Dynatrace Grail.

## Keyword list (Japanese PII labels)

氏名, 住所, 電話, 生年月日, 郵便番号, メール, メールアドレス, 携帯, 携帯電話, 携帯番号, 固定電話, 電話番号, ファックス, 生年月, 誕生日, 生年, 生月, 生日, 年齢, 性別, 身分証, 身分証明書, マイナンバー, 個人番号, 運転免許, 免許証, パスポート, 旅券, 銀行口座, 口座番号, 銀行コード, 支店コード, クレジットカード, カード番号, カード, 会社

## Dynatrace DQL

See `pii-jp-first-then-keywords.dql`.

### Step 1 — Japanese characters

Unicode ranges (same idea as your SPL):

- Hiragana/Katakana block-ish: `\u3000-\u30FF`
- CJK Kanji: `\u4E00-\u9FFF`

### Step 2 — Keywords then summarize

Match the keyword regex, then count hits (and optionally list which keywords matched).

## Splunk (same order as your chat)

```spl
index=*
| regex _raw="[\x{3000}-\x{30FF}\x{4E00}-\x{9FFF}]"
| regex _raw="(氏名|住所|電話|生年月日|郵便番号|メール|メールアドレス|携帯|携帯電話|携帯番号|固定電話|電話番号|ファックス|生年月|誕生日|生年|生月|生日|年齢|性別|身分証|身分証明書|マイナンバー|個人番号|運転免許|免許証|パスポート|旅券|銀行口座|口座番号|銀行コード|支店コード|クレジットカード|カード番号|カード|会社)"
| rex field=_raw "(?<pii_pattern>氏名|住所|電話|生年月日|郵便番号|メール|メールアドレス|携帯|携帯電話|携帯番号|固定電話|電話番号|ファックス|生年月|誕生日|生年|生月|生日|年齢|性別|身分証|身分証明書|マイナンバー|個人番号|運転免許|免許証|パスポート|旅券|銀行口座|口座番号|銀行コード|支店コード|クレジットカード|カード番号|カード|会社)"
| stats count as Total_PII_Count, dc(source) as Unique_Sources, dc(host) as Unique_Hosts, values(pii_pattern) as PII_Types by index
| sort - Total_PII_Count
| rename index as Index, Total_PII_Count as PII_Count, Unique_Sources as Sources, Unique_Hosts as Hosts, PII_Types as PII_Keywords
```

## Related files

| File | Purpose |
| --- | --- |
| `pii-jp-first-then-keywords.dql` | Dynatrace scan |
| `5.sh` | Open path reminder |

## Note

`会社` and `カード` are broad — expect false positives. Tighten the list with privacy if noise is high. Still combine with your English/JSON key blocklist (`policyHolder*`, `bankAccountNo`, …) as a second wave.
