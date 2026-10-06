# Investigation

| Checked | Finding |
|---|---|
| Frontend search | index, spath, eval upper(level), search level="ERROR" |
| Backend search | index, rex timestamp and level, eval upper(level), search level="ERROR" |
| Schedule | Both hourly at :00, > 0, For each result, email |
