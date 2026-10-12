# Dynatrace Notebook Queries Part 3 Investigation

| Cell | Evidence on screen |
|---|---|
| G | 1,000 records with warning, some host.name null (ClaimCenter, party-compass-system-api) |
| H | 134 records, no warning, PolicyCenter, Alfresco and portal pods, SWXMIGP on lp1gwd02 |
| I | 0 records, filter iAny(tags[] == "Windows") |
| J | Blurry; append of several entity tables, expand tags, filter with exact tag strings |
