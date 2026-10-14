# Splunk PayWithCreditCard Query Investigation

| Step | Finding |
|---|---|
| Base search | sourcetype and 1-hour window only. No text terms, so every event is read. |
| First replace | Pattern is escaped twice. It matches backslash plus quote. |
| Second replace | Matches one backslash and removes it. |
| `spath` | No arguments, so it parses all of `_raw`. |
| Final search | Wildcard on url, exact (case ignored) on type, joined by AND. |
| Speed tip | Add the two words to the base search. |
