# Investigation

| Checked | Finding |
|---|---|
| Search | index="eopt-prod-axa-li-jp", spath, eval level=upper(level), search level="ERROR" |
| Schedule | Run every hour at :00, expires 24 hours |
| Trigger | Results > 0, Once, For each result, no throttle |
| Action | Send email, priority Normal |
| Sample "ERROR" search | 11 backend plain-text events, no JSON frontend lines shown |
