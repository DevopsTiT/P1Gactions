# JP PII Filter Examples Like Splunk

Same basis as the Splunk chat: **Japanese chars first**, then **keyword list**.

## Splunk-style (find)

```spl
index=*
| regex _raw="[\x{3000}-\x{30FF}\x{4E00}-\x{9FFF}]"
| regex _raw="(氏名|住所|電話|生年月日|郵便番号|メール|メールアドレス|携帯|携帯電話|携帯番号|固定電話|電話番号|ファックス|生年月|誕生日|生年|生月|生日|年齢|性別|身分証|身分証明書|マイナンバー|個人番号|運転免許|免許証|パスポート|旅券|銀行口座|口座番号|銀行コード|支店コード|クレジットカード|カード番号|カード|会社)"
```

## Dynatrace DQL (verify)

```dql
fetch logs
| filter matchesValue(content, ".*[\\u3000-\\u30FF\\u4E00-\\u9FFF].*")
| filter matchesValue(content, ".*(氏名|住所|電話|生年月日|郵便番号|メール|メールアドレス|携帯|携帯電話|携帯番号|固定電話|電話番号|ファックス|マイナンバー|個人番号|口座番号|クレジットカード).*")
| summarize hits = count(), by: { host.name }
| sort hits desc
```

## PII examples → mask pattern

| Category | Keywords (examples) | OneAgent / OpenPipeline mask idea | Fake log example |
| --- | --- | --- | --- |
| Name | 氏名 | `氏名\s*[:：＝=]\s*(\S+)` | `氏名:テスト太郎` → `氏名:***` |
| Address | 住所 | `住所\s*[:：＝=]\s*(.+)` | `住所:東京都…` → masked |
| Postal | 郵便番号 | `郵便番号\s*[:：＝=]\s*(\S+)` | `郵便番号:100-0001` |
| Phone | 電話, 電話番号, 固定電話 | `(電話番号?\|固定電話)\s*[:：＝=]\s*(\S+)` | `電話番号:03-1234-5678` |
| Mobile | 携帯, 携帯電話, 携帯番号 | `携帯(電話\|番号)?\s*[:：＝=]\s*(\S+)` | `携帯番号:090…` |
| Email | メール, メールアドレス | `(メール(アドレス)?)\s*[:：＝=]\s*(\S+)` | `メール:a@example.com` |
| DOB | 生年月日, 誕生日, 生年… | `生年月日\s*[:：＝=]\s*(\S+)` | `生年月日:1980-01-01` |
| Age / gender | 年齢, 性別 | `年齢\s*[:：＝=]\s*(\S+)` | `年齢:40` |
| My Number | マイナンバー, 個人番号 | `(マイナンバー\|個人番号)\s*[:：＝=]\s*(\S+)` | `マイナンバー:0000…` |
| ID docs | 身分証, 身分証明書, 免許証, パスポート, 旅券 | `(身分証\|パスポート)\s*[:：＝=]\s*(\S+)` | label + fake id |
| Bank | 銀行口座, 口座番号, 銀行コード, 支店コード | `(口座番号\|銀行口座)\s*[:：＝=]\s*(\S+)` | `口座番号:1234567` |
| Card | クレジットカード, カード番号 | `(クレジットカード\|カード番号)\s*[:：＝=]\s*(\S+)` | `カード番号:4111…` |
| Company | 会社 | noisy — use carefully | often false positive |

## PPT

`23-JP-PII-Prevent-OneAgent-OpenPipeline.pptx` — OneAgent → OpenPipeline → Verify (no app layer).
