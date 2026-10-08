# Investigation

| What was checked | Finding |
|---|---|
| Search | `index=main host="CEAA204C.prprivmgmt.intraxa" RETURN_CD:2` |
| Schedule | Every 5 minutes, Last 10 minutes |
| Trigger | Results > 0, Once, no throttle |
| Action | Email ops list, priority High |
| index=main hosts | ljpljob01 and wpalja2199 only |
| Conclusion | No CEAA204C data in index=main, so the alert cannot fire |
