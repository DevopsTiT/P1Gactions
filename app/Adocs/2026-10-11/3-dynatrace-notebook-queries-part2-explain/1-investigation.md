# Dynatrace Notebook Queries Part 2 Investigation

| Cell | Evidence on screen |
|---|---|
| A | Error "technology isn't allowed here", 0 records, field list has "Main technology" |
| B | 1,000 records with warning, softwareTechnologies shows type NODE_JS with versions |
| C | Error "FROM isn't allowed here", SQL keywords, epoch ms 1765335600000 to 1765339200000 |
| D | 1,000 records with warning, honeycomb mostly blue with one darker cell |
| E | Only two lines visible |
| F | 1,000 records, oneAgentCustomHostName null on every row, some dt.entity.host null |
| G | 1,000 records, service.name and host.name, pod-style host names |
