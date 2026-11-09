# Wrong Kanji In The Name Boxes

```
Pink banner is still on the page
  セイ クイ and メイ シュゲ have no red line
    leave them
  姓 shows 達
    delete it
    paste 逵
    press Enter
  名 shows 格
    delete it
    paste 树格
    press Enter
  no red line under these four boxes
    scroll down
    the banner is for another item on the page
  名 turns red again with 全角で入力してください
    the site refused the simplified character 树
```

| Box | On the screen now | Type this |
|---|---|---|
| 姓 | 達 | 逵 |
| 名 | 格 | 树格 |
| セイ | クイ | クイ |
| メイ | シュゲ | シュゲ |

## Summary

The family-name box shows 達. The character for this name is 逵. The given-name box shows only 格. The given name is 树格. The kana boxes クイ and シュゲ already passed. The pink banner with no red line under these four boxes means another item further down the page still has a message.

## Investigation

| What is on screen | What it means |
|---|---|
| Pink banner | 正しく入力されていない項目があります。 Some item on the page failed. |
| 姓 | 達. This is a different kanji from 逵. |
| 名 | 格 alone. The given name has two characters, 树格. |
| セイ | クイ. No red line. |
| メイ | シュゲ. No red line. |
| Name | 逵树格. Reading クイ and シュゲ. |

達 and 逵 both use the 辶 radical, so an IME list puts the common kanji 達 where 逵 should be. 達 is inside the Japanese character set, which is why the 全角 line under 姓 is gone. The character is still the wrong one.

## Result

1. Leave セイ as クイ.
2. Leave メイ as シュゲ.
3. Click 姓, delete 達, paste 逵, and press Enter.
4. Click 名, delete 格, paste 树格, and press Enter.
5. If these four boxes have no red line, scroll down. Read the red sentence under the next item. The pink banner stays until that item is fixed.
6. If 名 shows 全角で入力してください again, the site refused 树. Leave 逵 in 姓.

How to tell the two family-name characters apart:

| Character | What is inside the 辶 |
|---|---|
| 逵 | 土, then 八, then 土 |
| 達 | 羊 on top of 土 |

Copy 逵 from this note. Choosing the first lookalike in the IME list enters 達.

## Data flow map

```
姓  達  → delete → paste 逵 → Enter
名  格  → delete → paste 树格 → Enter
セイ クイ   → keep
メイ シュゲ → keep
        |
        v
four boxes have no red line
        |
        v
scroll down and read the next red sentence
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which character to replace. |
| `1-investigation.md` | What this screen shows. |
| `2-result.md` | What to paste. |
| `3-glossary.md` | The two similar kanji. |
| `2-wrong-kanji-name-boxes-follow.txt` | The same steps for a phone. |
| `2.sh` | Copy commands. |

Commands: [2.sh](2.sh)
