# ESBv4 Quote Timeout 78 To 80 Investigation

| Item | Finding |
|---|---|
| SPL shape | Subsearch on request ID, then channel request lines. |
| Difference between #78, #79, #80 | Only the channel name in the request path. |
| #78 | Top cut off in screenshot. Same pattern assumed. |
| DQL approach | `lookup` replaces the subsearch. |
| Risk | esbv4 logs may not be in Dynatrace. Check 1 first. |
| Risk | ID parse pattern untested. Check 2. |
