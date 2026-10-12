# Dynatrace Notebook Queries Part 3 Glossary

| Term | What it means | Why you care |
|---|---|---|
| Tag | A label on an entity. | Used to group hosts and services. |
| Tag context | The part in brackets, such as [AWS] or [Kubernetes]. | Part of the full tag text. |
| classicEntitySelector | Runs an old-style selector and returns entity IDs. | Filter by tag inside DQL. |
| in() | True when a value is in a list. | Checks membership in the ADJ host set. |
| entityAttr | Reads an entity field inside a timeseries query. | Gets tags or osType per host. |
| osType | The host operating system field, such as WINDOWS or LINUX. | Better than a hand-made tag. |
| iAny | True when any list item matches. | Used on tag lists. |
| arrayAvg | Average of all points in a series. | One CPU number per host. |
| append | Stacks results of another query under the current one. | Mixes several entity types. |
| expand | One row per list item. | Tests each tag on its own. |
| contains | Checks if a text includes another text. | Safer than exact tag compare. |
