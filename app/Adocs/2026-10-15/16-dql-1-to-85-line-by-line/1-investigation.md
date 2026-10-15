# DQL 1 To 85 Investigation

| Queries | Source answer |
|---|---|
| #1 to #31 | 2026-10-14 answers 1 to 13 (#7 from 2026-10-15 answer 7) |
| #32 to #43 | 2026-10-14 answer 14 |
| #44 to #60 | 2026-10-15 answers 4, 5 and 6 |
| #61 to #65 | 2026-10-15 answer 6 |
| #66 to #76 | 2026-10-14 answer 16 |
| #77 to #80 | 2026-10-15 answers 1 and 3 |
| #81 | 2026-10-15 answer 11 |
| #82 to #85 | 2026-10-14 answers 17, 19, 24 and 2026-10-15 answer 8 |

| Correction applied | Why |
|---|---|
| `contains(msg_url, ...)` in #23 to #28, #83 to #85 | The url field holds the full https address, so `==` never matched. |
| `endsWith(msg_url, "/save")` and similar in #82 | Short names like "quote" would match too much with `contains`. |
