# ESBv4 Quote Timeout 80 Result

| Outcome | What to do |
|---|---|
| ID test shows `query` filled | Run the main query. |
| ID test shows `query` empty | The ID is not after the text the pattern expects. Look at one line and adjust the parse. |
| Main query returns rows | Note the times and check the pc-inssuite quote service around them. |
| Main query returns 0 rows | No kakakucomauto timeouts in 24 hours, or esbv4 logs are missing. |
