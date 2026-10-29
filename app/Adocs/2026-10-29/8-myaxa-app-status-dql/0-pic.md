# My Axa App Status Query

```
My Axa tile shows 0 records
  any CUSTOM_INFO in this window?
    no → blank tile. That is not OK. Widen the timeframe
    yes → which application values exist?
      agj-myaxa missing → the name on the event is different
      agj-myaxa present → newest event
        jobs text contains "NG :" → status NG
        jobs text has no "NG :" → status OK
  want every application?
    drop application == "agj-myaxa"
    keep the newest event per application
```

```
Notebook timeframe (this run: 09:28–11:28)
        |
        v
fetch events
        |
        v
keep CUSTOM_INFO
        |
        v
keep application is not empty
        |
        +-- this tile --> keep application == "agj-myaxa"
        |                         |
        |                         v
        |                 newest event only
        |                         |
        |                         v
        |                 jobs contains "NG :" ?
        |                    yes → status NG
        |                    no  → status OK
        |                         |
        |                         v
        |                 0 records this run → no status
        |
        +-- all applications --> newest event per application
                                      |
                                      v
                                 one row: application, status, last_seen
```
