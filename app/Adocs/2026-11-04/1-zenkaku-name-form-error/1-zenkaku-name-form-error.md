# Zenkaku Name Form Error

```
Red banner on the name form
  セイ クイ and メイ シュゲ have no red line
    leave those two boxes
  姓 shows 金
    delete it
    enter 逵
    press Enter so the green mark is gone
  名 shows 书
    delete it
    enter 树格
  submit again
    名 is red again
      the site refused the simplified character 树
    both kanji boxes are clear
      this page is done
```

| Box | On the screen now | Type this |
|---|---|---|
| 姓 | 金 | 逵 |
| 名 | 书 | 树格 |
| セイ | クイ | クイ |
| メイ | シュゲ | シュゲ |

## Summary

The red banner means the kanji boxes failed the check. セイ and メイ already passed. Replace 金 with 逵, replace 书 with 树格, and press Enter in each box so the input method finishes the character. 书 is a simplified Chinese character, so this Japanese form rejects it with the message 全角で入力してください.

## Investigation

| What is on screen | What it means |
|---|---|
| Top line | 正しく入力されていない項目があります。 Some box failed. The detail is the red line under that box. |
| 姓 | The character 金 is in the box, with a green mark. The red line says 全角で入力してください. |
| 名 | The character 书 is in the box. The same red line is under it. |
| セイ | クイ is full-width katakana. No red line. |
| メイ | シュゲ is full-width katakana. No red line. |
| Name to enter | 逵树格. Family name 逵. Given name 树格. Reading クイ and シュゲ. |

逵 is in the Japanese character set. Wiktionary lists it as JIS X 0208 level 2, Shift_JIS `0xE79C`. A normal 全角 check can store it.

书 is simplified Chinese. The Japanese character set stores 書 for that shape. A form that only keeps Japanese 全角 characters rejects 书 and shows 全角で入力してください.

树 is also simplified Chinese. 格 is the same character in Japanese and is a jōyō kanji, so that one character can pass.

## Result

Do this on the open page.

1. Leave セイ as クイ.
2. Leave メイ as シュゲ.
3. Click 姓, delete 金, paste 逵, then press Enter. The green mark means the input method has not finished the character yet.
4. Click 名, delete 书, paste 树格, then press Enter.
5. Submit again.

| After you submit | What to do |
|---|---|
| No red line under 姓 or 名 | The name boxes passed. |
| Red line only under 名 | The site refused 树. 格 can stay. The simplified character is the one the check rejected. |
| Red line under 姓 | Click 姓, press Enter once more, and look for a half-width letter still in the box. |

The top sentence will stay until every red line is gone.

## Data flow map

```
お名前
  姓  金   → delete → 逵    → Enter
  名  书   → delete → 树格  → Enter
  セイ クイ  → keep
  メイ シュゲ → keep
        |
        v
submit
  both kanji boxes clear → done
  名 red again → site refused simplified 树
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which box to change. |
| `1-investigation.md` | What the screen shows. |
| `2-result.md` | What to type. |
| `3-glossary.md` | The Japanese labels. |
| `1-zenkaku-name-form-error-follow.txt` | The same steps for a phone. |
| `1.sh` | Copy commands. |

Commands: [1.sh](1.sh)
