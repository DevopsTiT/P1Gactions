# Cost Result, Management Zones And Spans Glossary

| Term | What it means | Why you care |
|---|---|---|
| Rate card | Price per unit for each capability. | Used to turn usage into money. |
| Capability | A billed Dynatrace feature. | Cost is grouped by it. |
| fieldsRename | Gives columns new names. | Cleaner output. |
| fieldsKeep | Keeps only the listed columns. | Drops noise. |
| Management zone | Classic grouping for permissions and alert routing. | Shows ownership of hosts. |
| Span | One step of a request in a trace. | fetch spans reads raw traces. |
| Endpoint | A URL path or method of a service. | Traffic is split by it. |
| makeTimeseries | Builds a time series from records. | Draws the stacked bars. |
| Backticks | Quote a field name with special characters. | Needed for `count()`. |
| dt.service.request.count | Built-in request count metric. | Cheaper than counting spans. |
| GiB | 1,073,741,824 bytes. | Unit for log and trace billing. |
