# Investigation

| Checked | Finding |
|---|---|
| Search | index="eopt-prod-axa-li-jp", rex timestamp and level, eval upper, search level="ERROR" |
| Schedule | Run every hour at :00, expires 24 hours |
| Trigger | Results > 0, Once, For each result, no throttle |
| Action | Send email, priority Normal |
| Events | 11 on 10/6 09:30 JST from eoptsystemapi pod, PropertyDetailImportServiceImpl |
