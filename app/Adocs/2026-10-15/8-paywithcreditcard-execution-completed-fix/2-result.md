# PayWithCreditCard Execution Completed Result

| Outcome | What to do |
|---|---|
| Step 1 returns 0 | The logs are not in Dynatrace. Send the onboarding request from 2026-10-14 answer 21. |
| Step 1 returns rows | Use the real source names it shows, then run Step 2. |
| Step 2 returns rows | The DQL now matches Splunk. Compare the count with 68. |
| Step 2 returns 0 but Step 1 has rows | Open one raw line and check the exact url and type field names. |
