# Building Room Full Width

```
建物・部屋番号 shows 全角で入力してください
  the box is "robot home 六郷土手101室"
    letters robot home are half-width
    digits 101 are half-width
    六郷土手 and 室 are already full-width
  paste the full-width line
    ｒｏｂｏｔ　ｈｏｍｅ　六郷土手１０１室
  the red line comes back
    the site also refuses full-width letters
    paste ロボットホーム六郷土手１０１室
```

| What is in the box | Width | What to do |
|---|---|---|
| robot home | Half-width letters | Retype them as full-width letters, or as katakana. |
| The space after home | Half-width space | Use a full-width space, or leave the space out. |
| 六郷土手 | Full-width kanji | Keep these four characters. |
| 101 | Half-width digits | Retype them as １０１. |
| 室 | Full-width kanji | Keep this character. |

## Summary

The red line is the same 全角 check as the name boxes. One half-width character fails the whole box. The letters in robot home and the digits 101 are half-width. Paste ｒｏｂｏｔ　ｈｏｍｅ　六郷土手１０１室.

## Investigation

| Source | Finding |
|---|---|
| Label | 建物・部屋番号. Building name and room number. |
| Box text | robot home 六郷土手101室 |
| Red line | 全角で入力してください。 |
| Letters | r o b o t h o m e are half-width. |
| Digits | 1 0 1 are half-width. |
| Kanji | 六郷土手 and 室 are already full-width. |

## Result

Delete the box and paste this.

```
ｒｏｂｏｔ　ｈｏｍｅ　六郷土手１０１室
```

Press Enter so the input method finishes, then submit again.

| After you submit | What to do |
|---|---|
| The red line is gone | This box passed. |
| The red line is still there | The site refuses letters. Delete the box and paste ロボットホーム六郷土手１０１室. |

Keep 六郷土手 and １０１室 in either line. １０１ uses full-width digits.

## Data flow map

```
robot home 六郷土手101室
  half-width letters
  half-width digits
        |
        v
ｒｏｂｏｔ　ｈｏｍｅ　六郷土手１０１室
        |
        v
still red?
  yes → ロボットホーム六郷土手１０１室
  no  → this box is done
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which characters fail the check. |
| `1-investigation.md` | What the box contains. |
| `2-result.md` | The line to paste. |
| `3-glossary.md` | The labels. |
| `3-building-room-zenkaku-follow.txt` | The same steps for a phone. |
| `3.sh` | Copy commands. |

Commands: [3.sh](3.sh)
