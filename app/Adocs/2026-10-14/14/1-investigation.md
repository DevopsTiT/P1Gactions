# BC2 Index Errors And SSL Investigation

| What was checked | Finding |
|---|---|
| Splunk `index` | No Dynatrace equal. Replaced with a pod or host name prefix. |
| #32 operator order | Splunk OR binds before implicit AND. Index list AND word list. |
| #32 commented line | `#OR "Operation started"` is a comment. Left out. |
| #35 wildcards in quotes | Split into three `contains()` parts. |
| #38 and #44 | Identical SPL. One DQL. |
| #34 Japanese text | Unreadable. English part only. |
| #41 fields | Auto key=value in Splunk. Parsed explicitly in DQL. |
| #45 | Cut off in the screenshot. Not translated. |
