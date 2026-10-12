# Dynatrace Notebook Queries Part 2 Pic

```
A  Main technology (space)        → error → use softwareTechnologies
B  Node.js versions               → works, 1,000 cut → summarize by version
C  SELECT/FROM/GROUP BY            → error → timeseries, from/to, interval:1h
D  Service health honeycomb        → works, one service flagged → problems from 7d, limit 10000
F  service → host + custom name    → custom name always null (host field) → lookup host
G  service → host name             → works → limit 10000
```

```
process_group_instance → softwareTechnologies (A, B)
service → runs_on → host (E, F, G)
davis.problems → affected_entity_ids → service (D)
metrics → timeseries (C)
```
