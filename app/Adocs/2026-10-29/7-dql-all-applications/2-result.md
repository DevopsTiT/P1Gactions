# Result

Paste the unfiltered timeseries into the tile. Each row is one application plus one queue, with the latest average status.

| Goal | What to run |
|---|---|
| Every app that sends this metric | The query with no app filter. |
| Only pc and bc | The query with `app == "pc" or app == "bc"`. |
| Anything still open in Dynatrace | The dt.davis.problems query. |
