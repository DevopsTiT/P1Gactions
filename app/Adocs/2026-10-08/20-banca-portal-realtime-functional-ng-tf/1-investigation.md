# Banca Portal NG Investigation

| What I checked | What I found |
|---|---|
| Search body | Same template as AG Portal NTTGW (seq 19). |
| Application filter | "Banca Portal". |
| Schedule | cron */1, Last 2 hours. |
| Trigger | results > 0, Once, no throttle. |
| Action | Alert Status Manager, Production, PagerDuty Enable. |
