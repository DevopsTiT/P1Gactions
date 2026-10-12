# Dynatrace Notebook Queries Part 2 Glossary

| Term | What it means | Why you care |
|---|---|---|
| softwareTechnologies | List of technologies and versions detected in a process. | Real field behind the UI label "Main technology". |
| expand | One row per item of a list field. | Splits technologies and hosts into rows. |
| parse | Cuts a text into named parts with a pattern. | Pulls the version out of the technology text. |
| join kind:outer | Combines two tables and keeps left rows even without a match. | Cell B keeps processes with unknown hosts. |
| lookup | Adds fields from another query on a key; first match only. | Cells D and F. |
| entityName() | Turns an entity ID into its display name. | Easy host names in cell G. |
| runs_on | Relationship from a service to its hosts. | Links services to hosts. |
| dt.davis.problems | Table of problems found by Davis AI. | Feeds the honeycomb. |
| affected_entity_ids | IDs of the entities a problem affects. | Matched to service IDs. |
| Honeycomb | Chart with one hexagon per row, colored by a field. | Quick health picture. |
| Epoch milliseconds | Time as milliseconds since 1970-01-01 UTC. | Values in the SQL cell. |
| Record limit | Default 1,000 rows in notebooks. | Warning triangle means data was cut. |
| oneAgentCustomHostName | A custom host name set on the OneAgent. | Exists on hosts, not services. |
