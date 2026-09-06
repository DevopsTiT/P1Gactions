# Classic Main Multi-App Dashboard

```
Your DATA_EXPLORER example
  empty filterBy = All apps
  Dashboard filter tag app:eip = EIP (same board)
  Do not clone one board per app
```

| Key point | Detail |
| --- | --- |
| Basis | Classic `DATA_EXPLORER` tile like your Request count JSON |
| All | Empty `filterBy` (`nestedFilters: []`, `criteria: []`) |
| EIP | Same board → Dashboard filter tag `app:eip` |
| Import file | `Main-MultiApp-Health-Classic.json` |

## How to use

1. Tag hosts/services: `app:eip`, `app:api`, `app:payment`
2. Dynatrace → **Dashboards Classic** → upload `Main-MultiApp-Health-Classic.json`
3. Leave filter empty → **All** (same as your example)
4. Set Dashboard filter → tag `app:eip` → EIP multi servers + request/errors on this board
5. Clear filter → back to All

## Your All tile pattern (basis)

```json
"tileType": "DATA_EXPLORER",
"metric": "builtin:service.requestCount.total",
"splitBy": ["dt.entity.service"],
"filterBy": { "filter": "AND", "nestedFilters": [], "criteria": [] },
"limit": 10
```

Empty `filterBy` = All. `Last 10min` tile uses `"tileFilter": { "timeframe": "-10m" }`.

## Board contents

| Section | Tiles |
| --- | --- |
| Critical | Problems + Davis checklist |
| App KPIs | Request count + Last 10min + Errors + Response Time |
| Infra | Multi hosts + Windows/Linux CPU + Memory |
| Logs | ERROR / Exception query notes (Classic jump) |
| DB | Request count / RT / failure rate |

## Related files

| File | Purpose |
| --- | --- |
| `Main-MultiApp-Health-Classic.json` | Import this Classic dashboard |
| `13.sh` | Open path reminder |
