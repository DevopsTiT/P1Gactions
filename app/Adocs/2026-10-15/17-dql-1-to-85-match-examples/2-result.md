# DQL Match Examples Result

| Step | What to do |
|---|---|
| 1 | Find the query number in the main document. |
| 2 | Compare a real log line with the sample `content`. |
| 3 | If the real line differs, check the near miss to see which filter drops it. |
| 4 | Replace `<JP_TEXT>` placeholders (#29, #34, #54, #58) with the real Japanese text. |
| 5 | Expect 0 rows for portals-amp queries until those logs are onboarded. |
