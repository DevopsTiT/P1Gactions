# Result

| Item | Detail |
|---|---|
| New workflow | `1-extract-v3-tag-based-service-search.workflow.yaml` |
| New lookup | The query.sh searches built from the tags, merged and scored |
| Picks automatically | When the best service has at least 5 points and leads the second one |
| Otherwise | Top 10 candidates with score and reasons in `lookup.service_candidates` |
| Check first | `DOMAINS` list, `ENVIRONMENT` mapping for ACCEPTANCE, and the Problems API permission |
| Nothing sent | SNOW and PD bodies are previews only |
