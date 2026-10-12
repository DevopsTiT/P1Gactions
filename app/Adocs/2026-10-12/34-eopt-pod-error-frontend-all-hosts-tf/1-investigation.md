# eopt Frontend All Hosts Investigation

| What was checked | Finding |
|---|---|
| User request | Use the filter with eoptsystemapi-, eoptprocessapi- and eoptfrontend- |
| Splunk Frontend search | index eopt-prod-axa-li-jp, spath, upper(level), level ERROR |
| Splunk Backend search | same index, rex timestamp and level, level ERROR |
| Line types | Backend plain text starting with ISO timestamp; frontend JSON |
| Overlap | None: each line type passes only one alert's level check |
