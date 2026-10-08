# Compass PB NG Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as Banca Portal (seq 20) plus the remarks rex. |
| Application | "Compass AG". |
| Schedule | cron */1, Last 2 hours. |
| Trigger | event=2 or recovery, results > 0, Once. |
| Action | Alert Status Manager, Production, PagerDuty Enable. |
