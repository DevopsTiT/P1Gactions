# Error Access And PC2 UI Claims Investigation

| What was checked | Finding |
|---|---|
| SPL #11 vs #12 | Identical text. One DQL covers both. |
| Splunk bare terms | Whole-word match, case ignored. Mapped to `matchesPhrase()`. |
| `sourcetype` | Splunk-only label. No direct Dynatrace field. Needs a check query. |
| No index in #11/#12 | Splunk searches all default indexes. DQL needs a short time window. |
| #13 URL | Long URL. Split into host part and path part to avoid typos. |
| Screenshot text `op-prod-lpl` | Could be `lpl` or `1p1`. The split match avoids depending on it. |
| pc2 log path | Earlier answers flagged pc2 logs as S3-forwarded. They may be missing in Dynatrace. |
