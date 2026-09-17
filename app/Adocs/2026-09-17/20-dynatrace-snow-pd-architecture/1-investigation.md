# Investigation

User asked to explain the whole architecture again in detail for Dynatrace Problem → ServiceNow Connector + PagerDuty.

Sources checked:

| Source | Used for |
| --- | --- |
| Seq 19 Connector YAML | Actual open/close task graph and fields |
| Seq 14 connector vs notification | How classic `servicenowstg` sits beside Connection |
| Seq 13 / 17 working packs | Same Connector design lineage |

No live Dynatrace or ServiceNow API calls were made.
