# Glossary

| Term | What it means |
|---|---|
| fetch | Starts a query on records such as logs, spans, problems or entities |
| timeseries | Starts a query on metrics; returns an array of values per series |
| Span | One step of a request in a trace |
| Root span | The first span of a request, used to measure end-to-end time |
| Entity | A monitored thing such as a host or service, with an ID |
| entityName() | Turns an entity ID into its readable name |
| arrayAvg / arraySum | Reduce a timeseries array to one number |
| percentile(x, 95) | The value 95 percent of samples are below |
