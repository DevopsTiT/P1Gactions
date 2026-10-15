# ESBv4 Quote Timeout 77 Glossary

| Term | What it means |
|---|---|
| esbv4 | The enterprise service bus that forwards channel requests to the policy center. |
| bangauto | One aggregator channel that sends car insurance quote requests. |
| pc quote | The policy center quote endpoint `/pc/service/edge/ebroker/quote`. |
| Subsearch | Splunk `[ ]` search that runs first and filters the outer search. |
| `lookup` | DQL command that joins fields from another query on a matching key. |
| `parse` | DQL command that extracts fields from text using DPL patterns. |
| `prefix:"err."` | Lookup option that renames joined fields, so `query` becomes `err.query`. |
