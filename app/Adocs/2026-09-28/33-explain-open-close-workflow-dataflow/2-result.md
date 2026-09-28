# Result

| Item | Status |
|---|---|
| How OPEN extracts metadata | Four layers: event, Problems API, evidence event, Entities API |
| How OPEN decides values | "First source with a value wins" for host, environment, service and group |
| How OPEN creates the ticket | CI lookup, POST, fill blanks with PATCH |
| How CLOSE finds the ticket | correlation_id = display id, then PATCH to Resolved |
| Recommended next fixes | 1. Stop duplicates (remove UPDATED or check before POST). 2. Close every matching INC. 3. Tag before map for environment. 4. Clear the placeholders in CLOSE. |
| How to check a run | 33.sh line 1 (incidents per problem), line 3 (duplicate check), lines 5–6 (Dynatrace data the workflow saw) |
